package OpenVPN;

use strict;
use warnings;
use Exporter qw(import);
use threads;
use Digest::SHA qw(sha512_hex);
use File::Copy qw(copy);
use JSON::PP qw(encode_json);
use Tkx;

our @EXPORT_OK = qw(
    do_connect
    watch_logbox
	write_openvpn_config
    write_stunnel_config
    write_xray_config
    genpass
);

sub _ui_pump {
    # Use a full Tk event pass while starting/stopping local tunnel helpers.
    # idletasks alone can leave the main window partially painted on slower VMs.
    eval { Tkx::update(); 1 } or eval { Tkx::update('idletasks'); };
}

sub _connect_attempt_alive {
    my ($state, $attempt_id) = @_;
    return 0 unless $state && ref($state) eq 'HASH';
    return 0 if defined($attempt_id)
             && (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
    return 0 if ($state->{runtime}->{stop} // 0);
    my $mode = $state->{runtime}->{exit_btn_mode} // '';
    return 0 if $mode =~ /^(aborting|disconnecting|exit)$/;
    return 1;
}

sub _begin_tunnel_start_ui {
    my ($state, $ui) = @_;
    return unless $state && $ui && $ui->{mainwin} && $ui->{mainwin}->{exit_btn};
    return if $state->{runtime}->{tunnel_start_ui_locked};

    $state->{runtime}->{tunnel_start_ui_locked} = 1;
    eval { $ui->{mainwin}->{exit_btn}->configure(-state => 'disabled'); 1 };
    _ui_pump();
}

sub _end_tunnel_start_ui {
    my ($state, $ui, $attempt_id) = @_;
    return unless $state;
    delete $state->{runtime}->{tunnel_start_ui_locked};
    return unless $ui && $ui->{mainwin} && $ui->{mainwin}->{exit_btn};

    if (_connect_attempt_alive($state, $attempt_id)
        && (($state->{runtime}->{exit_btn_mode} // '') eq 'abort')) {
        eval { $ui->{mainwin}->{exit_btn}->configure(-state => 'normal'); 1 };
    }
    _ui_pump();
}

sub _silent_tunnel_failure {
    my ($state, $attempt_id) = @_;
    return !_connect_attempt_alive($state, $attempt_id);
}


sub _spawn_background_process {
    my ($exe, $cmdline, $cwd) = @_;
    $cwd ||= '.';

    if ($^O =~ /MSWin32/i) {
        my $ok = eval { require Win32::Process; 1 };
        if ($ok) {
            my $proc;
            my $flags = 0x08000000; # CREATE_NO_WINDOW
            my $created = Win32::Process::Create(
                $proc,
                $exe,
                $cmdline,
                0,
                $flags,
                $cwd,
            );
            if ($created && $proc) {
                my $pid = 0;
                eval { $pid = $proc->GetProcessID(); 1 };
                return $pid || 1;
            }
        }
    }

    return system(1, $cmdline);
}

sub _run_hidden_cmd_wait {
    my ($cmd, %opts) = @_;
    my $timeout = $opts{timeout} || 8;

    if ($^O !~ /MSWin32/i) {
        my $out = `$cmd`;
        return $?;
    }

    my $ok = eval { require Win32::Process; 1 };
    if (!$ok) {
        return system($cmd);
    }

    my $comspec = $ENV{ComSpec} || (($ENV{SystemRoot} || 'C:\\Windows') . '\\System32\\cmd.exe');
    my $cmdline = qq($comspec /D /S /C "$cmd");
    my $proc;
    my $created = Win32::Process::Create(
        $proc,
        $comspec,
        $cmdline,
        0,
        0x08000000, # CREATE_NO_WINDOW
        '.',
    );

    if (!$created || !$proc) {
        return system($cmd);
    }

    my $deadline = time + $timeout;
    my $exit = 259;
    while (1) {
        $proc->GetExitCode($exit);
        last if defined($exit) && $exit != 259;

        if (time >= $deadline) {
            eval { $proc->Kill(1); };
            $exit = 1;
            last;
        }

        _ui_pump();
        select undef, undef, undef, 0.05;
    }

    return (($exit || 0) << 8);
}

sub _canonical_tls_cipher {
    my ($tls) = @_;
    $tls = '' unless defined $tls;
    $tls =~ s/^\s+|\s+$//g;
    $tls =~ tr/\x{2010}\x{2011}\x{2012}\x{2013}\x{2014}\x{2212}/-/;

    my $lc = lc $tls;
    $lc =~ s/[\s_]+/-/g;

    return 'secp521r1' if $lc eq '' || $lc eq 'secp521r1' || $lc eq 'secp-521r1' || $lc eq 'p-521';
    return 'Ed25519'   if $lc eq 'ed25519' || $lc eq 'ed-25519';
    return 'Ed448'     if $lc eq 'ed448'   || $lc eq 'ed-448';
    return 'ML-DSA-87' if $lc eq 'ml-dsa-87' || $lc eq 'mldsa87' || $lc eq 'ml-dsa87' || $lc eq 'mldsa-87';

    return 'secp521r1';
}

sub _normalize_transport_state_for_connect {
    my ($state) = @_;
    return unless $state && ref($state) eq 'HASH';

    my $ssh_on   = (($state->{transport}->{ssh_enabled}   // 'off') eq 'on') ? 1 : 0;
    my $https_on = (($state->{transport}->{https_enabled} // 'off') eq 'on') ? 1 : 0;
    my $socks_on = (($state->{transport}->{socks_enabled} // 'off') eq 'on') ? 1 : 0;

    # stunnel/xray are sub-modes of the HTTPS tunnel checkbox.  Older config
    # files can have stunnel_enabled/xray_enabled left on while https_enabled
    # is off, which makes confgen point OpenVPN at 127.0.0.1 from a previous
    # local tunnel run.  Treat HTTPS=off as authoritative.
    if (!$https_on) {
        $state->{transport}->{stunnel_enabled} = 'off';
        $state->{transport}->{xray_enabled}    = 'off';
    }

    if (!$ssh_on && !$https_on) {
        delete $state->{transport}->{local_tunnel_port};
        delete @{$state->{runtime}}{qw(local_tunnel_remote_addr local_tunnel_remote_port local_tunnel_remote_ipv4 local_tunnel_remote_ipv6)};
        delete $state->{runtime}->{ssh_pid};
        delete $state->{runtime}->{stunnel_pid};
        delete $state->{runtime}->{xray_pid};

        for my $key (qw(remote_addr remote_ipv4 remote_ipv6)) {
            my $value = $state->{connect}->{$key};
            next unless defined $value;
            if ($value eq '127.0.0.1' || $value eq '::1') {
                delete $state->{connect}->{$key};
            }
        }
    }

    # Current server-side stunnel/Xray tunnel backends forward to the
    # secp521r1 OpenVPN profile. Force only those HTTPS submodes back to
    # secp521r1; SSH and direct OpenVPN keep the selected TLS profile.
    if ($https_on && !$ssh_on
        && (
               (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
            || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
            || (($state->{transport}->{https_mode} // 'stunnel') =~ /^(?:stunnel|xray)$/)
        )) {
        $state->{connect}->{tls_cipher} = 'secp521r1';
    }

    if (!$socks_on) {
        # Keep user-entered SOCKS fields in config, but ensure socks_enabled=off
        # cannot accidentally emit a socks-proxy line.
        $state->{transport}->{socks_enabled} = 'off';
    }
}

sub _kill_process_by_pid_or_image {
    my (%args) = @_;
    my $state = $args{state};
    my $pid_key = $args{pid_key};
    my $image = $args{image};

    if ($state && $pid_key && $state->{runtime}->{$pid_key}) {
        my $pid = $state->{runtime}->{$pid_key};
        _run_hidden_cmd_wait(qq{taskkill /F /T /PID $pid >NUL 2>NUL}, timeout => 5);
        delete $state->{runtime}->{$pid_key};
    }

    if ($image) {
        _run_hidden_cmd_wait(qq{taskkill /F /T /IM "$image" >NUL 2>NUL}, timeout => 5);
    }

    # Give Win7/WFP a short moment to tear down sockets and process state before
    # starting a replacement listener.  The local port is randomized, but Xray
    # and stunnel can still race their own cleanup during rapid Abort/retry or
    # Options toggles.
    for (1 .. 10) {
        _ui_pump();
        select undef, undef, undef, 0.10;
    }
}


sub _pid_is_alive {
    my ($pid) = @_;
    return 0 unless defined $pid && $pid =~ /^\d+$/ && $pid > 0;

    if ($^O =~ /MSWin32/i) {
        my $out = `tasklist /FI "PID eq $pid" /NH 2>NUL`;
        $out = '' unless defined $out;
        return ($out =~ /\b\Q$pid\E\b/) ? 1 : 0;
    }

    return kill(0, $pid) ? 1 : 0;
}

sub _local_tcp_port_claimed {
    my ($port) = @_;
    return 0 unless defined $port && $port =~ /^\d+$/ && $port > 0;

    my $sock = eval {
        require IO::Socket::INET;
        IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            Listen    => 1,
            ReuseAddr => 0,
        );
    };

    if ($sock) {
        close($sock);
        return 0;
    }

    return 1;
}

sub _xray_log_says_ready {
    my ($port, @logs) = @_;
    return 0 unless defined $port && $port =~ /^\d+$/;

    for my $path (@logs) {
        next unless defined $path && length $path && -e $path;
        my $txt = _tail_file($path, 8000);
        return 1 if $txt =~ /listening\s+TCP\s+on\s+127\.0\.0\.1:\Q$port\E\b/i;
        return 1 if $txt =~ /listening\s+UDP\s+on\s+127\.0\.0\.1:\Q$port\E\b/i;
        return 1 if $txt =~ /\bXray\b.*\bstarted\b/i;
    }

    return 0;
}

sub _stunnel_log_says_ready {
    my ($port, @logs) = @_;
    return 0 unless defined $port && $port =~ /^\d+$/;

    for my $path (@logs) {
        next unless defined $path && length $path && -e $path;
        my $txt = _tail_file($path, 8000);
        return 1 if $txt =~ /\bConfiguration successful\b/i;
        return 1 if $txt =~ /\bService \[openvpn\].*bound\b/i;
        return 1 if $txt =~ /\baccept(?:\s+|=)127\.0\.0\.1:\Q$port\E\b/i;
    }

    return 0;
}

sub _wait_helper_ready {
    my (%args) = @_;
    my $state        = $args{state};
    my $attempt_id   = $args{attempt_id};
    my $port         = $args{port};
    my $pid          = $args{pid};
    my $timeout_ms   = $args{timeout_ms} || 15000;
    my $is_tunnel_up = $args{is_tunnel_up};
    my $log_ready_cb = $args{log_ready_cb};

    my $deadline = time + ($timeout_ms / 1000);
    while (time < $deadline) {
        return 0 unless _connect_attempt_alive($state, $attempt_id);

        return 1 if $log_ready_cb && $log_ready_cb->();
        return 1 if $is_tunnel_up && $is_tunnel_up->($port, 250) > 0;

        # Some Windows builds/logging combinations can show a healthy local
        # helper listener before netstat has a stable LISTENING row.  If the
        # helper PID is alive and the freshly-randomized local TCP port is no
        # longer bindable, treat that as ready rather than killing a good helper
        # and reporting a false Unable-to-start error.
        return 1 if _pid_is_alive($pid) && _local_tcp_port_claimed($port);

        _ui_pump();
        select undef, undef, undef, 0.10;
    }

    return 0;
}

sub _wait_local_tcp_port_free {
    my ($port, $timeout_ms) = @_;

    return 1 unless defined $port && $port =~ /^\d+$/;

    $timeout_ms ||= 2500;
    my $deadline = time + ($timeout_ms / 1000);

    while (time < $deadline) {
        my $sock = eval {
            require IO::Socket::INET;
            IO::Socket::INET->new(
                PeerHost => '127.0.0.1',
                PeerPort => $port,
                Proto    => 'tcp',
                Timeout  => 0.20,
            );
        };

        if ($sock) {
            close($sock);
            _ui_pump();
            select undef, undef, undef, 0.10;
            next;
        }

        return 1;
    }

    return 0;
}


sub _tail_file {
    my ($path, $max) = @_;
    $max ||= 3000;
    return '' unless defined $path && -e $path;
    my $txt = '';
    eval {
        open my $fh, '<:raw', $path or die $!;
        local $/;
        $txt = <$fh> // '';
        close $fh;
        1;
    } or return '';
    $txt =~ s/\r\n/\n/g;
    $txt =~ s/\r/\n/g;
    return $txt if length($txt) <= $max;
    return substr($txt, length($txt) - $max);
}

sub _netstat_for_port {
    my ($port) = @_;
    return '' unless defined $port && $port =~ /^\d+$/;
    my $out = `netstat -ano -p TCP 2>NUL`;
    $out = '' unless defined $out;
    my @lines = grep { /(?:127\.0\.0\.1|0\.0\.0\.0):\Q$port\E\b/ } split /\r?\n/, $out;
    return join("\n", @lines);
}

sub do_connect {
    my (%args) = @_;

    my $state              = $args{state}              or die "do_connect: missing state";
    my $ui                 = $args{ui}                 or die "do_connect: missing ui";
    my $L                  = $args{L}                  or die "do_connect: missing L";
    my $servers            = $args{servers}            || [];
    my $token_plain_regex  = $args{token_plain_regex}  or die "do_connect: missing token_plain_regex";
    my $token_hash_regex   = $args{token_hash_regex}   or die "do_connect: missing token_hash_regex";
	my $show_logbox        = $args{show_logbox}        or die "do_connect: missing show_logbox";
	my $append_log_line    = $args{append_log_line}    or die "do_connect: missing append_log_line";
	my $ensure_tap_adapter = $args{ensure_tap_adapter} or die "do_connect: missing append_log_line";
	my $start_ssh_tunnel   = $args{start_ssh_tunnel};
    my $update_selected_remote_endpoints = $args{update_selected_remote_endpoints}
        or die "do_connect: missing update_selected_remote_endpoints";
    my $refresh_ui_from_state = $args{refresh_ui_from_state}
        or die "do_connect: missing refresh_ui_from_state";
    my $do_error = $args{do_error} or die "do_connect: missing do_error";
    my $save_config = $args{save_config} or die "do_connect: missing save_config";
    my $shutdown_openvpn = $args{shutdown_openvpn} or die "do_connect: missing shutdown_openvpn";
    my $confgen = $args{confgen} or die "do_connect: missing confgen";
    my $hidewin = $args{hidewin} or die "do_connect: missing hidewin";
	my $delete_logbox_text_line = $args{delete_logbox_text_line} or die "do_connect: missing delete_logbox_text_line";
	my $start_world_icon_spinner = $args{start_world_icon_spinner} or die "do_connect: missing start_world_icon_spinner";
	my $toggle_fw_rule = $args{toggle_fw_rule}; # optional
    my $refresh_killswitch_rules_for_connect = $args{refresh_killswitch_rules_for_connect}; # optional
    my $prepare_local_tunnel_start = $args{prepare_local_tunnel_start}; # optional
    my $refresh_ipv6_block_rule_for_connect = $args{refresh_ipv6_block_rule_for_connect}; # optional
    my $clear_ipv6_block_rule = $args{clear_ipv6_block_rule}; # optional
    my $remove_ipv6_routes = $args{remove_ipv6_routes}; # optional
    my $cleanup_tap_ipv6_addresses = $args{cleanup_tap_ipv6_addresses}; # optional

    my $lang = $state->{app}->{lang};

    if ($clear_ipv6_block_rule && ref($clear_ipv6_block_rule) eq 'CODE') {
        $state->{runtime}->{clear_ipv6_block_rule_cb} = $clear_ipv6_block_rule;
    }

    _normalize_transport_state_for_connect($state);

    my $mode_before_connect = $state->{runtime}->{exit_btn_mode} // 'exit';
    return 0 if $mode_before_connect =~ /^(?:preparing|abort|aborting|disconnecting)$/;

    # Make the UI react immediately to the Connect click before DNS/route,
    # firewall, TAP, or tunnel-prep work pumps the Tk event loop.  Abort is
    # enabled only after the short pre-launch critical section is over.
    $state->{runtime}->{connect_attempt_id} = ($state->{runtime}->{connect_attempt_id} // 0) + 1;
    $state->{runtime}->{stop} = 0;
    $state->{runtime}->{exit_btn_mode} = 'preparing';
    eval {
        $ui->{mainwin}->{connect_btn}->configure(-state => 'disabled') if $ui->{mainwin}->{connect_btn};
        $ui->{mainwin}->{options_btn}->configure(-state => 'disabled') if $ui->{mainwin}->{options_btn};
        $ui->{mainwin}->{server_picker}->configure(-state => 'disabled') if $ui->{mainwin}->{server_picker};
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_ABORT},
            -state => 'disabled',
        ) if $ui->{mainwin}->{exit_btn};
        1;
    };
    _ui_pump();

    $show_logbox->() if $show_logbox;
    _set_ui_connecting_state($state, $ui, $L);
    $state->{runtime}->{stop_world_spinner} = 0;
    $start_world_icon_spinner->($state, $ui);
    $state->{runtime}->{status_text} = "Preparing connection...";
    $state->{runtime}->{pbar} = 0;
    $state->{runtime}->{pbar_target} = 0;
    $state->{runtime}->{pbar_animating} = 0;
    $state->{runtime}->{pbar_seen} = {};
    _set_pbar_target($state, $ui, 3);
    _ui_pump();

    $update_selected_remote_endpoints->(
        $state,
        $servers,
        $L->{$lang}{TXT_DEFAULT_SERVER},
    );

    $refresh_ui_from_state->($state, $ui);

    if ($refresh_ipv6_block_rule_for_connect
        && (($state->{security}->{killswitch_enabled} // 'off') ne 'on')) {
        $state->{runtime}->{status_text} = "Checking IPv6 leak rules...";
        _ui_pump();
        if (!$refresh_ipv6_block_rule_for_connect->()) {
            my $err = $state->{runtime}->{ipv6_block_rule_error} || 'No firewall error text was captured.';
            $do_error->("Unable to update the IPv6 leak block rule.

" . $err);
            _reset_ui_disconnected_state($state, $ui, $L);
            return 0;
        }
    }


    if ($remove_ipv6_routes && (($state->{security}->{no_ipv6} // 'off') eq 'on')) {
        $state->{runtime}->{status_text} = "Cleaning IPv6 routes...";
        _ui_pump();
        $remove_ipv6_routes->(wait => 1);
    }

    # From this point through killswitch refresh/helper cleanup we pump Tk, so
    # disable the main actions before any long operation can re-enter Connect.
    eval {
        $ui->{mainwin}->{connect_btn}->configure(-state => 'disabled') if $ui->{mainwin}->{connect_btn};
        $ui->{mainwin}->{options_btn}->configure(-state => 'disabled') if $ui->{mainwin}->{options_btn};
        $ui->{mainwin}->{server_picker}->configure(-state => 'disabled') if $ui->{mainwin}->{server_picker};
        1;
    };
    _ui_pump();

    # connect_attempt_id and preparing UI state were set at the top of
    # do_connect so stale callbacks are invalidated before any UI pumping.

    # Refresh killswitch endpoint rules before starting SSH/stunnel/Xray.
    # Otherwise the helper can exit immediately because outbound traffic to the
    # selected tunnel endpoint is still blocked by the old rule set.
    if ($refresh_killswitch_rules_for_connect) {
        $state->{runtime}->{status_text} = "Preparing firewall rules...";
        _ui_pump();
        if (!$refresh_killswitch_rules_for_connect->()) {
            _reset_ui_disconnected_state($state, $ui, $L);
            return 0;
        }
    }

    if ($prepare_local_tunnel_start) {
        $state->{runtime}->{status_text} = "Cleaning tunnel helpers...";
        _ui_pump();
        if (!$prepare_local_tunnel_start->()) {
            _reset_ui_disconnected_state($state, $ui, $L);
            return 0;
        }
    }

    $state->{runtime}->{stop} = 0;
    $state->{runtime}->{exit_btn_mode} = 'abort';
	
	$delete_logbox_text_line->($L->{$lang}{TXT_ABORT});
    $delete_logbox_text_line->($L->{$lang}{TXT_DISCONNECTED});
    $delete_logbox_text_line->($L->{$lang}{TXT_CONNECTED});

	$ui->{mainwin}->{exit_btn}->configure(
        -text  => $L->{$state->{app}->{lang}}{TXT_ABORT},
        -state => 'normal',
    );
	
    _ui_pump();

    $SIG{ALRM} = sub {
        _recon(
            state            => $state,
            ui               => $ui,
            L                => $L,
            message          => $L->{$state->{app}->{lang}}{TXT_CONNECT_TIMEOUT},
            shutdown_openvpn => $shutdown_openvpn,
			append_log_line => $append_log_line
        );
        return;
    };

    alarm($state->{connect}->{timeout});

    if (!$state->{connect}->{token}) {
        $ui->{mainwin}->{world_img}->configure(-image => "mainicon");
        $do_error->($L->{$lang}{ERR_NO_TOKEN});
        _reset_ui_disconnected_state($state, $ui, $L);
        alarm(0);
        return 0;
    }

    $state->{connect}->{token} =~ s/[^a-zA-Z0-9\-\+\/]//g;

    if (($state->{connect}->{token} !~ /^$token_plain_regex$/) &&
        ($state->{connect}->{token} !~ /^$token_hash_regex$/) &&
        ($state->{connect}->{token} !~ /^AAAAC3NzaC1lZDI1NTE5AAAAI/)) {

        _reset_ui_disconnected_state($state, $ui, $L);
        $ui->{mainwin}->{world_img}->configure(-image => "mainicon");

        if ($state->{connect}->{token} =~ /^($token_plain_regex){2,}/) {
            $do_error->($L->{$lang}{ERR_TOO_MANY_TOKENS1} . "\n" .
                        $L->{$lang}{ERR_TOO_MANY_TOKENS2});
        } else {
            $do_error->($L->{$lang}{ERR_INVALID_TOKEN1} . "\n" .
                        $L->{$lang}{ERR_INVALID_TOKEN2});
        }

        alarm(0);
        return 0;
    }

    if ((($state->{startup}->{autoconnect} // 'off') eq "on")
        && (($state->{connect}->{save_token} // 'off') eq "off")) {
        $state->{startup}->{autoconnect} = "off";
    }
	
    $state->{runtime}->{status_text} = $L->{$lang}{TXT_LOGGING_IN} . "...";
    _ui_pump();

    _write_auth_file(
        state             => $state,
        token_plain_regex => $token_plain_regex,
        token_hash_regex  => $token_hash_regex,
    );

    $ui->{mainwin}->{logbox}->configure(-state => "normal");
    _delete_logbox_tagged_lines($ui, 'badline');

    my $launch = {
        mode         => 'direct_tap',
        config_path  => $state->{app}->{generated_ovpn_file} || '..\\user\\session.ovpn',
        log_path     => '..\\bin\\openvpn.log',
    };

    if ($launch->{mode} eq 'direct_tap') {
        my $tap_ok = $ensure_tap_adapter ? $ensure_tap_adapter->() : 1;

        if (!$tap_ok) {
            $do_error->(
                $state->{connect}->{tap_install_error}
                || $L->{$lang}{ERR_TAP_INSTALL_FAILED}
                || "Unable to install or find the cryptostorm TAP adapter."
            );

            _reset_ui_disconnected_state($state, $ui, $L);
            alarm(0);
            return 0;
        }

        $state->{runtime}->{status_text} = $L->{$lang}{TXT_LOGGING_IN} . "...";
        _ui_pump();

        $cleanup_tap_ipv6_addresses->(wait => 1)
            if $cleanup_tap_ipv6_addresses && (($state->{security}->{no_ipv6} // 'off') eq 'on');
    }

    unlink $launch->{log_path} if -e $launch->{log_path};
	
	if (($state->{transport}->{ssh_enabled} // 'off') eq 'on') {
    	my $ssh_ok = $start_ssh_tunnel ? $start_ssh_tunnel->() : 0;

    	if (!$ssh_ok) {

        	$state->{runtime}->{stop_world_spinner} = 1;
        	$state->{runtime}->{pbar} = 0;
        	$state->{runtime}->{pbar_target} = 0;
        	$state->{runtime}->{pbar_animating} = 0;
        	$state->{runtime}->{exit_btn_mode} = 'exit';

        	eval {
            	$ui->{mainwin}->{world_img}->configure(-image => "mainicon");
            	1;
        	};

        	_reset_ui_disconnected_state($state, $ui, $L);
        	alarm(0);
        	return 0;
    	}
	}

    if ($confgen) {
        my $conf_ok = eval {
            $confgen->(
                state       => $state,
                ui          => $ui,
			    L           => $L,
                launch      => $launch,
                mode        => $launch->{mode},
                log_path    => $launch->{log_path},
            );

            1;
        };

        if (!$conf_ok) {
            _reset_ui_disconnected_state($state, $ui, $L);
            alarm(0);
            return 0;
        }
    }

    # Reconcile this again after SSH/stunnel/Xray startup and config generation.
    # The first pass protects early helper work; this forced second pass catches
    # any Options/cleanup/import path that removed the standalone IPv6 block just
    # before OpenVPN starts.  This is only used when the full killswitch is off.
    if ($refresh_ipv6_block_rule_for_connect
        && (($state->{security}->{killswitch_enabled} // 'off') ne 'on')
        && (($state->{security}->{no_ipv6} // 'off') eq 'on')) {
        delete $state->{runtime}->{ipv6_block_rule_state};
        delete $state->{runtime}->{ipv6_block_rule_signature};
        $state->{runtime}->{status_text} = "Checking IPv6 leak rules...";
        _ui_pump();
        if (!$refresh_ipv6_block_rule_for_connect->()) {
            my $err = $state->{runtime}->{ipv6_block_rule_error} || 'No firewall error text was captured.';
            $do_error->("Unable to update the IPv6 leak block rule.

" . $err);
            _reset_ui_disconnected_state($state, $ui, $L);
            alarm(0);
            return 0;
        }
    }

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_CONNECTING} . "...";
    _ui_pump();

	Tkx::after(100, sub {
	    system(1, "netsh interface ipv6 set privacy state=disabled");
	});

    if ($launch->{mode} eq 'direct_tap') {
        my $cmd = qq("$state->{app}->{ovpn_exe}" --config "$launch->{config_path}");

        my $pid = _spawn_background_process(
            $state->{app}->{ovpn_exe},
            $cmd,
            $state->{app}->{program_files_dir} || '.',
        );

        if (!defined($pid) || !$pid) {
            $do_error->("Unable to start OpenVPN\nCommand: $cmd");
            _reset_ui_disconnected_state($state, $ui, $L);
            alarm(0);
            return 0;
        }

        $state->{runtime}->{vpn_pid} = $pid;
        $state->{runtime}->{last_openvpn_launch_cmd} = $cmd;
        delete $state->{runtime}->{VPNfh};
		
    }
    else {
        # Placeholder for DCO / interactive service path.
        # Later replace this with service start / pipe communication helper.
        $do_error->("DCO launch path not implemented yet");
        _reset_ui_disconnected_state($state, $ui, $L);
        alarm(0);
        return 0;
    }

    $state->{runtime}->{openvpn_log_path} = $launch->{log_path};
    $state->{runtime}->{openvpn_log_pos}  = 0;
    $state->{runtime}->{stop}             = 0;

    $state->{runtime}->{pbar} = $state->{runtime}->{pbar} // 0;
    $state->{runtime}->{pbar_target} = $state->{runtime}->{pbar_target} // 0;
    $state->{runtime}->{pbar_animating} = $state->{runtime}->{pbar_animating} // 0;
    $state->{runtime}->{pbar_seen} = {};

    _set_pbar_target($state, $ui, 8);

    $state->{runtime}->{pbar_events} = [
        {
            key    => 'openvpn_started', 
            re     => qr/\bOpenVPN\s+[0-9.]+.*\bbuilt on\b/i,
            target => 8,
        },
        {
            key    => 'remote_preserved',
            re     => qr/TCP\/UDP: Preserving recently used remote address/i,
            target => 12,
        },
        {
            key    => 'udp_remote',
            re     => qr/UDPv[46] link remote:/i,
            target => 18,
        },
        {
            key    => 'tls_initial',
            re     => qr/TLS: Initial packet from/i,
            target => 25,
        },
        {
            key    => 'ca_verified',
            re     => qr/VERIFY OK: depth=1/i,
            target => 32,
        },
        {
            key    => 'server_verified',
            re     => qr/VERIFY OK: depth=0/i,
            target => 40,
        },
        {
            key    => 'control_channel',
            re     => qr/Control Channel:\s*TLSv/i,
            target => 50,
        },
        {
            key    => 'peer_initiated',
            re     => qr/Peer Connection Initiated/i,
            target => 58,
        },
        {
            key    => 'push_request',
            re     => qr/SENT CONTROL .*PUSH_REQUEST/i,
            target => 65,
        },
        {
            key    => 'push_reply',
            re     => qr/PUSH: Received control message: 'PUSH_REPLY/i,
            target => 72,
        },
        {
            key    => 'open_tun',
            re     => qr/^open_tun\b/i,
            target => 78,
        },
        {
            key    => 'tap_configured',
            re     => qr/Set TAP-Windows .* \[SUCCEEDED\]|Notified TAP-Windows driver/i,
            target => 84,
        },
        {
            key    => 'tap_opened',
            re     => qr/tap-windows6 device .* opened/i,
            target => 88,
        },
        {
            key    => 'data_channel',
            re     => qr/Data Channel: cipher/i,
            target => 91,
        },
        {
            key    => 'routes_tested',
            re     => qr/TEST ROUTES: .* succeeded/i,
            target => 94,
        },
        {
            key    => 'routes_added',
            re     => qr/Route addition via .* succeeded/i,
            target => 97,
        },
    ];

    alarm(0);
    return 1;
}

sub watch_logbox {
    my (%args) = @_;

    my $state            = $args{state}            or die "watch_logbox: missing state";
    my $ui               = $args{ui}               or die "watch_logbox: missing ui";
    my $L                = $args{L}                or die "watch_logbox: missing L";
    my $Registry         = $args{Registry};
    my $do_error         = $args{do_error}         or die "watch_logbox: missing do_error callback";
    my $shutdown_openvpn = $args{shutdown_openvpn} or die "watch_logbox: missing shutdown_openvpn callback";
    my $save_config      = $args{save_config};
    my $toggle_fw_rule   = $args{toggle_fw_rule};
    my $hidewin          = $args{hidewin} or die "watch_logbox: missing hidewin";
	my $after_update_check = $args{after_update_check};
	my $append_log_line = $args{append_log_line} or die "watch_logbox: missing append_log_line";
	my $delete_logbox_text_line = $args{delete_logbox_text_line} or die "watch_logbox: missing delete_logbox_text_line";
	my $stop_world_icon_spinner = $args{stop_world_icon_spinner} or die "watch_logbox: missing stop_world_icon_spinner";
	my $start_post_connect_checks = $args{start_post_connect_checks} or die "watch_logbox: missing start_post_connect_checks";
	my $delete_logbox_status_lines = $args{delete_logbox_status_lines} or die "watch_logbox: missing delete_logbox_status_lines";
    my $append_log_status_line = $args{append_log_status_line} or die "watch_logbox: missing append_log_status_line";
	my $on_openvpn_connected = $args{on_openvpn_connected} or die "watch_logbox: missing on_openvpn_connected callback";

    my $lang = $state->{app}->{lang};

    my $processed = 0;
    my $max_lines_per_tick = 25;

    while ($processed < $max_lines_per_tick) {
        my $ovpnline = '';

        last unless @{ $state->{runtime}->{log_lines} };
        $ovpnline = shift @{ $state->{runtime}->{log_lines} };

        $processed++;

        $append_log_line->($ui, $ovpnline);

        for my $event (@{ $state->{runtime}->{pbar_events} || [] }) {
            next unless defined $event->{key};
            next if $state->{runtime}->{pbar_seen}->{ $event->{key} };

            if (defined $ovpnline && $ovpnline =~ $event->{re}) {
                $state->{runtime}->{pbar_seen}->{ $event->{key} } = 1;
                _set_pbar_target($state, $ui, $event->{target});
                last;
            }
        }

        if ($ovpnline =~ /\b(10\.(?:66|67|70|71)\.\d{1,3}\.(?:25[0-5]|2[0-4]\d|1\d\d|\d\d|[2-9]))\b/) {
            $state->{runtime}->{localip} = $1;
        }

        if ($ovpnline =~ /(fd00:10:60:(?:[a-f0-9]{1,4}:){4}[a-f0-9]{1,4})/i) {
            $state->{runtime}->{localip6} = $1;
        }

        if ($ovpnline =~ /GDG6: remote_host_ipv6=([a-f0-9:]+)/) {
            $state->{connect}->{remote_ipv6} = $1;
        }

        if ($ovpnline =~ /received, process restarting/) {
            my $mode = $state->{runtime}->{exit_btn_mode} // '';

            # During an active connection attempt, this is OpenVPN retrying.
            # Do not reset the GUI to disconnected.
            if ($mode eq 'abort' || $mode eq 'disconnect') {
                next;
            }

            _delete_logbox_tagged_lines($ui, 'goodline');
            _reset_ui_disconnected_state($state, $ui, $L);
            next;
        }

        if ($ovpnline =~ /Failed to open/ || $ovpnline =~ /Options error:/) {
            $append_log_line->($ui, "", "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($ovpnline);
            $shutdown_openvpn->();
            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }

        if ($ovpnline =~ /Exiting due to fatal error/) {
            $append_log_line->($ui, "", "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($ovpnline);
            $shutdown_openvpn->();
            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }
        if ($ovpnline =~ /AUTH_FAILED.*(?:\bEXPIRED\b|YOUR TOKEN HAS EXPIRED)/i) {
            my $msg = $L->{$lang}{ERR_TOKEN_EXPIRED} || 'Your VPN access token has expired';

            $append_log_line->($ui, $msg, "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($msg);
            $shutdown_openvpn->();

            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }

        if ($ovpnline =~ /AUTH_FAILED.*(?:\bMAX\b|MAX SESSIONS REACHED FOR THAT TOKEN)/i) {
            my $msg = $L->{$lang}{ERR_MAX_SESSIONS} || 'You have reached the maximum sessions permitted';

            $append_log_line->($ui, $msg, "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($msg);
            $shutdown_openvpn->();

            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }
		
        if ($ovpnline =~ /AUTH: Received control message: AUTH_FAILED/) {
            $append_log_line->($ui, $L->{$lang}{ERR_AUTH_FAIL}, "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($L->{$lang}{ERR_AUTH_FAIL});
            $shutdown_openvpn->();
            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }

        if ($ovpnline =~ /Cannot resolve host address: (.*)/) {
            $append_log_line->($ui, $L->{$lang}{ERR_RESOLVE} . " $1", "badline");
            _reset_ui_disconnected_state($state, $ui, $L);
            $do_error->($L->{$lang}{ERR_RESOLVE} . " $1");
            $shutdown_openvpn->();
            alarm(0);
            close($state->{runtime}->{VPNfh}) if $state->{runtime}->{VPNfh};
            $state->{runtime}->{stop} = 1;
            return -1;
        }

        if ($ovpnline =~ /Initialization Sequence Completed/) {
            my $mode = $state->{runtime}->{exit_btn_mode} // '';

            if (($state->{runtime}->{stop} // 0) && $mode =~ /^(aborting|disconnecting)$/) {
                @{ $state->{runtime}->{log_lines} } = ();
                return 0;
            }

            if ($ovpnline =~ /Initialization Sequence Completed With Errors/) {
                $append_log_line->($ui, $L->{$lang}{ERR_CONNECT_GENERIC}, "badline");
                _reset_ui_disconnected_state($state, $ui, $L);
                $ui->{mainwin}->{world_img}->configure(-image => "mainicon");
                $do_error->($L->{$lang}{ERR_CONNECT_GENERIC});
                $shutdown_openvpn->();
                alarm(0);
                $state->{runtime}->{stop} = 1;
                return -1;
            }

            my $success_attempt_id = $state->{runtime}->{connect_attempt_id} // 0;

            $on_openvpn_connected->(
                source     => 'log',
                attempt_id => $success_attempt_id,
                ovpnline   => $ovpnline,
            );

            return 0;
        }
    }

    return 0;
}

sub _write_auth_file {
    my (%args) = @_;

    my $state             = $args{state}             or die "_write_auth_file: missing state";
    my $token_plain_regex = $args{token_plain_regex} or die "_write_auth_file: missing token_plain_regex";
    my $token_hash_regex  = $args{token_hash_regex}  or die "_write_auth_file: missing token_hash_regex";

    my $path = "..\\user\\$state->{app}->{auth_file}";
    open my $fh, '>', $path or die "_write_auth_file: could not write $path";

    if (length($state->{connect}->{token})) {
        if ($state->{connect}->{token} =~ /^($token_plain_regex)$/) {
            print $fh sha512_hex($state->{connect}->{token}) . "\n";
        }
        elsif (($state->{connect}->{token} =~ /^($token_hash_regex)$/)
            || ($state->{connect}->{token} =~ /^AAAAC3NzaC1lZDI1NTE5AAAAI/)) {
            print $fh $state->{connect}->{token} . "\n";
        }
        else {
            print $fh sha512_hex($state->{connect}->{token}) . "\n";
        }
    }

    print $fh join("", map { sprintf "%02x", rand(256) } 1..16), "\n";
    close $fh;
}

sub _delete_logbox_tagged_lines {
    my ($ui, $tag) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    eval {
        $logbox->configure(-state => 'normal');

        while (1) {
            my @range = $logbox->tag_nextrange($tag, '1.0', 'end');
            last unless @range >= 2;

            my ($start, $end) = @range;
            $logbox->delete("$start linestart", "$start lineend +1c");
        }

        $logbox->configure(-state => 'disabled');
        1;
    } or do {
        warn "OpenVPN::_delete_logbox_tagged_lines($tag) failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub _delete_status_line_from_logbox {
    my ($state, $ui, $text) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    my $pattern = '^' . quotemeta($text) . '$';
    my $idx = $logbox->search(-regexp, $pattern, "1.0");

    if (defined $idx && $idx =~ /[0-9\.]+/) {
        $logbox->configure(-state => 'normal');
        $logbox->delete($idx, "$idx lineend +1c");
        $logbox->configure(-state => 'disabled');
    }
}

sub _set_ui_connecting_state {
    my ($state, $ui, $L) = @_;
    my $lang = $state->{app}->{lang};

    $state->{runtime}->{exit_btn_mode} = 'abort';

    $ui->{mainwin}->{connect_btn}->configure(-state => "disabled");
    $ui->{mainwin}->{options_btn}->configure(-state => "disabled");
    $ui->{mainwin}->{server_picker}->configure(-state => "disabled");
    $ui->{mainwin}->{exit_btn}->configure(
        -text  => $L->{$lang}{TXT_ABORT},
        -state => "normal",
    );
}

sub _reset_ui_disconnected_state {
    my ($state, $ui, $L) = @_;
    my $lang = $state->{app}->{lang};
	

    eval {
        $ui->{mainwin}->{world_img}->configure(-image => "mainicon");
        1;
    };

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_NOT_CONNECTED};
	$state->{runtime}->{stop_world_spinner} = 1;
    $state->{runtime}->{pbar} = 0;
	$state->{runtime}->{pbar_target} = 0;
	$state->{runtime}->{pbar_animating} = 0;
	$state->{runtime}->{pbar_seen} = {};
    $state->{runtime}->{exit_btn_mode} = 'exit';

    $ui->{mainwin}->{exit_btn}->configure(-text => $L->{$lang}{TXT_EXIT});
    $ui->{mainwin}->{connect_btn}->configure(-state => "normal");
    $ui->{mainwin}->{options_btn}->configure(-state => "normal");
    $ui->{mainwin}->{server_picker}->configure(-state => "readonly");
}

sub _set_pbar_target {
    my ($state, $ui, $target) = @_;

    $target = 0   if !defined($target) || $target < 0;
    $target = 100 if $target > 100;

    my $current = $state->{runtime}->{pbar} // 0;
    my $old_target = $state->{runtime}->{pbar_target} // 0;

    # Never move backwards during connect.
    return if $target <= $old_target && $target <= $current;

    $state->{runtime}->{pbar_target} = $target;

    return if $state->{runtime}->{pbar_animating};

    $state->{runtime}->{pbar_animating} = 1;

    Tkx::after(20, sub {
        _animate_pbar($state, $ui);
    });
}

sub _animate_pbar {
    my ($state, $ui) = @_;

    my $current = $state->{runtime}->{pbar} // 0;
    my $target  = $state->{runtime}->{pbar_target} // $current;

    if ($current >= $target) {
        $state->{runtime}->{pbar} = $target;
        $state->{runtime}->{pbar_animating} = 0;
        return;
    }

    my $diff = $target - $current;

    my $step =
        $diff > 20 ? 3 :
        $diff > 10 ? 2 :
                     1;

    $current += $step;
    $current = $target if $current > $target;

    $state->{runtime}->{pbar} = $current;

    Tkx::after(25, sub {
        _animate_pbar($state, $ui);
    });
}

sub _recon {
    my (%args) = @_;

    my $state            = $args{state}            or die "_recon: missing state";
    my $ui               = $args{ui}               or die "_recon: missing ui";
    my $L                = $args{L}                or die "_recon: missing L";
    my $message          = $args{message}          // '';
    my $shutdown_openvpn = $args{shutdown_openvpn} or die "_recon: missing shutdown_openvpn callback";
	my $append_log_line  = $args{append_log_line} or die "_recon: missing append_log_line callback";

    $append_log_line->($ui, $message, "warnline");
    _reset_ui_disconnected_state($state, $ui, $L);

    $state->{runtime}->{stop} = 1;
    $state->{runtime}->{show_tip_once} = 0;

    $shutdown_openvpn->();
    alarm(0);
}

sub write_openvpn_config {
    my (%args) = @_;

    my $state  = $args{state}  or die "write_openvpn_config: missing state";
    my $ui     = $args{ui};
    my $L      = $args{L};
    my $launch = $args{launch} || {};

    my $get_next_free_local_port = $args{get_next_free_local_port}
        or die "write_openvpn_config: missing get_next_free_local_port callback";

    my $ovpn_path = $args{ovpn_path} || '..\\\user\\\vpn.ovpn';
    my $log_path  = $args{log_path}  || '..\\\bin\\\openvpn.log';
    my $auth_path = $args{auth_path} || '..\\\user\\\client.dat';
    my $mgmt_pass_path = $args{mgmt_pass_path} || '..\\\user\\\manpass.txt';

    my $remote_addr = $args{remote_addr} || $state->{connect}->{remote_addr}
        or die "write_openvpn_config: missing remote_addr";
    if (($state->{security}->{no_ipv6} // 'off') eq 'on'
        && $remote_addr =~ /:/
        && (($state->{connect}->{remote_ipv4} // '') ne '')) {
        $remote_addr = $state->{connect}->{remote_ipv4};
    }
    die "write_openvpn_config: IPv6 remote selected while Disable IPv6 is on"
        if (($state->{security}->{no_ipv6} // 'off') eq 'on') && $remote_addr =~ /:/;

    my $remote_port = $args{remote_port} || $state->{connect}->{port}
        or die "write_openvpn_config: missing remote_port";

    my $tls_cipher  = _canonical_tls_cipher($state->{connect}->{tls_cipher} || 'secp521r1');
    if ((($state->{transport}->{https_enabled} // 'off') eq 'on')
        && (($state->{transport}->{ssh_enabled} // 'off') ne 'on')
        && (
               (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
            || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
        )) {
        $tls_cipher = 'secp521r1';
    }
    $state->{connect}->{tls_cipher} = $tls_cipher;
    my $data_cipher = $state->{connect}->{data_cipher} || 'AES-256-GCM';

    my %ca_for_tls = (
        'secp521r1' => '..\\\user\\\ca_secp521r1.crt',
        'Ed25519'   => '..\\\user\\\ca_ed25519.crt',
        'Ed448'     => '..\\\user\\\ca_ed448.crt',
        'ML-DSA-87' => '..\\\user\\\ca_mldsa87.crt',
    );

    my @cfg;

    push @cfg, "client";
    push @cfg, "dev tun";

    # TAP-only build for now. OpenVPN 2.7 defaults to ovpn-dco on
    # Windows 10/11 when a DCO adapter is installed; if we also pass a
    # tap-windows6 dev-node GUID, OpenVPN expects DCO and then errors with
    # "tap-windows6 driver, ovpn-dco expected". Keep all launch paths on
    # tap-windows6 until the client has explicit DCO support.
    push @cfg, "disable-dco";

    push @cfg, "auth-nocache";
    push @cfg, "auth-user-pass $auth_path";
    push @cfg, "resolv-retry 16";
    push @cfg, "remote-cert-tls server";
    push @cfg, "down-pre";
    push @cfg, "verb 3";
    #push @cfg, "mute 3";
    push @cfg, "machine-readable-output";
    push @cfg, "data-ciphers $data_cipher";
    push @cfg, "cipher $data_cipher";
    push @cfg, "tls-version-min 1.2";
    push @cfg, "tls-client";

    push @cfg, "ca " . ($ca_for_tls{$tls_cipher} || $ca_for_tls{secp521r1});

    if (-e '..\\user\\tcv2.key') {
        push @cfg, 'tls-crypt-v2 ..\\\user\\\tcv2.key';
    }
    else {
        push @cfg, 'tls-crypt ..\\\user\\\tc.key';
    }

    if ($tls_cipher eq 'ML-DSA-87') {
        push @cfg, "tls-ciphersuites TLS_AES_256_GCM_SHA384";
        push @cfg, "tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384";
    }
    else {
        push @cfg, "tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384";
        push @cfg, "tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384";
    }

    my $https_transport_enabled = (($state->{transport}->{https_enabled} // 'off') eq 'on')
        && (
               (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
            || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
        );

    my $local_transport_enabled =
           (($state->{transport}->{socks_enabled}   // 'off') eq 'on')
        || (($state->{transport}->{ssh_enabled}     // 'off') eq 'on')
        || $https_transport_enabled;

    my $remote_is_ipv6 = ($remote_addr =~ /:/) ? 1 : 0;

    if (($state->{connect}->{proto} // 'UDP') eq 'UDP') {
        my $proto = 'udp';
        $proto = 'udp4' if (($state->{security}->{no_ipv6} // 'off') eq 'on');

        push @cfg, "proto $proto";
        push @cfg, "explicit-exit-notify 3";
    }
    else {
        my $proto = 'tcp';
        $proto = 'tcp4' if (($state->{security}->{no_ipv6} // 'off') eq 'on');

        push @cfg, "proto $proto";
    }

    # Honor OpenVPN's pushed block-outside-dns when DNS leak protection is on.
    # Only ignore it if the user explicitly disables DNS leak protection.
    if (($state->{security}->{dns_leak_protect} // 'on') ne 'on') {
        push @cfg, qq{pull-filter ignore "block-outside-dns"};
    }

    _push_local_tunnel_bypass_routes($state, \@cfg);
    _push_direct_endpoint_bypass_route($state, \@cfg, $remote_addr);

    my $tunnelcrack_enabled = (($state->{security}->{tunnelcrack_enabled} // 'off') eq 'on');
    my $needs_redirect_gateway =
           $local_transport_enabled
        || (($state->{security}->{killswitch_enabled} // 'off') eq 'on')
        || $tunnelcrack_enabled;

    if ($needs_redirect_gateway) {
        my @flags;

        # Always use def1 when replacing pushed redirect-gateway.  The older
        # no-def1 form deletes/replaces the real default route and proved much
        # more fragile with the Windows 11 firewall/route timing.  local is only
        # needed for localhost/local-helper transports to prevent recursion.
        push @flags, 'def1';
        # Keep an explicit host route to the VPN/tunnel endpoint through the
        # pre-VPN gateway.  This is harmless for direct OpenVPN and avoids
        # Win11 default-route/endpoint recursion edge cases.
        push @flags, 'local';

        push @flags, 'ipv6' if (($state->{security}->{no_ipv6} // 'off') eq 'off');
        push @flags, 'block-local' if $tunnelcrack_enabled;

        push @cfg, qq{pull-filter ignore "redirect-gateway"};
        push @cfg, "redirect-gateway" . (@flags ? " " . join(" ", @flags) : "");
    }

    if (($state->{security}->{no_ipv6} // 'off') eq 'on') {
        push @cfg, "block-ipv6";
    }

    if (($state->{security}->{adblock_enabled} // 'off') eq 'on') {
        push @cfg, qq{pull-filter ignore "dhcp-option DNS 10.31.33.8"};
        push @cfg, qq{pull-filter ignore "dhcp-option DNS 2001:db8::8"};
        push @cfg, "dhcp-option DNS 10.31.33.7";

        if (($state->{security}->{no_ipv6} // 'off') eq 'off') {
            push @cfg, "dhcp-option DNS 2001:db8::7";
        }
    }

    if (($state->{connect}->{mssfix} // 'disabled') ne 'disabled') {
        push @cfg, "mssfix $state->{connect}->{mssfix}";
    }

    if (($state->{connect}->{tap_adapter_guid} // '') ne '') {
        my $guid = $state->{connect}->{tap_adapter_guid};

        $guid =~ s/[{}]//g;
        $guid = uc($guid);

        push @cfg, "dev-node {$guid}";
    }
    elsif (($state->{connect}->{tap_adapter_name} // '') ne '') {
        my $dev_node = $state->{connect}->{tap_adapter_name};

        $dev_node =~ s/\\/\\\\/g;
        $dev_node =~ s/"/\\"/g;

        push @cfg, qq{dev-node "$dev_node"};
    }

    if (($state->{connect}->{bind_ip} // 'Any address') ne 'Any address') {
        push @cfg, "local $state->{connect}->{bind_ip}";
    }

    if (($state->{transport}->{socks_enabled} // 'off') eq 'on') {
        my $socks_ip   = $state->{transport}->{socks_ip}   || '127.0.0.1';
        my $socks_port = $state->{transport}->{socks_port} || 9150;

        if (($state->{transport}->{socks_noauth} // 'on') eq 'on'
            || (($state->{transport}->{socks_user} // '') eq ''
            &&  ($state->{transport}->{socks_pass} // '') eq '')) {

            push @cfg, "socks-proxy $socks_ip $socks_port";
        }
        else {
            my $socks_auth_path = '..\\\user\\\socks.dat';

            open my $sfh, '>', $socks_auth_path
                or die "write_openvpn_config: could not write $socks_auth_path: $!";

            print {$sfh} ($state->{transport}->{socks_user} // ''), "\n";
            print {$sfh} ($state->{transport}->{socks_pass} // ''), "\n";
            close $sfh;

            push @cfg, "socks-proxy $socks_ip $socks_port $socks_auth_path";
        }
    }

    if (($state->{transport}->{ssh_enabled} // 'off') eq 'on') {
        my $local_port = $state->{transport}->{local_tunnel_port};

        if (!$local_port) {
            die "write_openvpn_config: ssh_enabled but SSH tunnel was not started";
        }

        push @cfg, "socks-proxy 127.0.0.1 $local_port";
    }

    $state->{connect}->{manport} = $get_next_free_local_port->('random_mgmt');
    $state->{connect}->{manpass} = genpass();

    open my $mp, '>', $mgmt_pass_path
        or die "write_openvpn_config: could not write $mgmt_pass_path: $!";

    print {$mp} $state->{connect}->{manpass}, "\n";
    close $mp;

    push @cfg, "management 127.0.0.1 $state->{connect}->{manport} $mgmt_pass_path";

    push @cfg, "remote $remote_addr $remote_port";
    push @cfg, "log $log_path";

    unlink $log_path if -e $log_path;

    open my $ovpn, '>', $ovpn_path
        or die "write_openvpn_config: could not write $ovpn_path: $!";

    print {$ovpn} join("\n", @cfg), "\n";
    close $ovpn;

    $launch->{config_path} = $ovpn_path;
    $launch->{log_path}    = $log_path;

    return $ovpn_path;
}

sub write_stunnel_config {
    my (%args) = @_;

    my $state = $args{state} or die "write_stunnel_config: missing state";
    my $ui    = $args{ui};
    my $L     = $args{L};

    my $get_next_free_local_port = $args{get_next_free_local_port}
        or die "write_stunnel_config: missing get_next_free_local_port callback";
    my $is_tunnel_up = $args{is_tunnel_up}
        or die "write_stunnel_config: missing is_tunnel_up callback";
    my $do_error = $args{do_error};

    my $remote_addr = $args{remote_addr} || $state->{connect}->{remote_addr}
        or die "write_stunnel_config: missing remote_addr";
    if (($state->{security}->{no_ipv6} // 'off') eq 'on'
        && $remote_addr =~ /:/
        && (($state->{connect}->{remote_ipv4} // '') ne '')) {
        $remote_addr = $state->{connect}->{remote_ipv4};
    }
    die "write_stunnel_config: IPv6 remote selected while Disable IPv6 is on"
        if (($state->{security}->{no_ipv6} // 'off') eq 'on') && $remote_addr =~ /:/;
    my $remote_port = $args{remote_port} || $state->{connect}->{port} || 443;

    my $stunnel_path = $args{stunnel_path} || $state->{app}->{program_files_dir} . "\\..\\user\\stunnel.conf";
    my $stunnel_exe  = $args{stunnel_exe}  || "cs-https-tun.exe";
    my $stunnel_log  = $args{stunnel_log}  || $state->{app}->{program_files_dir} . "\\..\\user\\stunnel-client.log";

    my $attempt_id = $state->{runtime}->{connect_attempt_id} // 0;
    my $old_status = $state->{runtime}->{status_text};
    $state->{runtime}->{status_text} =
        ($L && $L->{$state->{app}->{lang}}{TXT_STARTING_HTTPS_TUNNEL})
        || "Starting HTTPS tunnel...";
    _begin_tunnel_start_ui($state, $ui);
    _ui_pump();

    my $old_local_port = $state->{transport}->{local_tunnel_port};

    _kill_process_by_pid_or_image(
        state   => $state,
        pid_key => 'stunnel_pid',
        image   => 'cs-https-tun.exe',
    );
    delete $state->{transport}->{local_tunnel_port};

    # Give a just-killed stunnel a moment to release its old local listener.
    # The new listener is randomized, but waiting keeps readiness tests from
    # accidentally matching the previous process during rapid option changes.
    _wait_local_tcp_port_free($old_local_port, 3000) if $old_local_port;

    my $local_port = $get_next_free_local_port->('random_tunnel');

    if (!$local_port) {
        $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
        _ui_pump();

        $do_error->($L->{$state->{app}->{lang}}{ERR_NO_FREE_PORT})
            if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

        die "write_stunnel_config: no free local port";
    }
    $state->{transport}->{local_tunnel_port} = $local_port;
    $state->{runtime}->{local_tunnel_remote_addr} = $remote_addr;
    $state->{runtime}->{local_tunnel_remote_port} = $remote_port;
    $state->{runtime}->{local_tunnel_remote_ipv4} = $state->{connect}->{remote_ipv4} // '';
    $state->{runtime}->{local_tunnel_remote_ipv6} = $state->{connect}->{remote_ipv6} // '';

    unlink $stunnel_log if -e $stunnel_log;

    open my $st, '>', $stunnel_path
        or die "write_stunnel_config: could not write $stunnel_path: $!";

    print {$st} "output = $stunnel_log\n";
    print {$st} "debug = 5\n";
    print {$st} "[openvpn]\n";
    print {$st} "client = yes\n";
    my $connect_host = $remote_addr;
    $connect_host = "[$connect_host]" if $connect_host =~ /:/ && $connect_host !~ /^\[.*\]$/;

    print {$st} "accept = 127.0.0.1:$local_port\n";
    print {$st} "connect = $connect_host:$remote_port\n";
    print {$st} "sni = " . ($state->{transport}->{sni_host} || 'www.yahoo.com') . "\n";
	print {$st} "TIMEOUTconnect = 5\n";
	print {$st} "TIMEOUTclose = 5\n";
	print {$st} "TIMEOUTidle = 43200\n";
    close $st;

    my $stunnel_cmd = qq("$stunnel_exe" "$stunnel_path");
    my $stunnel_pid = _spawn_background_process(
        $stunnel_exe,
        $stunnel_cmd,
        $state->{app}->{program_files_dir} || '.',
    );

    if (!defined($stunnel_pid) || !$stunnel_pid) {
        delete $state->{transport}->{local_tunnel_port};
        $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
        _ui_pump();

        $do_error->($L->{$state->{app}->{lang}}{ERR_TUNNEL})
            if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

        die "write_stunnel_config: could not start stunnel";
    }

    $state->{runtime}->{stunnel_pid} = $stunnel_pid;

    my $stunnel_ready = _wait_helper_ready(
        state        => $state,
        attempt_id   => $attempt_id,
        port         => $local_port,
        pid          => $stunnel_pid,
        timeout_ms   => 15000,
        is_tunnel_up => $is_tunnel_up,
        log_ready_cb => sub { _stunnel_log_says_ready($local_port, $stunnel_log) },
    );

    if (!$stunnel_ready || !_connect_attempt_alive($state, $attempt_id)) {
        if ($state->{runtime}->{stunnel_pid}) {
            _run_hidden_cmd_wait("taskkill /F /T /PID $state->{runtime}->{stunnel_pid} >NUL 2>NUL", timeout => 5);
            delete $state->{runtime}->{stunnel_pid};
        }
        else {
            _run_hidden_cmd_wait("taskkill /F /T /IM cs-https-tun.exe >NUL 2>NUL", timeout => 5);
        }
        delete $state->{transport}->{local_tunnel_port};

        $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
        _ui_pump();

        my $msg = ($L->{$state->{app}->{lang}}{ERR_TUNNEL} || 'Unable to start tunnel');
        $msg .= "\n\nTransport: stunnel";
        $msg .= "\nLocal port: $local_port" if $local_port;
        $msg .= "\nRemote: $connect_host:$remote_port";
        my $tail = _tail_file($stunnel_log, 4000);
        my $netstat = _netstat_for_port($local_port);
        $msg .= "\n\nstunnel log:\n$tail" if length $tail;
        $msg .= "\n\nnetstat:\n$netstat" if length $netstat;
        $state->{runtime}->{last_tunnel_error} = $msg;

        $do_error->($msg)
            if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

        die "write_stunnel_config: stunnel failed to start";
    }

    $state->{runtime}->{status_text} = $old_status;
    _end_tunnel_start_ui($state, $ui, $attempt_id);
    _ui_pump();

    return {
        local_addr => '127.0.0.1',
        local_port => $local_port,
        path       => $stunnel_path,
    };
}

sub write_xray_config {
    my (%args) = @_;

    my $state = $args{state} or die "write_xray_config: missing state";
    my $ui    = $args{ui};
    my $L     = $args{L};

    my $get_next_free_local_port = $args{get_next_free_local_port}
        or die "write_xray_config: missing get_next_free_local_port callback";
    my $is_tunnel_up = $args{is_tunnel_up}
        or die "write_xray_config: missing is_tunnel_up callback";
    my $do_error = $args{do_error};

    my $remote_addr = $args{remote_addr} || $state->{connect}->{remote_addr}
        or die "write_xray_config: missing remote_addr";
    if (($state->{security}->{no_ipv6} // 'off') eq 'on'
        && $remote_addr =~ /:/
        && (($state->{connect}->{remote_ipv4} // '') ne '')) {
        $remote_addr = $state->{connect}->{remote_ipv4};
    }
    die "write_xray_config: IPv6 remote selected while Disable IPv6 is on"
        if (($state->{security}->{no_ipv6} // 'off') eq 'on') && $remote_addr =~ /:/;
    my $remote_port = $args{remote_port} || $state->{connect}->{port} || 443;

    my $xray_path = $args{xray_path} || '..\\user\\xray-config.json';
    my $xray_exe  = $args{xray_exe}  || 'xray.exe';
    my $xray_error_log  = $args{xray_error_log}  || $state->{app}->{program_files_dir} . "\\..\\user\\xray-error.log";
    my $xray_access_log = $args{xray_access_log} || $state->{app}->{program_files_dir} . "\\..\\user\\xray-access.log";

    my $sni = lc($state->{transport}->{sni_host} || '');
    my $sni_cfg = $state->{transport}->{xray_snis}->{$sni}
        or die "write_xray_config: unknown Xray SNI '$sni'";

    my $xray_uuid = $state->{transport}->{xray_uuid}
        or die "write_xray_config: missing state->{transport}->{xray_uuid}";

    my $attempt_id = $state->{runtime}->{connect_attempt_id} // 0;
    my $old_status = $state->{runtime}->{status_text};
    $state->{runtime}->{status_text} =
        ($L && $L->{$state->{app}->{lang}}{TXT_STARTING_XRAY_TUNNEL})
        || "Starting Xray tunnel...";
    _begin_tunnel_start_ui($state, $ui);
    _ui_pump();

    my $old_local_port = $state->{transport}->{local_tunnel_port};

    _kill_process_by_pid_or_image(
        state   => $state,
        pid_key => 'xray_pid',
        image   => 'xray.exe',
    );
    delete $state->{transport}->{local_tunnel_port};

    # Same stale-listener guard as stunnel. Xray can take a little longer to
    # shut down on slow Win7 32-bit VMs.
    _wait_local_tcp_port_free($old_local_port, 3000) if $old_local_port;

    my $local_port = $get_next_free_local_port->('random_tunnel');
	if (!$local_port) {
	    $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
    	_ui_pump();

    	$do_error->($L->{$state->{app}->{lang}}{ERR_NO_FREE_PORT})
        	if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

    	die "write_xray_config: no free local port";
	}
    $state->{transport}->{local_tunnel_port} = $local_port;
    $state->{runtime}->{local_tunnel_remote_addr} = $remote_addr;
    $state->{runtime}->{local_tunnel_remote_port} = $remote_port;
    $state->{runtime}->{local_tunnel_remote_ipv4} = $state->{connect}->{remote_ipv4} // '';
    $state->{runtime}->{local_tunnel_remote_ipv6} = $state->{connect}->{remote_ipv6} // '';

    my $network = 'tcp,udp';

    unlink $xray_error_log  if -e $xray_error_log;
    unlink $xray_access_log if -e $xray_access_log;

    my %xray_config = (
        log => {
            loglevel => 'info',
            error    => $xray_error_log,
            access   => $xray_access_log,
        },

        inbounds => [
            {
                listen   => '127.0.0.1',
                port     => 0 + $local_port,
                protocol => 'dokodemo-door',
                settings => {
                    address => $remote_addr,
                    port    => 0 + $remote_port,
                    network => $network,
                },
                tag => 'openvpn-in',
            },
        ],

        outbounds => [
            {
                protocol => 'vless',
                settings => {
                    vnext => [
                        {
                            address => $remote_addr,
                            port    => 0 + $remote_port,
                            users   => [
                                {
                                    id         => $xray_uuid,
                                    encryption => 'none',
                                    flow       => 'xtls-rprx-vision-udp443',
                                },
                            ],
                        },
                    ],
                },
                streamSettings => {
                    network  => 'tcp',
                    security => 'reality',
                    realitySettings => {
                        serverName  => $sni,
                        fingerprint => $sni_cfg->{fingerprint},
                        shortId     => $sni_cfg->{short_id},
                        spiderX     => '/',
                        publicKey   => $sni_cfg->{pubkey},
                    },
                },
                tag => 'reality-out',
            },
        ],

        routing => {
            rules => [
                {
                    type        => 'field',
                    inboundTag  => ['openvpn-in'],
                    outboundTag => 'reality-out',
                },
            ],
        },
    );

    open my $xfh, '>', $xray_path
        or die "write_xray_config: could not write $xray_path: $!";

    print {$xfh} JSON::PP->new->ascii->pretty->encode(\%xray_config);
    close $xfh;

    $xray_path = Win32::AbsPath::Fix($xray_path) || $xray_path;

    my $xray_cmd = qq("$xray_exe" run -config "$xray_path");
    my $xray_pid = _spawn_background_process(
        $xray_exe,
        $xray_cmd,
        $state->{app}->{program_files_dir} || '.',
    );

    if (!defined($xray_pid) || !$xray_pid) {
        delete $state->{transport}->{local_tunnel_port};
        $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
        _ui_pump();

        $do_error->($L->{$state->{app}->{lang}}{ERR_TUNNEL})
            if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

        die "write_xray_config: could not start Xray";
    }

    $state->{runtime}->{xray_pid} = $xray_pid;

    my $xray_ready = _wait_helper_ready(
        state        => $state,
        attempt_id   => $attempt_id,
        port         => $local_port,
        pid          => $xray_pid,
        timeout_ms   => 15000,
        is_tunnel_up => $is_tunnel_up,
        log_ready_cb => sub { _xray_log_says_ready($local_port, $xray_error_log, $xray_access_log) },
    );

    if (!$xray_ready || !_connect_attempt_alive($state, $attempt_id)) {
        if ($state->{runtime}->{xray_pid}) {
            _run_hidden_cmd_wait("taskkill /F /T /PID $state->{runtime}->{xray_pid} >NUL 2>NUL", timeout => 5);
            delete $state->{runtime}->{xray_pid};
        }
        else {
            _run_hidden_cmd_wait("taskkill /F /T /IM xray.exe >NUL 2>NUL", timeout => 5);
        }
        delete $state->{transport}->{local_tunnel_port};

        $state->{runtime}->{status_text} = $old_status;
        _end_tunnel_start_ui($state, $ui, $attempt_id);
        _ui_pump();

        my $msg = ($L->{$state->{app}->{lang}}{ERR_TUNNEL} || 'Unable to start tunnel');
        $msg .= "\n\nTransport: Xray";
        $msg .= "\nLocal port: $local_port" if $local_port;
        $msg .= "\nRemote: $remote_addr:$remote_port";
        $msg .= "\nSNI: $sni" if defined $sni && length $sni;
        my $err_tail = _tail_file($xray_error_log, 4000);
        my $acc_tail = _tail_file($xray_access_log, 2000);
        my $netstat = _netstat_for_port($local_port);
        $msg .= "\n\nxray error log:\n$err_tail" if length $err_tail;
        $msg .= "\n\nxray access log:\n$acc_tail" if length $acc_tail;
        $msg .= "\n\nnetstat:\n$netstat" if length $netstat;
        $state->{runtime}->{last_tunnel_error} = $msg;

        $do_error->($msg)
            if $do_error && $L && !_silent_tunnel_failure($state, $attempt_id);

        die "write_xray_config: Xray failed to start";
    }

    $state->{runtime}->{status_text} = $old_status;
    _end_tunnel_start_ui($state, $ui, $attempt_id);
    _ui_pump();

    return {
        local_addr => '127.0.0.1',
        local_port => $local_port,
        path       => $xray_path,
    };
}


sub _is_ipv4_literal {
    my ($addr) = @_;
    return 0 unless defined $addr;
    return 0 unless $addr =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
    for my $oct (split /\./, $addr) {
        return 0 if $oct > 255;
    }
    return 0 if $addr =~ /^(?:0\.0\.0\.0|127\.)/;
    return 1;
}

sub _is_ipv6_literal {
    my ($addr) = @_;
    return 0 unless defined $addr && $addr =~ /:/;
    $addr =~ s/^\[//;
    $addr =~ s/\]$//;
    return 0 if $addr eq '::1' || $addr =~ /^fe80:/i;
    return 1;
}

sub _push_direct_endpoint_bypass_route {
    my ($state, $cfg, $remote_addr) = @_;
    return unless $state && $cfg && ref($cfg) eq 'ARRAY';
    return unless defined $remote_addr && length $remote_addr;

    # For direct OpenVPN, add an explicit host route for the VPN endpoint before
    # redirect-gateway is installed.  On Win11, replacing the pushed redirect
    # gateway while Disable IPv6 is on could otherwise leave no /32 route for the
    # IPv4 VPN server; the data channel then routes into the VPN and eventually
    # ping-restarts even though the initial TLS connect succeeded.
    return unless _is_ipv4_literal($remote_addr);
    push @$cfg, "route $remote_addr 255.255.255.255 net_gateway";
}

sub _push_local_tunnel_bypass_routes {
    my ($state, $cfg) = @_;
    return unless $state && $cfg && ref($cfg) eq 'ARRAY';

    my $ssh_on = (($state->{transport}->{ssh_enabled} // 'off') eq 'on');
    my $https_on = (($state->{transport}->{https_enabled} // 'off') eq 'on')
        && (
               (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
            || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
        );
    return unless $ssh_on || $https_on;

    my @candidates;
    push @candidates, $state->{runtime}->{local_tunnel_remote_addr}
        if defined $state->{runtime}->{local_tunnel_remote_addr};

    # If the helper endpoint was selected from a server record, keep both
    # family literals available.  The actual helper normally uses
    # local_tunnel_remote_addr; the extra family route is harmless and prevents
    # Windows from moving a helper's reconnect path into the VPN if it flips
    # address families after the default route changes.
    push @candidates, $state->{runtime}->{local_tunnel_remote_ipv4}
        if defined $state->{runtime}->{local_tunnel_remote_ipv4};
    push @candidates, $state->{runtime}->{local_tunnel_remote_ipv6}
        if defined $state->{runtime}->{local_tunnel_remote_ipv6};

    my %seen;
    for my $addr (@candidates) {
        next unless defined $addr && length $addr;
        $addr =~ s/^\[//;
        $addr =~ s/\]$//;
        next if $seen{lc $addr}++;

        if (_is_ipv4_literal($addr)) {
            push @$cfg, "route $addr 255.255.255.255 net_gateway";
        }
        # IPv6 helper bypass routes are installed before OpenVPN starts with
        # route -6 ADD.  Do not put them in vpn.ovpn: OpenVPN processes static
        # route-ipv6 entries before the pushed ifconfig-ipv6 is active on TAP,
        # which causes a noisy "no IPv6 has been configured" warning.
    }
}

sub genpass {
 # generate a random password for the management interface
 my @chars = ('a' .. 'z', '0' ..'9', 'A' .. 'Z');
 return join '' => map $chars[rand @chars], 0 .. int(rand(100))+20;
}

sub _run_detached_cmd {
    my ($cmd) = @_;
    return unless defined $cmd && length $cmd;

    # This wrapper keeps the Tk callback tiny and isolates any spawn warnings.
    eval {
        system(1, $cmd);
        1;
    } or warn "_run_detached_cmd failed for [$cmd]: $@";
}

1;
