package TapManager;

use strict;
use warnings;
use Exporter qw(import);
use Tkx;
use Cwd qw(abs_path);

our @EXPORT_OK = qw(
    ensure_tap_adapter
    list_tap_adapters
);

use constant TAP_DEBUG => 0;
my $CREATE_NO_WINDOW_FLAG = 0x08000000;

sub _dbg {
    return unless TAP_DEBUG;
    my ($msg) = @_;
    $msg = '' unless defined $msg;
    print STDERR "[TapManager] $msg\n";
}

sub ensure_tap_adapter {
    my (%args) = @_;

    my $state     = $args{state}     or die "ensure_tap_adapter: missing state";
    my $L         = $args{L};
    my $on_status = $args{on_status} || sub {};
    my $Registry  = $args{Registry};

    my $wanted_name = $args{name} || 'cryptostorm VPN';

    my $ovpn_exe = $args{ovpn_exe}
        || $state->{app}->{ovpn_exe}
        || 'openvpn.exe';

    my $tap_os_dir = _tap_os_dir($state);
    my $tap_arch   = _is_64bit_windows() ? 'amd64' : 'i386';
    my $tap_tool   = ($tap_os_dir eq 'win10') ? 'devcon.exe' : 'tapinstall.exe';

    my $tapinstall_exe = $args{tapinstall_exe}
        || "$tap_os_dir\\$tap_arch\\$tap_tool";

    my $tap_inf = $args{tap_inf}
        || "$tap_os_dir\\$tap_arch\\OemVista.inf";

    my $tap_sys = $args{tap_sys} || _sibling_path($tap_inf, 'tap0901.sys');
    my $tap_cat = $args{tap_cat} || _sibling_path($tap_inf, 'tap0901.cat');

    $state->{connect}->{tap_install_error} = '';

    for ($tapinstall_exe, $tap_inf, $tap_sys, $tap_cat) {
        $_ = _canonical_existing_path($_) if defined $_ && -e $_;
    }

    _dbg("ensure_tap_adapter wanted_name=$wanted_name");
    _dbg("ovpn_exe=$ovpn_exe");
    _dbg("tap_os_dir=$tap_os_dir");
    _dbg("tap_arch=$tap_arch");
    _dbg("tap_tool=$tap_tool");
    _dbg("tapinstall_exe=$tapinstall_exe");
    _dbg("tap_inf=$tap_inf");
    _dbg("tap_sys=$tap_sys");
    _dbg("tap_cat=$tap_cat");

    $on_status->('Checking TAP adapter...');

    my @before = list_tap_adapters(
        state    => $state,
        ovpn_exe => $ovpn_exe,
    );

    my $known_guid = _normalize_guid($state->{connect}->{cryptostorm_tap_guid});

    # 1. Prefer the adapter GUID we previously installed/used.  If the user
    # renames our TAP, this is the only existing adapter we rename back.
    if (length $known_guid) {
        for my $tap (@before) {
            if (_normalize_guid($tap->{guid}) eq $known_guid) {
                _dbg("found known cryptostorm TAP by GUID: name=" . ($tap->{name} // '') . " guid=$known_guid");
                $tap = _rename_known_tap_if_needed(
                    state       => $state,
                    tap         => $tap,
                    wanted_name => $wanted_name,
                    ovpn_exe    => $ovpn_exe,
                    on_status   => $on_status,
                );
                _remember_tap($state, $tap, 1);
                return 1;
            }
        }
    }

    # 2. Prefer an explicitly owned/named adapter.
    for my $tap (@before) {
        if (lc($tap->{name} // '') eq lc($wanted_name)) {
            _dbg("found existing owned TAP: $tap->{name} guid=" . ($tap->{guid} // ''));
            _remember_tap($state, $tap, 1);
            return 1;
        }
    }

    # 3. If there is exactly one visible TAP, use it by GUID but do not rename
    # it.  It may belong to another VPN.  We only rename known/owned TAPs or
    # a TAP we create during this run.
    if (@before == 1) {
        my $tap = $before[0];

        _dbg(
            "using sole existing TAP by GUID without renaming: name="
            . ($tap->{name} // '')
            . " guid="
            . ($tap->{guid} // '')
        );

        _remember_tap($state, $tap, 0);
        return 1;
    }

    # 4. Multiple adapters with no owned/known cryptostorm adapter.
    # Safer to stop instead of hijacking another VPN's adapter.
    if (@before > 1) {
        _dbg("multiple TAP adapters found and none named/known as $wanted_name; refusing to guess");

        for my $tap (@before) {
            _dbg(
                "candidate TAP: name="
                . ($tap->{name} // '')
                . " guid="
                . ($tap->{guid} // '')
                . " driver="
                . ($tap->{driver} // '')
            );
        }

        return _tap_fail(
            $state,
            "Multiple TAP adapters are installed, but none is named $wanted_name and no saved cryptostorm TAP GUID matched."
        );
    }

    # 5. No visible adapters: install one using the bundled TAP package.
    _dbg("no usable TAP adapters found; installing new TAP");

    _free_interface_name($wanted_name);

    if ($Registry) {
        eval {
            $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Network/NewNetworkWindowOff/'} = {};
            1;
        };
    }

    if (!-e $tapinstall_exe) {
        return _tap_fail($state, "TAP install tool missing: $tapinstall_exe");
    }

    if (!-e $tap_inf) {
        return _tap_fail($state, "TAP driver INF missing: $tap_inf");
    }

    if (!-e $tap_sys) {
        return _tap_fail($state, "TAP driver SYS missing: $tap_sys");
    }

    if (!-e $tap_cat) {
        return _tap_fail($state, "TAP driver CAT missing: $tap_cat");
    }

    my $os_is_64bit = _is_64bit_windows();
    my $tapinstall_machine = _pe_machine($tapinstall_exe);
    my $tap_sys_machine = _pe_machine($tap_sys);

    if ($os_is_64bit && $tapinstall_machine eq 'x86') {
        return _tap_fail(
            $state,
            "TAP install tool architecture mismatch: this is 64-bit Windows, but $tapinstall_exe is the 32-bit x86 tool.\n"
            . "Use $tap_os_dir\\amd64\\$tap_tool on 64-bit Windows."
        );
    }

    if (!$os_is_64bit && $tapinstall_machine eq 'amd64') {
        return _tap_fail(
            $state,
            "TAP install tool architecture mismatch: this is 32-bit Windows, but $tapinstall_exe is the 64-bit amd64 tool.\n"
            . "Use $tap_os_dir\\i386\\$tap_tool on 32-bit Windows."
        );
    }

    if ($os_is_64bit && $tap_sys_machine eq 'x86') {
        return _tap_fail(
            $state,
            "TAP driver architecture mismatch: this is 64-bit Windows, but tap0901.sys is the 32-bit x86 driver.\n"
            . "Use $tap_os_dir\\amd64\\OemVista.inf, $tap_os_dir\\amd64\\tap0901.sys, and $tap_os_dir\\amd64\\tap0901.cat on 64-bit Windows."
        );
    }

    if (!$os_is_64bit && $tap_sys_machine eq 'amd64') {
        return _tap_fail(
            $state,
            "TAP driver architecture mismatch: this is 32-bit Windows, but tap0901.sys is the 64-bit amd64 driver.\n"
            . "Use $tap_os_dir\\i386\\OemVista.inf, $tap_os_dir\\i386\\tap0901.sys, and $tap_os_dir\\i386\\tap0901.cat on 32-bit Windows."
        );
    }

    if (!_is_elevated()) {
        return _tap_fail(
            $state,
            "Administrator privileges are required to install the TAP driver.\n"
            . "Start the client from an elevated Administrator command prompt, or run the installed client elevated for first-time TAP install."
        );
    }

    my $install_msg = 'Installing TAP adapter';
    $on_status->("$install_msg...");

    my $install_cmd = qq("$tapinstall_exe" install "$tap_inf" tap0901);

    _dbg("running: $install_cmd");

    my ($install_result, $install_out, $install_exit) = _run_process_tk(
        $install_cmd,
        180000,
        sub {
            my ($spin) = @_;
            $on_status->("$spin $install_msg...");
        },
    );

    $install_out ||= '';

    my $install_output = "\n\n> $install_cmd\n$install_out";

    print STDERR "\n[TapManager] $install_cmd\n$install_out\n";
    _dbg("TAP install tool ok=$install_result exit=$install_exit output=$install_out");

    if (!$install_result) {
        my $msg = "$tap_tool failed.";
        $msg .= "\n\nTAP install output:\n$install_output" if length $install_output;
        return _tap_fail($state, $msg);
    }

    $on_status->('Waiting for TAP adapter...');

    my %before_guids = map { (_normalize_guid($_->{guid}) => 1) } @before;
    my $created;

    for (1 .. 90) {
        my @after = list_tap_adapters(
            state    => $state,
            ovpn_exe => $ovpn_exe,
        );

        my @new = grep {
            my $guid = _normalize_guid($_->{guid});
            length($guid) && !$before_guids{$guid};
        } @after;

        if (@new) {
            $created = $new[0];
            last;
        }

        # If we started from zero visible TAPs and one is now visible, use it.
        if (!@before && @after == 1) {
            $created = $after[0];
            last;
        }

        eval { Tkx::update(); 1 } or eval { Tkx::update('idletasks'); };
        select undef, undef, undef, 0.50;
    }

    if (!$created) {
        my $msg = "TAP driver installed, but Windows did not expose a usable TAP network interface.";
        $msg .= "\n\nTAP install output:\n$install_output" if length $install_output;
        return _tap_fail($state, $msg);
    }

    _dbg("new TAP ready: name=" . ($created->{name} // '') . " guid=" . ($created->{guid} // ''));

    # This adapter was just installed by us, so it is safe to claim the friendly
    # name.  Existing third-party TAP adapters are not renamed above.
    if (lc($created->{name} // '') ne lc($wanted_name)) {
        $on_status->('Naming TAP adapter...');
        _rename_interface($created->{name}, $wanted_name);

        for (1 .. 40) {
            my @final = list_tap_adapters(
                state    => $state,
                ovpn_exe => $ovpn_exe,
            );

            for my $tap (@final) {
                if (_normalize_guid($tap->{guid}) eq _normalize_guid($created->{guid})) {
                    $created = $tap;
                    last;
                }
            }

            last if lc($created->{name} // '') eq lc($wanted_name);

            Tkx::update('idletasks');
            select undef, undef, undef, 0.25;
        }
    }

    _remember_tap($state, $created, 1);
    return 1;
}

sub _normalize_guid {
    my ($guid) = @_;

    return '' unless defined $guid;
    return '' if ref $guid;

    $guid =~ s/[{}]//g;
    $guid =~ s/^\s+|\s+$//g;

    return uc($guid);
}

sub _remember_tap {
    my ($state, $tap, $owned_by_us) = @_;

    return 0 unless $state && ref($tap) eq 'HASH';

    my $guid = _normalize_guid($tap->{guid});

    $state->{connect}->{tap_adapter_name} = $tap->{name} // '';
    $state->{connect}->{tap_adapter_guid} = $guid;

    if ($owned_by_us && length $guid) {
        $state->{connect}->{cryptostorm_tap_guid} = $guid;
    }

    return 1;
}

sub _rename_known_tap_if_needed {
    my (%args) = @_;

    my $state       = $args{state};
    my $tap         = $args{tap};
    my $wanted_name = $args{wanted_name} || 'cryptostorm VPN';
    my $ovpn_exe    = $args{ovpn_exe} || 'openvpn.exe';
    my $on_status   = $args{on_status} || sub {};

    return $tap unless ref($tap) eq 'HASH';
    return $tap if lc($tap->{name} // '') eq lc($wanted_name);

    my $guid = _normalize_guid($tap->{guid});
    return $tap unless length $guid;

    $on_status->('Naming TAP adapter...');
    _rename_interface($tap->{name}, $wanted_name);

    for (1 .. 30) {
        my @renamed = list_tap_adapters(
            state    => $state,
            ovpn_exe => $ovpn_exe,
        );

        for my $candidate (@renamed) {
            if (_normalize_guid($candidate->{guid}) eq $guid) {
                return $candidate;
            }
        }

        Tkx::update('idletasks');
        select undef, undef, undef, 0.20;
    }

    return $tap;
}

sub _sibling_path {
    my ($path, $file) = @_;

    $path ||= '';
    $file ||= '';

    if ($path =~ /^(.*[\\\/])[^\\\/]+$/) {
        return $1 . $file;
    }

    return $file;
}

sub _canonical_existing_path {
    my ($path) = @_;

    return $path unless defined $path && length $path;

    my $abs = eval { abs_path($path) };
    if (defined $abs && length $abs) {
        $abs =~ s{/}{\\}g if $^O =~ /MSWin32/i;
        return $abs;
    }

    $path =~ s{/}{\\}g if $^O =~ /MSWin32/i;

    return $path;
}

sub _tap_fail {
    my ($state, $msg) = @_;

    $msg ||= 'TAP install tool failed';

    if ($state) {
        $state->{connect}->{tap_install_error} = $msg;
    }

    print STDERR "[TapManager] $msg\n";
    _dbg($msg);

    return 0;
}

sub _is_64bit_windows {
    return 0 unless $^O =~ /MSWin32/i;

    return 1 if ($ENV{PROCESSOR_ARCHITEW6432} || '') =~ /AMD64|IA64|ARM64/i;
    return 1 if ($ENV{PROCESSOR_ARCHITECTURE} || '') =~ /AMD64|IA64|ARM64/i;

    return 0;
}

sub _tap_os_dir {
    my ($state) = @_;

    my $major;

    if ($state && ref($state) eq 'HASH') {
        $major = $state->{runtime}->{os_major};
    }

    if (!defined($major) || $major !~ /^\d+$/) {
        eval {
            require Win32;
            my (undef, $os_major) = Win32::GetOSVersion();
            $major = $os_major if defined $os_major;
            1;
        };
    }

    $major = 10 unless defined($major) && $major =~ /^\d+$/;

    return ($major >= 10) ? 'win10' : 'win7';
}

sub _is_elevated {
    return 1 unless $^O =~ /MSWin32/i;

    my $rc = system('fltmc >NUL 2>&1');
    return $rc == 0 ? 1 : 0;
}

sub _pe_machine {
    my ($path) = @_;

    return '' unless defined $path && -e $path;

    open my $fh, '<:raw', $path or return '';
    read($fh, my $mz, 64) == 64 or do { close $fh; return ''; };

    return '' unless substr($mz, 0, 2) eq "MZ";

    my $peoff = unpack('V', substr($mz, 0x3c, 4));
    seek($fh, $peoff, 0) or do { close $fh; return ''; };
    read($fh, my $pe, 6) == 6 or do { close $fh; return ''; };
    close $fh;

    return '' unless substr($pe, 0, 4) eq "PE\0\0";

    my $machine = unpack('v', substr($pe, 4, 2));

    return 'x86'   if $machine == 0x014c;
    return 'amd64' if $machine == 0x8664;
    return 'arm64' if $machine == 0xaa64;

    return sprintf('0x%04x', $machine);
}

sub _free_interface_name {
    my ($wanted_name) = @_;

    return 1 unless defined $wanted_name && length $wanted_name;
    return 1 unless _interface_name_exists($wanted_name);

    my $old_name = "$wanted_name legacy";
    if (_interface_name_exists($old_name)) {
        $old_name = "$wanted_name legacy $$";
    }

    my $cmd = qq(netsh interface set interface name="$wanted_name" newname="$old_name");
    _dbg("freeing existing non-TAP interface name: $cmd");

    _run_wait_tk($cmd, 15000);

    return !_interface_name_exists($wanted_name);
}

sub _rename_interface {
    my ($old_name, $new_name) = @_;

    return 0 unless defined $old_name && length $old_name;
    return 0 unless defined $new_name && length $new_name;
    return 1 if lc($old_name) eq lc($new_name);

    _free_interface_name($new_name);

    my $rename_cmd = qq(netsh interface set interface name="$old_name" newname="$new_name");
    _dbg("running: $rename_cmd");

    return _run_wait_tk($rename_cmd, 15000);
}

sub _interface_name_exists {
    my ($name) = @_;

    return 0 unless defined $name && length $name;

    my $cmd = qq(netsh interface show interface name="$name" 2>&1);
    my @out = _capture_lines_hidden($cmd, 10000);

    return 0 if grep { /not found|does not exist|The filename, directory name, or volume label syntax is incorrect/i } @out;
    return 1 if grep { /\Q$name\E/i } @out;

    return 0;
}

sub _interface_visible_to_windows {
    my ($name) = @_;

    return 0 unless defined $name && length $name;

    my $cmd = qq(netsh interface show interface name="$name" 2>&1);
    my @out = _capture_lines_hidden($cmd, 10000);
    my $text = join('', @out);

    return 0 if $text =~ /not found|does not exist|The filename, directory name, or volume label syntax is incorrect/i;
    return 1 if $text =~ /\Q$name\E/i;

    return 0;
}

sub _is_tap_windows6_driver {
    my ($driver) = @_;

    $driver = '' unless defined $driver;
    $driver =~ s/^\s+|\s+$//g;

    # OpenVPN 2.7+ can list DCO adapters here too.  This client is still
    # TAP-only, and transports like SSH/SOCKS disable DCO anyway, so never let
    # an ovpn-dco adapter satisfy TAP selection.
    return 0 if $driver =~ /^ovpn-dco/i;

    # Current OpenVPN prints tap-windows6 explicitly.  Keep accepting an empty
    # driver string for older --show-adapters output, but reject every other
    # named driver.
    return 1 if $driver eq '';
    return 1 if $driver =~ /^tap-windows6$/i;

    return 0;
}

sub list_tap_adapters {
    my (%args) = @_;

    my $state    = $args{state};
    my $require_windows_visible = exists $args{require_windows_visible}
        ? $args{require_windows_visible}
        : 1;
    my $ovpn_exe = $args{ovpn_exe}
        || ($state ? $state->{app}->{ovpn_exe} : undef)
        || 'openvpn.exe';

    my $cmd = qq("$ovpn_exe" --show-adapters 2>&1);
    _dbg("running: $cmd");

    my @out = _capture_lines_hidden($cmd, 15000);

    my @adapters;

    for my $line (@out) {
        chomp $line;
        $line =~ s/\r\z//;

        _dbg("show-adapters: $line") if TAP_DEBUG;

        if ($line =~ /['"](.+?)['"]\s+\{([0-9A-Fa-f-]{36})\}\s*(\S+)?/) {
            my $guid = uc($2);
            $guid =~ s/[{}]//g;
            my $driver = $3 // '';

            if (!_is_tap_windows6_driver($driver)) {
                _dbg("ignoring non-TAP OpenVPN adapter: $line");
                next;
            }

            my $windows_visible = $require_windows_visible
                ? _interface_visible_to_windows($1)
                : 0;

            my $adapter = {
                name   => $1,
                guid   => $guid,
                driver => $driver,
                raw    => $line,
                windows_visible => $windows_visible,
            };

            if (!$require_windows_visible || $windows_visible) {
                push @adapters, $adapter;
            }
            else {
                _dbg("ignoring stale/non-visible TAP adapter: $line");
            }
            next;
        }

        # fallback
        if ($line =~ /^(.+?)\s+\{([0-9A-Fa-f-]{36})\}\s*(\S+)?/) {
            my $name = $1;
            my $guid = uc($2);
            my $driver = $3 // '';

            $name =~ s/^\s+|\s+$//g;
            $guid =~ s/[{}]//g;

            if (!_is_tap_windows6_driver($driver)) {
                _dbg("ignoring non-TAP OpenVPN adapter: $line");
                next;
            }

            my $windows_visible = $require_windows_visible
                ? _interface_visible_to_windows($name)
                : 0;

            my $adapter = {
                name   => $name,
                guid   => $guid,
                driver => $driver,
                raw    => $line,
                windows_visible => $windows_visible,
            };

            if (!$require_windows_visible || $windows_visible) {
                push @adapters, $adapter;
            }
            else {
                _dbg("ignoring stale/non-visible TAP adapter: $line");
            }
            next;
        }
    }

    _dbg("adapter_count=" . scalar(@adapters));

    return @adapters;
}


sub _capture_lines_hidden {
    my ($cmd, $timeout_ms) = @_;
    $timeout_ms ||= 15000;

    if ($^O =~ /MSWin32/i) {
        my (undef, $out, undef) = _run_hidden_cmd($cmd, $timeout_ms, 1);
        return split(/\n/, $out // '');
    }

    my @out = `$cmd`;
    return @out;
}

sub _run_hidden_cmd {
    my ($cmd, $timeout_ms, $capture) = @_;

    $timeout_ms ||= 30000;
    $capture = $capture ? 1 : 0;

    my $loaded = eval { require Win32::Process; 1 };
    if (!$loaded) {
        if ($capture) {
            my @out = `$cmd`;
            return (($? == 0) ? 1 : 0, join('', @out), $? >> 8);
        }

        my $pid = system(1, $cmd);
        return (0, '', 'spawn failed') unless defined($pid) && $pid;
        my $deadline = time + ($timeout_ms / 1000);
        while (kill(0, $pid)) {
            eval { Tkx::update('idletasks'); };
            return (0, '', 'timeout') if time >= $deadline;
            select undef, undef, undef, 0.05;
        }
        return (1, '', 0);
    }

    my $comspec = $ENV{ComSpec} || "$ENV{SystemRoot}\\System32\\cmd.exe";
    my $tmp = $ENV{TEMP} || $ENV{TMP} || '.';
    $tmp =~ s/[\\\/]\z//;

    my $stamp = $$ . "_" . int(time * 1000) . "_" . int(rand(100000));
    my $out_file = "$tmp\\cs_cmd_$stamp.log";
    my $bat_file = "$tmp\\cs_cmd_$stamp.cmd";

    my $bat;
    if (!open $bat, '>:raw', $bat_file) {
        return (0, "Could not write temporary command file: $bat_file: $!", 'setup failed');
    }

    print {$bat} "\@echo off\r\n";
    if ($capture) {
        print {$bat} "$cmd > \"$out_file\" 2>&1\r\n";
    }
    else {
        print {$bat} "$cmd >NUL 2>NUL\r\n";
    }
    print {$bat} "exit /b %ERRORLEVEL%\r\n";
    close $bat;

    my $cmdline = qq($comspec /D /S /C call "$bat_file");
    my $proc;
    my $created = Win32::Process::Create(
        $proc,
        $comspec,
        $cmdline,
        0,
        $CREATE_NO_WINDOW_FLAG,
        '.',
    );

    if (!$created) {
        my $err = eval { Win32::FormatMessage(Win32::GetLastError()) } || 'unknown error';
        unlink $bat_file if -e $bat_file;
        return (0, "Could not start hidden command: $err\n$cmd", 'spawn failed');
    }

    my $deadline = time + ($timeout_ms / 1000);
    my $exit = 259;

    while (1) {
        $proc->GetExitCode($exit);
        last if defined($exit) && $exit != 259;

        eval { Tkx::update('idletasks'); };

        if (time >= $deadline) {
            eval { $proc->Kill(1); };
            my $out = $capture ? _read_and_delete($out_file) : '';
            unlink $bat_file if -e $bat_file;
            return (0, $out, 'timeout');
        }

        select undef, undef, undef, 0.05;
    }

    my $out = $capture ? _read_and_delete($out_file) : '';
    unlink $bat_file if -e $bat_file;

    return (($exit == 0) ? 1 : 0, $out, $exit);
}

sub _run_wait_tk {
    my ($cmd, $timeout_ms) = @_;

    $timeout_ms ||= 30000;

    if ($^O =~ /MSWin32/i) {
        my ($ok, undef, undef) = _run_hidden_cmd($cmd, $timeout_ms, 0);
        return $ok ? 1 : 0;
    }

    my $pid = system(1, $cmd);

    if (!defined $pid || $pid == 0) {
        _dbg("system spawn failed for: $cmd");
        return 0;
    }

    my $deadline = time + ($timeout_ms / 1000);

    while (kill(0, $pid)) {
        Tkx::update('idletasks');

        if (time >= $deadline) {
            _dbg("timeout waiting for pid=$pid cmd=$cmd");
            return 0;
        }

        select undef, undef, undef, 0.05;
    }

    return 1;
}

sub _run_capture_tk {
    my ($cmd, $timeout_ms) = @_;

    $timeout_ms ||= 120000;

    my $tmp = $ENV{TEMP} || $ENV{TMP} || '.';
    $tmp =~ s/[\\\/]\z//;

    my $out_file = $tmp . "\\cs_tapinstall_" . $$ . "_" . int(time * 1000) . ".log";
    my $run_cmd = qq($cmd > "$out_file" 2>&1);

    my $pid = system(1, $run_cmd);

    if (!defined $pid || $pid == 0) {
        return (0, "Could not start: $cmd", 'spawn failed');
    }

    my $deadline = time + ($timeout_ms / 1000);
    my $timed_out = 0;

    while (kill(0, $pid)) {
        eval { Tkx::update(); 1 } or eval { Tkx::update('idletasks'); };

        if (time >= $deadline) {
            $timed_out = 1;
            last;
        }

        select undef, undef, undef, 0.05;
    }

    my $out = '';
    if (-e $out_file) {
        if (open my $fh, '<:raw', $out_file) {
            local $/;
            $out = <$fh> // '';
            close $fh;
        }
        unlink $out_file;
    }

    $out =~ s/\s+\z//;

    if ($timed_out) {
        return (0, $out . "\nTimed out waiting for TAP install tool.", 'timeout');
    }

    my $ok = 0;
    if ($out =~ /Drivers installed successfully/i && $out !~ /failed|UpdateDriverForPlugAndPlayDevices failed|error/i) {
        $ok = 1;
    }

    return ($ok, $out, 'done');
}

sub _run_process_tk {
    my ($cmd, $timeout_ms, $tick_cb) = @_;

    $timeout_ms ||= 120000;

    if ($^O =~ /MSWin32/i) {
        my $loaded = eval { require Win32::Process; 1 };

        if ($loaded) {
            my $comspec = $ENV{ComSpec} || "$ENV{SystemRoot}\\System32\\cmd.exe";
            my $tmp = $ENV{TEMP} || $ENV{TMP} || '.';
            $tmp =~ s/[\\\/]\z//;

            my $stamp = $$ . "_" . int(time * 1000);
            my $out_file = "$tmp\\cs_tapinstall_$stamp.log";
            my $bat_file = "$tmp\\cs_tapinstall_$stamp.cmd";

            my $bat;
            if (!open $bat, '>:raw', $bat_file) {
                return (0, "Could not write temporary command file: $bat_file: $!", 'setup failed');
            }

            print {$bat} "\@echo off\r\n";
            print {$bat} "$cmd > \"$out_file\" 2>&1\r\n";
            print {$bat} "exit /b %ERRORLEVEL%\r\n";
            close $bat;

            my $cmdline = qq($comspec /D /S /C call "$bat_file");
            my $proc;

            my $created = Win32::Process::Create(
                $proc,
                $comspec,
                $cmdline,
                0,
                $CREATE_NO_WINDOW_FLAG,
                '.',
            );

            if (!$created) {
                my $err = eval { Win32::FormatMessage(Win32::GetLastError()) } || 'unknown error';
                unlink $bat_file if -e $bat_file;
                return (0, "Could not start TAP install command: $err\n$cmd", 'spawn failed');
            }

            my $deadline = time + ($timeout_ms / 1000);
            my $exit = 259;
            my @spin = ('[|]', '[/]', '[-]', '[\\]');
            my $spin_i = 0;
            my $loop_i = 0;

            while (1) {
                $proc->GetExitCode($exit);
                last if defined($exit) && $exit != 259;

                if ($tick_cb && (($loop_i++ % 8) == 0)) {
                    eval { $tick_cb->($spin[$spin_i++ % @spin]); 1 };
                }

                eval { Tkx::update(); 1 } or eval { Tkx::update('idletasks'); };

                if (time >= $deadline) {
                    eval { $proc->Kill(1); };
                    my $out = _read_and_delete($out_file);
                    unlink $bat_file if -e $bat_file;
                    return (0, $out . "\nTimed out waiting for TAP install tool.\n$cmd", 'timeout');
                }

                select undef, undef, undef, 0.05;
            }

            my $out = _read_and_delete($out_file);
            unlink $bat_file if -e $bat_file;

            $out =~ s/\s+\z//;

            my $ok = ($exit == 0 || $out =~ /Drivers installed successfully/i)
                && $out !~ /failed|UpdateDriverForPlugAndPlayDevices failed|error/i;

            $out = "TAP install tool exit code $exit" unless length $out;

            return ($ok ? 1 : 0, $out, $exit);
        }
    }

    return _run_capture_tk($cmd, $timeout_ms);
}

sub _read_and_delete {
    my ($path) = @_;

    my $out = '';

    if (defined $path && -e $path) {
        if (open my $fh, '<:raw', $path) {
            local $/;
            $out = <$fh> // '';
            close $fh;
        }
        unlink $path;
    }

    return $out;
}

sub _run_capture {
    my ($cmd) = @_;

    my $full_cmd = "$cmd 2>&1";
    my @out = `$full_cmd`;
    my $exit = $? >> 8;
    my $sig  = $? & 127;

    my $text = join('', @out);
    $text =~ s/\s+\z//;

    my $ok = ($? == 0) ? 1 : 0;

    return ($ok, $text, $sig ? "signal $sig" : $exit);
}

1;
