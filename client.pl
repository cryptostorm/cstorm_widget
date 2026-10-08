#!/usr/bin/perl
our $VERSION;
BEGIN {
    $VERSION = "4.05";
	# Set version-specific PAR cache folder to ensure updates don't run old code
    $ENV{PAR_GLOBAL_TEMP} = 1 unless defined $ENV{PAR_GLOBAL_TEMP};
    $ENV{PAR_CACHE_ID} = "cswidget_v${VERSION}" unless defined $ENV{PAR_CACHE_ID};

	my $par_user = sprintf("%x", 0x61636f726e + $$);
    $ENV{MYAPP_PAR_PATH} = "$ENV{TEMP}/par-$par_user/cache-$ENV{PAR_CACHE_ID}";
    mkdir $ENV{MYAPP_PAR_PATH} unless -d $ENV{MYAPP_PAR_PATH};

    # Force preload before PAR loader
    $ENV{PAR_TEMP} = $ENV{MYAPP_PAR_PATH};
    $ENV{PAR_CLEAN} = 1;
}
use PAR;
use lib "$ENV{MYAPP_PAR_PATH}/inc/lib";
use lib "$ENV{MYAPP_PAR_PATH}/inc";
use strict;
use warnings;
use threads;
use threads::shared;
use Scalar::Util qw(blessed);
use utf8;
use Encode;
binmode(STDOUT, ":utf8");
use Tkx;
Tkx::encoding("system", "utf-8");
use JSON::PP;
use File::Slurp;
use HTTP::Tiny;
use Tkx::SplashScreen;
use Win32::GUI;
use Digest::SHA qw(sha512_hex);
use File::Copy qw(copy);
use Time::HiRes qw(time);
use IO::Select;
use IO::Socket;
use Socket;
use Socket6;
use Win32::AbsPath;
use Win32::File::VersionInfo;
use Win32::Process;
use Win32::Process::List;
use Win32::Event;
use Win32::Clipboard;
use Win32::Service;
use Win32::TieRegistry qw(REG_DWORD REG_MULTI_SZ REG_SZ),(Delimiter => "/");
use Win32::IPHelper;
use lib ".";
use LangPicker;
use ServerPicker;
use CSConfig qw(restore_upgrade_files load_config save_config);
use Startup qw(run_startup);
use MainWindow qw(build_main_window);
use TrayUI qw(init_tray hide_to_tray show_from_tray rebuild_tray_menu track_tray_menu remove_tray);
use OptionsWindow qw(build_options_window);
use OpenVPN qw(do_connect watch_logbox write_openvpn_config write_stunnel_config write_xray_config);
use PostConnect qw(start_post_connect_checks);
use TapManager qw(ensure_tap_adapter list_tap_adapters);

# Listen for power events
# https://learn.microsoft.com/en-us/windows/win32/power/wm-powerbroadcast
use constant WM_POWERBROADCAST => 0x218;
use constant PBT_APMSUSPEND => 0x4;
use constant PBT_APMRESUMEAUTOMATIC => 0x12;
use constant PBT_APMRESUMECRITICAL => 0x6;
my $CREATE_NO_WINDOW_FLAG = 0x08000000;
my $powerw = Win32::GUI::Window->new();
$powerw->Hook(WM_POWERBROADCAST, \&power_event);
$powerw->Hide();

# Prevent system() from showing console windows
if (defined &Win32::SetChildShowWindow) {
 Win32::SetChildShowWindow(0);
}

# Prevent an empty Tk window from briefly appearing
Tkx::widget->new(".")->g_wm_withdraw();

# Create our registry key
$Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'} = {};
my $regkey = $Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'};

my $state = {
    app => {
        version => $VERSION,
        bitness => {},
        lang => '',
		program_files_dir => {},
        config_file => '..\user\config.ini',
        config_json_file => '..\user\config.json',
        auth_file => '..\user\client.dat',
		serversfile => '..\user\latest_list.json',
		clip => Win32::Clipboard(),
		ossh_exe => "cs-ssh-tun.exe",
		ossh_ver => {},
		ossl_exe => "ossl.exe",
		ossl_ver => {},
		ovpn_exe => "csvpn.exe",
		ovpn_ver => {},
		stunnel_exe => "cs-https-tun.exe",
		stunnel_ver => {},
		xray_exe => "xray.exe",
		xray_ver => {},		
		self_exe => {}
    },

    runtime => {
        connected => 0,
        connecting => 0,
		connect_attempt_id => 0,
        pid => undef,
		stunnel_pid => undef,
		xray_pid => undef,
		ssh_pid => undef,
        status_text => '',
        log_lines => [],
		logbox_index => 0,
		log_follow => 1,
		openvpn_log_pos => 0,
		openvpn_log_path => '',
		pbar => 0,
		pbar_target => 0,
        pbar_animating => 0,
        pbar_seen => {},
		stop_world_spinner => 0,
		upgrade => 0,
		schedule_upgrade => 0,
		upgrade_installer_path => '',
		exit_btn_mode => 'exit' # exit | abort | disconnect
    },
	
	tray => {
	    hidden => 0,
		show_tip_once => 0
	},

    connect => {
        token => '',
        save_token => "on",
        server_display => '', # Same format as $server->{name}
        port => 443,
        proto => "UDP",
        timeout => 60,
        random_port => "off",
        tls_cipher => 'secp521r1',
        data_cipher => 'AES-256-GCM',
        adapter => {},
		tap_adapter_name => '',
		tap_adapter_guid => '',
		cryptostorm_tap_guid => '',
        bind_ip => "Any address",
		local_ipv4 => '',
		local_ipv6 => '',
		remote_ipv4 => '',
		remote_ipv6 => '',
        mssfix => 1400,
		manport => 0,
		manpass => "",
    },

    transport => {
        socks_enabled => "off",
        socks_ip => '127.0.0.1',
        socks_port => 9150,
        socks_noauth => "on",
        socks_user => '',
        socks_pass => '',
        ssh_enabled => "off",
		ssh_tunnel => {},
		ssh_hostkey => "",
		https_enabled => "off",
		https_mode => "stunnel",
        stunnel_enabled => "off",
		xray_enabled => "off",
        sni_host => 'www.yahoo.com',
		local_tunnel_port => 0,
		xray_snis_order => [
                    'cloudflare.com',
                    'download.windowsupdate.com',
                    'cstat.apple.com',
                    'www.speedtest.net',
                    'google.com',
        ],
		xray_snis => {
                    'cloudflare.com' => {
                        pubkey      => 'jVcTjg6A1chgD2MFD7wjLwMO6UIDCowW1QfbusF5khE',
                        short_id    => '8a12df734e',
                        fingerprint => 'chrome',
                    },
                    'download.windowsupdate.com' => {
                        pubkey      => 'iqJU65woLA5Ty0IyNytoRU2p8gO4bG9hf0aXpBqxwlQ',
                        short_id    => '221ead0789',
                        fingerprint => 'edge',
                    },
                    'cstat.apple.com' => {
                        pubkey      => 'SIrp99jJeHIx0E9KRIeFi7BSiLVGeEMR7k7yZUwHTU4',
                        short_id    => 'fc0c8c7d70',
                        fingerprint => 'safari',
                    },
                    'www.speedtest.net' => {
                        pubkey      => 'dGKC5dLdVoDkmYUfAE2dIjlOjS2hcWi9yF_E1TDHsnc',
                        short_id    => 'fe72e9f89a',
                        fingerprint => 'chrome',
                    },
                    'google.com' => {
                        pubkey      => 'Szip1HLPNdOl1g7k0gUjbdNFG4kO0f24lUXdJxxgOTY',
                        short_id    => '3cbf9bdab0',
                        fingerprint => 'edge',
                    },
        },
		xray_uuid => "b38321c5-ccdd-432c-9f68-6e931f7df16f"
	},

    security => {
        no_ipv6 => "off",
        dns_leak_protect => "on",
        killswitch_enabled => "off",
        adblock_enabled => "on",
		tunnelcrack_enabled => "off"
    },

    startup => {
        no_splash => "",
        autoconnect => "off",
        autorun => "off"
    },
};

$state->{app}->{self_exe} = Win32::AbsPath::Fix("$0");

my $ui = {
    mainwin => {
        mw => {},
		world_img => {},
		top_lbl => {},
        token_entry => {},
		token_combo => {},
		server_picker => {},
		save_token_check => {},
		lang_picker => {},
        connect_btn => {},
        options_btn => {},
		exit_btn => {}, # also disconnect/abort btn
        status_lbl => {},
		frame => {},
        logbox => {},
		scroll => {},
		pbar => {},
		pbar_frame => {}
    },
	opt_main => {
	    ow => {},
		frame => {},
	    world_img => {},
	    version_lbl => {},
		back_btn => {},
		tabs => {},
		tab_frame => {},
	},
	opt_startup => {
	    splash_check => {},
		splash_lbl => {},
		autocon_check => {},
		autocon_lbl => {},
		autostart_check => {},
		autostart_lbl => {},
		lang_combo => {},
		lang_lbl => {}
	},
	opt_connecting => {
	    port_lbl => {},
		port_entry => {},
		proto_lbl => {},
		proto_combo => {},
		timeout_lbl => {},
		timeout_combo => {},
		random_port_check => {}
	},
	opt_security => {
	    tls_cipher_lbl => {},
		tls_cipher_combo => {},
		data_cipher_lbl => {},
		data_cipher_combo => {},
		disable_ipv6_check => {},
		dnsleak_check => {},
		killswitch_check => {},
		ts_check => {},
		tunnelcrack_check => {},
	},
    opt_advanced => {
		top_lbl => {},
	    mssfix_lbl => {},
		mssfix_combo => {},
		bind_lbl => {},
		bind_combo => {},
		adapter_lbl => {},
		adapter_combo => {},
        socks_check => {},
        socks_ip_lbl => {},
        socks_ip_entry => {},
        socks_port_lbl => {},
        socks_port_entry => {},
        socks_user_lbl => {},
        socks_user_entry => {},
        socks_pass_lbl => {},
        socks_pass_entry => {},
        socks_noauth_check => {},
        ssh_check => {},
        https_check => {},
		stunnel_radio => {},
		xray_radio => {},
		xray_sni_combo => {},
        tunnel_lbl => {},
        ssh_tunnel_combo => {},
        sni_entry => {},
        reset_dns_to_dhcp_btn => {}
    },
};

# More reliable way to detect the Program Files folder
if (exists $ENV{'ProgramFiles(x86)'}) {
    $state->{app}->{bitness} = 64;
    $state->{app}->{program_files_dir} =
        "$ENV{'ProgramFiles(x86)'}\\Cryptostorm Client\\bin";
}
else {
    $state->{app}->{bitness} = 32;
    $state->{app}->{program_files_dir} =
        "$ENV{ProgramFiles}\\Cryptostorm Client\\bin";
}
chdir($state->{app}->{program_files_dir})
    or die "chdir failed: $!";

my $token_plain_regex = qr/[a-zA-Z0-9]{5}-[a-zA-Z0-9]{5}-[a-zA-Z0-9]{5}-[a-zA-Z0-9]{5}/;
my $token_hash_regex  = qr/[a-f0-9]{128}/;

$state->{runtime}->{signal_exit_requested} = 0;
$state->{runtime}->{signal_name} = '';

sub request_signal_exit {
    my ($sig) = @_;

    $state->{runtime}->{signal_exit_requested} = 1;
    $state->{runtime}->{signal_name} = $sig || '';
}

$SIG{TERM} = sub { request_signal_exit('TERM') };
$SIG{ABRT} = sub { request_signal_exit('ABRT') };
$SIG{INT}  = sub { request_signal_exit('INT')  };
$SIG{HUP}  = sub { request_signal_exit('HUP')  };

my $openvpn_log_poll_scheduled = 0;

my $json_text = read_file($state->{app}->{serversfile});
my $servers = decode_json($json_text);

my $tunnel_check_counter = 0;
my @recover;

restore_upgrade_files(state => $state);

sub language_override_from_argv {
    my ($argv) = @_;

    return undef unless $argv && ref($argv) eq 'ARRAY';

    for (my $i = 0; $i < @$argv; $i++) {
        my $arg = $argv->[$i];
        next unless defined $arg;

        if ($arg =~ m{^[/-]LANG=(.+)$}i) {
            return $1 if length $1;
        }

        if ($arg =~ m{^[/-]LANG$}i) {
            my $value = $argv->[$i + 1];
            return $value if defined $value && length $value && $value !~ m{^[/-]};
        }
    }

    return undef;
}

my $language_override = language_override_from_argv(\@ARGV);
my @config_argv = defined($language_override) ? ('/LANG', $language_override) : @ARGV;

load_config(
    state             => $state,
    json_file         => $state->{app}->{config_json_file},
    servers           => $servers,
    regkey            => $regkey,
    argv              => \@config_argv,
    token_plain_regex => $token_plain_regex,
    token_hash_regex  => $token_hash_regex,
);

# Set language via /LANG or default to English
if (defined($language_override)) {
 $state->{app}->{lang} = $language_override;
}
$state->{app}->{lang} ||= 'English';
# shortcut
my $lang = $state->{app}->{lang};

my $L = load_lang_compat('..\user\lang.txt');

$state->{app}->{prev_lang} = $state->{app}->{lang};

run_startup(
    state       => $state,
    ui          => $ui,
    L           => $L,
    lang        => $lang,
    version     => $VERSION,
    do_error    => \&do_error,
    do_exit     => \&do_exit,
    isoncs      => \&isoncs,
    hidewin     => \&hidewin,
    backtomain  => \&backtomain,
);

my %callbacks = (
    backtomain => \&backtomain,
    reset_dns_to_dhcp_btn_cmd => sub {
        reset_dns_to_dhcp_btn_cmd($state, $ui, $Registry, \@recover);
    },
    refresh_ui_from_state => \&refresh_ui_from_state,
    apply_language_to_ui  => \&apply_language_to_ui,
    is_xray_sni           => \&is_xray_sni,
    is_valid_ip           => \&is_valid_ip,
    do_error              => \&do_error,
    do_options            => sub { do_options() },
    do_exit               => sub { do_exit() },
    do_connect => sub {
        my $ok = do_connect(
            state      => $state,
            ui         => $ui,
            L          => $L,
            servers    => $servers,
            token_plain_regex => $token_plain_regex,
            token_hash_regex  => $token_hash_regex,
            update_selected_remote_endpoints => \&update_selected_remote_endpoints,
            refresh_ui_from_state            => \&refresh_ui_from_state,
            do_error                         => \&do_error,
            save_config                      => \&save_config,
            shutdown_openvpn                 => \&shutdown_openvpn,
            confgen                          => \&confgen,
            hidewin                          => \&hidewin,
            toggle_fw_rule                   => \&toggle_fw_rule,
            refresh_killswitch_rules_for_connect => \&refresh_killswitch_rules_for_connect,
            refresh_ipv6_block_rule_for_connect => \&refresh_ipv6_block_rule_for_connect,
            clear_ipv6_block_rule => \&clear_ipv6_block_rule,
            prepare_local_tunnel_start       => sub {
                my $needs_tunnel_cleanup =
                       (($state->{transport}->{ssh_enabled}     // 'off') eq 'on')
                    || (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
                    || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
                    || ($state->{transport}->{local_tunnel_port} // 0)
                    || ($state->{runtime}->{ssh_pid}     // 0)
                    || ($state->{runtime}->{stunnel_pid} // 0)
                    || ($state->{runtime}->{xray_pid}    // 0);

                return 1 unless $needs_tunnel_cleanup;
                reset_local_tunnel_helpers(reason => 'pre-connect', wait_ms => 900);
                return 1;
            },
            update_node_list                 => \&update_node_list,
			show_logbox                      => sub { show_logbox($state, $ui); },
			append_log_line                  => \&append_log_line,
			delete_logbox_text_line          => \&delete_logbox_text_line,
				start_world_icon_spinner         => \&start_world_icon_spinner,
                remove_ipv6_routes             => \&cleanup_ipv6_routes_for_vpn,
                cleanup_tap_ipv6_addresses     => \&cleanup_tap_ipv6_addresses,
				ensure_tap_adapter => sub {
    			return ensure_tap_adapter(
        			state     => $state,
        			L         => $L,
        			Registry  => $Registry,
        			name      => 'cryptostorm VPN',
        			ovpn_exe  => $state->{app}->{ovpn_exe},
        			on_status => sub {
            			my ($msg) = @_;
            			$state->{runtime}->{status_text} = $msg;
            			_ui_pump();
        			},
    			);
			},
			start_ssh_tunnel => sub {
    			return start_ssh_tunnel(
        			state                    => $state,
        			L                        => $L,
					servers                  => $servers,
        			get_next_free_local_port => \&get_next_free_local_port,
        			is_tunnel_up             => \&is_tunnel_up,
					is_tcp_accepting         => \&is_local_tcp_accepting,
        			do_error                 => \&do_error,
					ssh_exe                  => $state->{app}->{program_files_dir} . '\\cs-ssh-tun.exe'
    			);
			},
			start_management_success_watcher => sub {
    			return start_management_success_watcher(@_);
			},
			on_openvpn_connected => sub {
    			return mark_openvpn_connected(@_);
			},
        );
        start_openvpn_log_poller() if $ok;
    },
    TrackTrayMenu         => sub { TrackTrayMenu() },
    showwin               => sub { showwin() },
    hidewin               => sub { hidewin() },
	isoncs                => sub { isoncs() },
    killswitch_on         => sub { killswitch_on() },
    killswitch_off        => sub { killswitch_off() }
);

build_options_window(
    state     => $state,
    ui        => $ui,
    L         => $L,
    lang      => $lang,
    servers   => $servers,
    version   => $VERSION,
    callbacks => \%callbacks,
);

build_main_window(
    state             => $state,
    ui                => $ui,
    L                 => $L,
    lang              => $lang,
    servers           => $servers,
    version           => $VERSION,
    token_plain_regex => $token_plain_regex,
    token_hash_regex  => $token_hash_regex,
    callbacks         => \%callbacks,
);

init_tray(
    state     => $state,
    ui        => $ui,
    icon_path => '..\\res\\world1.ico',
    on_show   => \&showwin,
    on_hide   => \&hidewin,
    on_exit   => \&do_exit,
);

$state->{runtime}->{ui_ready} = 1;
refresh_ui_from_state($state, $ui);

if (($state->{startup}->{autoconnect} // 'off') eq 'on') {
    $ui->{mainwin}->{mw}->g_wm_deiconify();
    $ui->{mainwin}->{mw}->g_raise();
    $ui->{mainwin}->{mw}->g_focus();
    $callbacks{do_connect}->();
}

sub poll_signal_exit {
    if ($state->{runtime}->{signal_exit_requested}) {
        $state->{runtime}->{signal_exit_requested} = 0;

        if (defined $ui->{mainwin}->{mw}) {
            $ui->{mainwin}->{mw}->g_wm_attributes('-topmost', 1);
            $ui->{mainwin}->{mw}->g_wm_attributes('-topmost', 0);
            $ui->{mainwin}->{mw}->g_wm_deiconify();
            $ui->{mainwin}->{mw}->g_raise();
            $ui->{mainwin}->{mw}->g_focus();
        }

        my $answer = Tkx::tk___messageBox(
            -parent  => $ui->{mainwin}->{mw},
            -type    => "yesno",
            -message => $L->{$state->{app}->{lang}}{QUESTION_ANOTHERPROG1} . "\n" .
                        $L->{$state->{app}->{lang}}{QUESTION_ANOTHERPROG2} . "\n" .
                        $L->{$state->{app}->{lang}}{QUESTION_ANOTHERPROG3} . "\n",
            -icon    => "question",
            -title   => "cryptostorm.is client",
        );

        if ($answer eq "yes") {
            save_config(
                state     => $state,
                json_file => $state->{app}->{config_json_file},
            );

            do_exit();
            return;
        }
    }

    Tkx::after(250, \&poll_signal_exit);
}

Tkx::after(250, \&poll_signal_exit);

Tkx::MainLoop();
exit;

sub apply_language_to_ui {
    my ($ui, $state, $L) = @_;

    my $lang = $state->{app}->{lang} || 'English';

    # fallback if missing
    if (!defined $L->{$lang}{ERR_AUTH_FAIL}) {
        $lang = 'English';
        $state->{app}->{lang} = 'English';
    }
	
	# old language/default before switching text
    my $old_lang = $state->{app}->{prev_lang} || 'English';
    my $old_default = $L->{$old_lang}{TXT_DEFAULT_SERVER} // 'Global random';
    my $new_default = $L->{$lang}{TXT_DEFAULT_SERVER}     // 'Global random';
	
    # widget refs
	eval {

        # only replace the visible selected server text if it was the old default
        if (
            defined $state->{connect}->{server_display}
            && $state->{connect}->{server_display} eq $old_default
        ) {
            $state->{connect}->{server_display} = $new_default;
        }		
		
		$ui->{mainwin}->{server_picker}->set_default_text($new_default);
		
        $ui->{mainwin}->{connect_btn}->configure(-text => "\n" . $L->{$lang}{TXT_CONNECT} . "\n");

        my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';
        sync_exit_button($state, $ui, $L);

        if ($mode eq 'disconnect') {
            $state->{runtime}->{status_text} = $L->{$lang}{TXT_CONNECTED};
        }
        elsif ($mode eq 'abort') {
            # Connecting in progress. Do NOT add/replace an Abort log line here.
            $state->{runtime}->{status_text} = $L->{$lang}{TXT_CONNECTING} . "...";
        }
        elsif ($mode eq 'aborting') {
            $state->{runtime}->{status_text} = $L->{$lang}{TXT_DISCONNECTING};
        }
        elsif ($mode eq 'disconnecting') {
            $state->{runtime}->{status_text} = $L->{$lang}{TXT_DISCONNECTING};
        }
        else {
            # exit mode can be idle, disconnected, or aborted. Keep this simple for the status bar.
            $state->{runtime}->{status_text} =
                ($state->{runtime}->{last_log_status} // '') eq 'disconnected'
                    ? $L->{$lang}{TXT_DISCONNECTED}
                    : $L->{$lang}{TXT_NOT_CONNECTED};
        }

        replace_logbox_status_line('status_connected',    $L->{$lang}{TXT_CONNECTED},    'goodline');
        replace_logbox_status_line('status_disconnected', $L->{$lang}{TXT_DISCONNECTED}, 'badline');
		replace_logbox_status_line('status_disconnecting', $L->{$lang}{TXT_DISCONNECTING}, 'badline');
        replace_logbox_status_line('status_abort',        $L->{$lang}{TXT_ABORT},        'badline');
        replace_logbox_status_line('status_suspending',   $L->{$lang}{TXT_SUSPENDING},   'warnline');

        $ui->{mainwin}->{options_btn}->configure(-text => $L->{$lang}{TXT_OPTIONS});
		
		$ui->{mainwin}->{save_token_check}->configure(-text => $L->{$lang}{TXT_SAVE});
		
		$ui->{mainwin}->{top_lbl}->configure(-state => 'normal');
        $ui->{mainwin}->{top_lbl}->delete('1.0', 'end');
        $ui->{mainwin}->{top_lbl}->tag(qw/configure link1 -foreground blue -underline 1/);
        $ui->{mainwin}->{top_lbl}->tag(qw/configure link3 -foreground blue -underline 1/);
        $ui->{mainwin}->{top_lbl}->insert('1.0',
            "\n" . $L->{$lang}{TXT_MAINWINDOW1} . "\n" . $L->{$lang}{TXT_MAINWINDOW2} . " "
        );
        $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_HERE}, 'link1');
        $ui->{mainwin}->{top_lbl}->insert('insert', "\n \n");
        $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_MAINWINDOW5} . " ");
        $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_HERE}, 'link3');
        $ui->{mainwin}->{top_lbl}->insert('insert', ".\n");
        $ui->{mainwin}->{top_lbl}->configure(-state => 'disabled');
		
		$ui->{mainwin}->{status_lbl}->configure(-textvariable => \$state->{runtime}->{status_text});
		
		Tkx::wm_title($ui->{opt_main}->{ow}, $L->{$lang}{TXT_OPTIONS});
		$ui->{opt_main}->{back_btn}->configure(-text => $L->{$lang}{TXT_BACK});
		
        $ui->{opt_main}->{tabs}->tab(
            $ui->{opt_main}->{tab_frame}->{1},
            -text => $L->{$lang}{TXT_STARTUP}
        );
        $ui->{opt_main}->{tabs}->tab(
            $ui->{opt_main}->{tab_frame}->{2},
            -text => $L->{$lang}{TXT_CONNECTING}
        );
        $ui->{opt_main}->{tabs}->tab(
            $ui->{opt_main}->{tab_frame}->{3},
            -text => $L->{$lang}{TXT_SECURITY}
        );
        $ui->{opt_main}->{tabs}->tab(
            $ui->{opt_main}->{tab_frame}->{4},
            -text => $L->{$lang}{TXT_ADVANCED}
        );
		
		$ui->{opt_startup}->{splash_check}->configure(-text => $L->{$lang}{TXT_NO_SPLASH});
        $ui->{opt_startup}->{autocon_check}->configure(-text => $L->{$lang}{TXT_AUTO_CONNECT});
        $ui->{opt_startup}->{autorun_check}->configure(-text => $L->{$lang}{TXT_AUTO_START});
		
		$ui->{opt_connecting}->{port_lbl}->configure(-text => $L->{$lang}{TXT_CONNECT_PORT});
		$ui->{opt_connecting}->{proto_lbl}->configure(-text => $L->{$lang}{TXT_CONNECT_PROTOCOL});
		$ui->{opt_connecting}->{timeout_lbl}->configure(-text => $L->{$lang}{TXT_TIMEOUT});
        $ui->{opt_connecting}->{random_port_check}->configure(-text => $L->{$lang}{TXT_RANDOM_PORT});
		
		$ui->{opt_security}->{disable_ipv6_check}->configure(-text => $L->{$lang}{TXT_DISABLE_IPV6});
        $ui->{opt_security}->{dnsleak_check}->configure(-text => $L->{$lang}{TXT_DNS_LEAK});
        $ui->{opt_security}->{killswitch_check}->configure(-text => $L->{$lang}{TXT_KILLSWITCH_ENABLE});
        $ui->{opt_security}->{ts_check}->configure(-text => $L->{$lang}{TXT_ENABLE_ADBLOCK});
        $ui->{opt_security}->{tunnelcrack_check}->configure(-text => $L->{$lang}{TXT_ENABLE_TUNNELCRACK});

		$ui->{opt_advanced}->{top_lbl}->configure(-text => $L->{$lang}{TXT_ADVANCED_OPTIONS} . "\n");

	};
	warn $@ if $@;
    
	$state->{app}->{prev_lang} = $lang;    
	Tkx::update("idletasks");
}

sub hidewin {
    return hide_to_tray(
        state   => $state,
        ui      => $ui,
        on_show => \&showwin,
        on_hide => \&hidewin,
        on_exit => \&do_exit,
    );
}

sub showwin {
    return show_from_tray(
        state   => $state,
        ui      => $ui,
        on_show => \&showwin,
        on_hide => \&hidewin,
        on_exit => \&do_exit,
    );
}

sub TrackTrayMenu {
    return track_tray_menu();
}

sub remove_ipv6_routes {
    my (%args) = @_;

    # Clear IPv6 routes OpenVPN may leave behind after IPv6/transport edge cases.
    # These are VPN-pushed split/default ranges, not the normal host ::/0 route.
    my @cmds = (
        'route delete 128.0.0.0 MASK 128.0.0.0',
        'route delete 2000::/3',
        'route delete ::/3',
        'route delete 2000::/4',
        'route delete 3000::/4',
        'route delete fc00::/7',
    );

    my $cmd = 'cmd.exe /d /c "' . join(' & ', map { $_ . ' >NUL 2>NUL' } @cmds) . '"';

    return system($cmd) if $args{wait};
    return system(1, $cmd);
}

sub cleanup_ipv6_routes_for_vpn {
    my (%args) = @_;

    remove_ipv6_routes(%args);

    if (($state->{connect}->{remote_ipv6} // '') =~ /^[0-9a-f:]+$/i) {
        my $cmd = 'cmd.exe /d /c "route delete '
                . $state->{connect}->{remote_ipv6}
                . '/128 >NUL 2>NUL"';

        return system($cmd) if $args{wait};
        return system(1, $cmd);
    }
}

sub cleanup_tap_ipv6_addresses {
    my (%args) = @_;

    my $ifname = $state->{connect}->{tap_adapter_name} // '';
    $ifname =~ s/^\s+|\s+$//g;
    $ifname =~ s/"//g;

    return 0 unless length $ifname;

    my @lines = `netsh interface ipv6 show addresses interface="$ifname" 2>NUL`;
    my %seen;
    my @addrs;

    for my $line (@lines) {
        while ($line =~ /(fd00:10:60:[0-9a-f:]+)/ig) {
            my $addr = lc $1;
            $addr =~ s/[,\s].*\z//;
            next if $seen{$addr}++;
            push @addrs, $addr;
        }
    }

    for my $addr (@addrs) {
        my $cmd = 'netsh interface ipv6 delete address interface="'
                . $ifname
                . '" address='
                . $addr
                . ' store=active >NUL 2>NUL';

        system($cmd);
    }

    return @addrs ? 1 : 0;
}

sub start_world_icon_spinner {
    my ($state, $ui) = @_;

    $state->{runtime}->{world_spinner_active} = 1;
    my $seq = ++$state->{runtime}->{world_spinner_seq};

    my $tick;
    $tick = sub {
        return unless $state->{runtime}->{world_spinner_active};
        return unless (($state->{runtime}->{world_spinner_seq} // 0) == $seq);
        return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'abort');

        # existing image-frame update here

        Tkx::after(150, $tick);
    };

    Tkx::after(150, $tick);
}

sub _world_icon_spinner_tick {
    my ($state, $ui) = @_;

    return unless $state->{runtime}->{world_spinner_active};
    return unless $ui->{mainwin}->{world_img};

    my $frame = $state->{runtime}->{world_spinner_frame} || 1;

    $ui->{mainwin}->{world_img}->configure(-image => "b$frame");

    $frame++;
    $frame = 1 if $frame > 6;
    $state->{runtime}->{world_spinner_frame} = $frame;

    Tkx::after(80, sub {
        _world_icon_spinner_tick($state, $ui);
    });
}

sub stop_world_icon_spinner {
    my ($state, $ui) = @_;

    $state->{runtime}->{world_spinner_active} = 0;
    ++$state->{runtime}->{world_spinner_seq};

    eval {
        $ui->{mainwin}->{world_img}->configure(-image => "mainicon");
        1;
    };

    _ui_pump();
}

sub sync_exit_button {
    my ($state, $ui, $L) = @_;
    my $lang = $state->{app}->{lang} || 'English';

    my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';

    if ($mode eq 'abort') {
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_ABORT},
            -state => 'normal',
        );
    }
    elsif ($mode eq 'preparing') {
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_ABORT},
            -state => 'disabled',
        );
    }
    elsif ($mode eq 'aborting' || $mode eq 'disconnecting') {
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_ABORT},
            -state => 'disabled',
        );
    }
    elsif ($mode eq 'disconnect') {
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_DISCONNECT},
            -state => 'normal',
        );
    }
    else {
        $state->{runtime}->{exit_btn_mode} = 'exit';
        $ui->{mainwin}->{exit_btn}->configure(
            -text  => $L->{$lang}{TXT_EXIT},
            -state => 'normal',
        );
    }
}

sub do_exit {
    my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';

    if ($mode eq 'abort') {
        return do_abort_connect();
    }

    if ($mode eq 'disconnect') {
        return do_disconnect();
    }

    return do_app_exit();
}

sub do_abort_connect {
    my $lang = $state->{app}->{lang} || 'English';

    $state->{runtime}->{connect_attempt_id} = ($state->{runtime}->{connect_attempt_id} // 0) + 1;
    $state->{runtime}->{status_text}   = $L->{$lang}{TXT_DISCONNECTING};
    $state->{runtime}->{exit_btn_mode} = 'aborting';
    $state->{runtime}->{stop}          = 1;
    $state->{runtime}->{pbar}          = 0;
	stop_world_icon_spinner($state, $ui, 'mainicon');

    @{ $state->{runtime}->{log_lines} } = ();

    $ui->{mainwin}->{exit_btn}->configure(-state => 'disabled');
    $ui->{mainwin}->{connect_btn}->configure(-state => 'disabled');
    $ui->{mainwin}->{options_btn}->configure(-state => 'disabled');

    _ui_pump();

    Tkx::after(10, sub {
        _do_abort_connect_work();
    });

    return 1;
}

sub _do_abort_connect_work {
    my $lang = $state->{app}->{lang} || 'English';

    $state->{runtime}->{stop} = 1;
    $state->{runtime}->{pbar} = 0;

    shutdown_openvpn_fast();
    cleanup_ipv6_routes_for_vpn();
    cleanup_tap_ipv6_addresses();
    clear_ipv6_block_rule('abort');

    _run_taskkill_wait("taskkill /IM cs-ssh-tun.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{ssh_enabled} // 'off') eq 'on');

    _run_taskkill_wait("taskkill /IM cs-https-tun.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{stunnel_enabled} // 'off') eq 'on');

    _run_taskkill_wait("taskkill /IM xray.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{xray_enabled} // 'off') eq 'on');

    clear_local_tunnel_runtime(1500);

    _stop_openvpn_tail_thread();

    @{ $state->{runtime}->{log_lines} } = ();

    $ui->{mainwin}->{world_img}->configure(-image => "mainicon");

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_NOT_CONNECTED};
    $state->{runtime}->{pbar}        = 0;

    Tkx::after(200, sub {
        _finish_abort_ui();
    });
}

sub _finish_abort_ui {
    my $lang = $state->{app}->{lang} || 'English';

    @{ $state->{runtime}->{log_lines} } = ();

    delete_logbox_status_lines();

    $state->{runtime}->{log_follow} = 1;

    append_log_status_line(
        $ui,
        $L->{$lang}{TXT_ABORT},
        "badline",
        "status_abort",
    );

    $state->{runtime}->{last_log_status} = 'abort';

    $state->{runtime}->{exit_btn_mode} = 'exit';
    $state->{runtime}->{status_text}   = $L->{$lang}{TXT_NOT_CONNECTED};
    $state->{runtime}->{pbar} = 0;
    $state->{runtime}->{pbar_target} = 0;
    $state->{runtime}->{pbar_animating} = 0;
    $state->{runtime}->{pbar_seen} = {};

    $ui->{mainwin}->{exit_btn}->configure(
        -text  => $L->{$lang}{TXT_EXIT},
        -state => 'normal',
    );

    $ui->{mainwin}->{connect_btn}->configure(-state => 'normal');
    $ui->{mainwin}->{options_btn}->configure(-state => 'normal');
    $ui->{mainwin}->{server_picker}->configure(-state => 'readonly');

    _ui_pump();
}

sub delete_logbox_text_line {
    my ($text) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;
    return unless defined $text && length $text;

    my $pattern = '^' . quotemeta($text) . '$';

    eval {
        $logbox->configure(-state => 'normal');

        while (1) {
            my $idx = $logbox->search(-regexp, $pattern, '1.0', 'end');
            last unless defined($idx) && $idx =~ /^\d+\.\d+$/;

            $logbox->delete("$idx linestart", "$idx lineend +1c");
        }

        $logbox->configure(-state => 'disabled');
        1;
    } or do {
        warn "delete_logbox_text_line failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub shutdown_openvpn_fast {

    my $manport = $state->{connect}->{manport};
    my $manpass = $state->{connect}->{manpass};

    if ($manport && $manpass) {
        eval {
            my $sock = IO::Socket::INET->new(
                PeerHost => '127.0.0.1',
                PeerPort => $manport,
                Proto    => 'tcp',
                Timeout  => 0.25,
            );

            if ($sock) {
                $sock->autoflush(1);
                print $sock "$manpass\r\n";
                print $sock "signal SIGTERM\r\n";
                print $sock "exit\r\n";
                close $sock;
            }

            1;
        };
    }

    _run_taskkill_wait("TASKKILL /F /T /IM $state->{app}->{ovpn_exe} >NUL 2>NUL", timeout => 6);
}

sub _stop_openvpn_tail_thread {
    $state->{runtime}->{stop} = 1;
    delete $state->{runtime}->{openvpn_log_path};
    delete $state->{runtime}->{openvpn_log_pos};
}

sub do_disconnect {
    my $lang = $state->{app}->{lang} || 'English';

    my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';

    my $should_prompt =
           ($mode eq 'disconnect')
        || (isoncs() > 0);

    if ($should_prompt) {
        my $answer = Tkx::tk___messageBox(
            -parent  => $ui->{mainwin}->{mw},
            -type    => "yesno",
            -message => $L->{$lang}{QUESTION_DISCONNECT1} . "\n" .
                        $L->{$lang}{QUESTION_DISCONNECT2} . "\n" .
                        $L->{$lang}{QUESTION_DISCONNECT3},
            -icon    => "question",
            -title   => "cryptostorm.is client",
        );

        return 0 if $answer ne "yes";
    }

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_DISCONNECTING};
    $state->{runtime}->{exit_btn_mode} = 'disconnecting';
    $state->{runtime}->{stop} = 1;
	stop_world_icon_spinner($state, $ui, 'mainicon');

    @{ $state->{runtime}->{log_lines} } = ();

    $ui->{mainwin}->{exit_btn}->configure(-state => 'disabled');
    $ui->{mainwin}->{connect_btn}->configure(-state => 'disabled');
    $ui->{mainwin}->{options_btn}->configure(-state => 'disabled');

    delete_logbox_status_lines();

    $state->{runtime}->{log_follow} = 1;

    append_log_status_line(
        $ui,
        $L->{$lang}{TXT_DISCONNECTING},
        "badline",
        "status_disconnecting",
    );

    $state->{runtime}->{last_log_status} = 'disconnected';

    _ui_pump();

    my @steps;

    push @steps, {
	    code => sub {
            cleanup_ipv6_routes_for_vpn();
	        }
	    };

    push @steps, {
	    code => sub {
            if (($state->{security}->{killswitch_enabled} // 'off') eq 'on') {
                my $had_localip6 = $state->{runtime}->{localip6} // '';

                $state->{runtime}->{localip}  = "";
                $state->{runtime}->{localip6} = "";

                toggle_fw_rule("cryptostorm - Allow internal VPN DNS", "no");
                toggle_fw_rule("cryptostorm - Allow internal IPv4 in", "no");
                toggle_fw_rule("cryptostorm - Allow internal IPv4 out", "no");
                toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway in", "no");
                toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "no");

                if (($state->{security}->{no_ipv6} // 'off') eq 'off' && length $had_localip6) {
                    toggle_fw_rule("cryptostorm - Allow internal IPv6 in", "no");
                    toggle_fw_rule("cryptostorm - Allow internal IPv6 out", "no");
                    toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway in", "no");
                    toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "no");
                }
			}
        }
    };

    push @steps, {
        code => sub {
            save_config(
                state     => $state,
                json_file => $state->{app}->{config_json_file},
            );
        },
    };

    push @steps, {
        async => 1,
        code  => sub {
            my ($next) = @_;

            shutdown_openvpn_graceful_async(
                state    => $state,
                grace_ms => (($state->{connect}->{proto} // 'UDP') =~ /^UDP$/i) ? 9000 : 4500,
                on_done  => $next,
            );
        },
    };

    push @steps, {
        code => sub {
            cleanup_ipv6_routes_for_vpn();
            cleanup_tap_ipv6_addresses();
            clear_ipv6_block_rule('disconnect');
        }
    };

    push @steps, {
	    code => sub {
            _run_taskkill_wait("taskkill /IM cs-ssh-tun.exe /F >NUL 2>NUL", timeout => 5)
                if (($state->{transport}->{ssh_enabled} // 'off') eq 'on');

            _run_taskkill_wait("taskkill /IM cs-https-tun.exe /F >NUL 2>NUL", timeout => 5)
                if (($state->{transport}->{stunnel_enabled} // 'off') eq 'on');

            _run_taskkill_wait("taskkill /IM xray.exe /F >NUL 2>NUL", timeout => 5)
                if (($state->{transport}->{xray_enabled} // 'off') eq 'on');

            clear_local_tunnel_runtime(1500);

            unlink "..\\user\\socks.dat" if -e "..\\user\\socks.dat";
		}
    };

    push @steps, {
	    code  => sub {
            if (($state->{security}->{killswitch_enabled} // 'off') eq 'on') {
                system(1, "ipconfig /renew >NUL 2>NUL");
            }
		}
    };

    push @steps, {
	    code  => sub {
            _stop_openvpn_tail_thread();
		}
    };

    _run_disconnect_steps(\@steps);

    return 1;
}

sub _run_disconnect_steps {
    my ($steps) = @_;

    my $i = 0;

    my $run_next;
    $run_next = sub {
        if ($i >= @$steps) {
            _finish_disconnect_ui();
            return;
        }

        my $step = $steps->[$i++];
        my $code = ref($step) eq 'HASH' ? $step->{code} : $step;
        my $async = ref($step) eq 'HASH' && $step->{async};

        eval {
            if ($async) {
                $code->($run_next);
            }
            else {
                $code->();
                Tkx::after(10, $run_next);
            }

            1;
        } or do {
            my $err = $@ || 'unknown disconnect error';
            append_log_line($ui, $err, "badline");
            Tkx::after(10, $run_next);
        };
    };

    Tkx::after(10, $run_next);
}

sub _sub_wants_callback {
    my ($sub) = @_;
    return 0 unless ref($sub) eq 'CODE';
    # mark async steps yourself instead of introspecting
    return 0;
}

sub _finish_disconnect_ui {
    my $lang = $state->{app}->{lang} || 'English';

    $ui->{mainwin}->{world_img}->configure(-image => "mainicon");

    $state->{runtime}->{exit_btn_mode}  = 'exit';
    $state->{runtime}->{status_text}    = $L->{$lang}{TXT_DISCONNECTED};
    $state->{runtime}->{pbar}           = 0;
    $state->{runtime}->{pbar_target}    = 0;
    $state->{runtime}->{pbar_animating} = 0;
    $state->{runtime}->{pbar_seen}      = {};
    $state->{tray}->{show_tip_once}     = 0;

	delete_logbox_status_lines();

    append_log_status_line(
        $ui,
        $L->{$lang}{TXT_DISCONNECTED},
        "badline",
        "status_disconnected",
    );
	
    $ui->{mainwin}->{exit_btn}->configure(
        -text  => $L->{$lang}{TXT_EXIT},
        -state => "normal",
    );

    $ui->{mainwin}->{options_btn}->configure(-state => "normal");
    $ui->{mainwin}->{connect_btn}->configure(-state => "normal");

    if ($ui->{mainwin}->{server_picker}->can('configure')) {
        $ui->{mainwin}->{server_picker}->configure(-state => "readonly");
    }

    _ui_pump();
}

sub do_app_exit {
    my $lang = $state->{app}->{lang} || 'English';

    $ui->{mainwin}->{mw}->g_wm_deiconify();
    $ui->{mainwin}->{mw}->g_raise();
    $ui->{mainwin}->{mw}->g_focus();

    $ui->{mainwin}->{exit_btn}->configure(-state => "disabled");
    $state->{runtime}->{status_text} = $L->{$lang}{TXT_EXITING};
	Tkx::update();

    remove_tray();

    save_config(state => $state, json_file => $state->{app}->{config_json_file});

    _run_taskkill_wait("taskkill /IM cs-ssh-tun.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{ssh_enabled} // 'off') eq "on");

    _run_taskkill_wait("taskkill /IM cs-https-tun.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{stunnel_enabled} // 'off') eq "on");

    _run_taskkill_wait("taskkill /IM xray.exe /F >NUL 2>NUL", timeout => 5)
        if (($state->{transport}->{xray_enabled} // 'off') eq "on");

    clear_local_tunnel_runtime(1500);

    unlink "..\\bin\\openvpn.log"      if -e "..\\bin\\openvpn.log";
    unlink "..\\user\\manpass.txt"     if -e "..\\user\\manpass.txt";
    unlink "..\\user\\socks.dat"       if -e "..\\user\\socks.dat";
    unlink "..\\user\\mydns.txt"       if -e "..\\user\\mydns.txt";
    unlink "..\\user\\vpn.ovpn"        if -e "..\\user\\vpn.ovpn";
    unlink "..\\user\\stunnel.conf"    if -e "..\\user\\stunnel.conf";
    unlink "..\\user\\xray-config.json" if -e "..\\user\\xray-config.json";

    if ((-e "..\\user\\all.wfw") || (($state->{security}->{killswitch_enabled} // 'off') eq "on")) {
        my $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow CS programs" 2>&1`;
        $rt = '' unless defined $rt;

        if ($rt =~ /cryptostorm/) {
            my $answer = Tkx::tk___messageBox(
                -parent  => $ui->{mainwin}->{mw},
                -type    => "yesno",
                -message => $L->{$lang}{QUESTION_KILLSWITCH1} . "\n" .
                            $L->{$lang}{QUESTION_KILLSWITCH2},
                -icon    => "question",
                -title   => "cryptostorm.is client",
            );

            if ($answer eq "yes") {
                killswitch_off();
                $state->{security}->{killswitch_enabled} = "off";
                save_config(state => $state, json_file => $state->{app}->{config_json_file});
            }
        }
    }

    shutdown_openvpn_fast();
    _stop_openvpn_tail_thread();

    system(1, "ipconfig /registerdns >NUL 2>NUL");

    if (($state->{security}->{killswitch_enabled} // 'off') eq "on") {
        system(1, "ipconfig /renew >NUL 2>NUL");
    }

    cleanup_ipv6_routes_for_vpn();
    cleanup_tap_ipv6_addresses();
    clear_ipv6_block_rule('app-exit') if (($state->{security}->{killswitch_enabled} // 'off') eq 'off');

    # If an update is scheduled, start only a detached waiter here.  Do not
    # start Inno Setup directly: at this point the Tk window can be destroyed
    # while this Perl/PAR process is still alive and still releasing files.
    # The waiter has no inherited handles, waits for our PID to disappear,
    # gives Windows a short extra grace period, and only then starts the
    # verified installer copy from %TEMP%.
    if ($state->{runtime}->{schedule_upgrade}) {
        my $installer = $state->{runtime}->{upgrade_installer_path} || '';

        if (!$installer || !-e $installer || !_launch_upgrade_installer_after_exit($installer)) {
            my $root_installer = '..\cryptostorm_setup.exe';
            do_error(
                "Could not schedule the Cryptostorm installer to start after the client exits.\n\n" .
                (-e $root_installer
                    ? "Please run $root_installer manually."
                    : "Please download and run cryptostorm_setup.exe manually.")
            );
        }
    }

    eval { $ui->{mainwin}->{mw}->g_destroy() };

    Tkx::exit(0);
    CORE::exit(0);
}

sub shutdown_openvpn {
 my $tried_mgmt = 0;

 if ($state->{connect}->{manport} && $state->{connect}->{manpass}) {
  $tried_mgmt = 1;
  my $sock = IO::Socket::INET->new(PeerHost => '127.0.0.1',
                                   PeerPort => $state->{connect}->{manport},
                                   Proto    => 'tcp',
                                   Timeout  => 1);
  if ($sock) {
   print $sock "$state->{connect}->{manpass}\r\n";
   my $authorized = 0;
   eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm(1);
    while (my $line = <$sock>) {
     if ($line =~ /INFO:OpenVPN Management Interface Version/) {
      $authorized = 1;
      last;
     }
    }
    alarm(0);
    1;
   };
   alarm(0);

   if ($authorized) {
    print $sock "signal SIGTERM\r\n";
    eval {
     local $SIG{ALRM} = sub { die "timeout\n" };
     alarm(1);
     while (my $line = <$sock>) {
      last if $line =~ /SUCCESS: signal SIGTERM thrown/;
     }
     alarm(0);
     1;
    };
    alarm(0);
    print $sock "exit\r\n";
   }
   close($sock);
  }
 }

 # Always do a hidden taskkill fallback.  The old version returned early when
 # the management port/pass were missing, which could leave a prior OpenVPN
 # process alive and make the next attempt appear to hang with no log output.
 _run_taskkill_wait("TASKKILL /F /T /IM $state->{app}->{ovpn_exe} >NUL 2>NUL", timeout => 6);
}

sub update_node_list {
    my $base_url        = 'http://10.31.33.7';
    my $json_url        = "$base_url/latest_list.json";
    my $hash_url        = "$base_url/list_hash.txt";

    my $local_json_file = $state->{app}->{serversfile};
    my $local_hash_file = '..\user\list_hash.txt';

    my $update_err;
    my $http = HTTP::Tiny->new(
        timeout => 7,
    );

    # Step 1: fetch remote hash file
    my $hash_res = $http->get($hash_url);
    unless ($hash_res->{success}) {
        $update_err = "ERROR: Couldn't download $hash_url: $hash_res->{status} $hash_res->{reason}";
        return;
    }

    my $remote_hash_line = $hash_res->{content};
    $remote_hash_line =~ s/\r?\n\z//;

    # list_hash.txt format:
    # <sha512hash> ver=whatever
    my ($remote_hash) = split /\s+/, $remote_hash_line, 2;

    unless ($remote_hash && $remote_hash =~ /\A[a-fA-F0-9]{128}\z/) {
        $update_err = "ERROR: Invalid hash format in $hash_url";
        return;
    }

    # Step 2: calculate local JSON hash, if local file exists
    my $local_hash = '';
    if (-e $local_json_file) {
        eval {
            my $local_json = read_file($local_json_file, binmode => ':raw');
            $local_hash = sha512_hex($local_json);
        };
        if ($@) {
            $update_err = "ERROR: Couldn't read/hash local JSON file $local_json_file: $@";
            return;
        }
    }

    # Step 3: if hashes match, no need to download latest_list.json
    if ($local_hash && lc($local_hash) eq lc($remote_hash)) {
        read_file($local_json_file, binmode => ':raw');
        return 1;
    }

    # Step 4: download latest_list.json because hash differs
    my $json_res = $http->get($json_url);
    unless ($json_res->{success}) {
        $update_err = "ERROR: Couldn't download $json_url: $json_res->{status} $json_res->{reason}";
        return;
    }

    my $json_body = $json_res->{content};

    # Step 5: verify downloaded file matches advertised hash
    my $downloaded_hash = sha512_hex($json_body);
    unless (lc($downloaded_hash) eq lc($remote_hash)) {
        $update_err = "ERROR: Downloaded latest_list.json hash mismatch";
        return;
    }

    # Optional sanity check: valid JSON
    eval {
        decode_json($json_body);
    };
    if ($@) {
        $update_err = "ERROR: Downloaded latest_list.json is not valid JSON: $@";
        return;
    }

    # Step 6: save local copies
    eval {
        write_file($local_json_file, { binmode => ':raw' }, $json_body);
        write_file($local_hash_file, { binmode => ':raw' }, $remote_hash_line . "\n");
    };
    if ($@) {
        $update_err = "ERROR: Couldn't write updated files: $@";
        return;
    }

    return 1;
}

sub autosize_options_window {
    return unless $ui
        && $ui->{opt_main}
        && $ui->{opt_main}->{ow}
        && $ui->{opt_main}->{tabs};

    my $tabs = $ui->{opt_main}->{tabs};
    return unless widget_exists($tabs);

    my $min_tab_w = 465;
    my $min_tab_h = 230;
    my $tab_w     = $min_tab_w;
    my $tab_h     = $min_tab_h;

    eval { Tkx::update('idletasks'); 1 };

    # Size the notebook from the largest tab frame instead of the old fixed
    # 465x230 value.  The fixed value could clip the right-most controls in the
    # Advanced tab, especially the stunnel/Xray SNI controls, on small Windows
    # displays where Tk's requested size math differs slightly.
    for my $idx (1 .. 4) {
        my $frame = $ui->{opt_main}->{tab_frame}->{$idx};
        next unless widget_exists($frame);

        my $rw = eval { Tkx::winfo('reqwidth',  $frame) } || 0;
        my $rh = eval { Tkx::winfo('reqheight', $frame) } || 0;

        $tab_w = $rw if $rw > $tab_w;
        $tab_h = $rh if $rh > $tab_h;
    }

    # Leave room for ttk::notebook padding/borders and the tab strip itself.
    $tab_w += 44;
    $tab_h += 56;

    eval {
        $tabs->configure(-width => $tab_w, -height => $tab_h);
        Tkx::update('idletasks');
        1;
    };

    return 1;
}

sub do_options {
 if ($state->{connect}->{save_token} eq "off") {
  $state->{startup}->{autoconnect} = "off";
 }
 $ui->{mainwin}->{mw}->g_wm_deiconify();
 $ui->{mainwin}->{mw}->g_wm_withdraw();
 # The Advanced tab is wider than the old hard-coded notebook size on some
 # small/low-DPI Windows 7 systems.  Recalculate from the actual requested
 # widget sizes every time Options is opened so stunnel/Xray controls are not
 # clipped by the notebook/window geometry.
 autosize_options_window();
 Tkx::update('idletasks');

 my $width  = Tkx::winfo('reqwidth',  $ui->{opt_main}->{ow});
 my $height = Tkx::winfo('reqheight', $ui->{opt_main}->{ow});
 my $screen_w = Tkx::winfo('screenwidth',  $ui->{opt_main}->{ow});
 my $screen_h = Tkx::winfo('screenheight', $ui->{opt_main}->{ow});
 my $x = int(($screen_w - $width) / 2);
 my $y = int(($screen_h - $height) / 2);
 $x = 0 if $x < 0;
 $y = 0 if $y < 0;
 $ui->{opt_main}->{ow}->g_wm_geometry($width . "x" . $height . "+" . $x . "+" . $y);
 $ui->{opt_main}->{ow}->g_raise();
 $ui->{opt_main}->{ow}->g_wm_deiconify();
 $ui->{opt_main}->{ow}->g_focus();
}

sub backtomain {
    my $lang = $state->{app}->{lang} || 'English';

    return unless _validate_options_before_back($state, $L, $lang);

    _hide_options_show_main($ui);

    _apply_autorun_setting($state, $Registry);

    _normalize_options_after_back($state, $ui, $L, $lang);

    # Options changes can switch SSH/stunnel/Xray modes while a previous helper
    # process is still tearing down.  Clear local helper runtime here while the
    # client is disconnected, so the next Connect starts from a clean state.
    if (($state->{runtime}->{exit_btn_mode} // 'exit') eq 'exit') {
        reset_local_tunnel_helpers(reason => 'options', wait_ms => 1000);
    }

    save_config(
        state     => $state,
        json_file => $state->{app}->{config_json_file},
    );

    # The standalone IPv6 leak block is a connected-state guard for IPv4-only
    # connection paths when the full killswitch is off. Do not keep it active
    # while disconnected just because Disable IPv6 is selected in Options.
    if (($state->{runtime}->{exit_btn_mode} // 'exit') eq 'exit'
        && (($state->{security}->{killswitch_enabled} // 'off') eq 'off')) {
        clear_ipv6_block_rule('options-disconnected');
    }


    _apply_killswitch_after_options($state, $ui, $L, $lang);

    refresh_ui_from_state($state, $ui);

    _ui_pump();
}

sub _validate_options_before_back {
    my ($state, $L, $lang) = @_;

    if (($state->{transport}->{socks_enabled} // 'off') eq 'on') {
        my $port = $state->{transport}->{socks_port};

        if (!defined($port) || $port !~ /^([0-9]+)$/ || $1 < 1 || $1 > 65535) {
            do_error($L->{$lang}{ERR_INVALID_SOCKS_PORT});
            return 0;
        }
    }

    $state->{connect}->{port} =~ s/[^0-9]//g;

    if ($state->{connect}->{port} !~ /^([0-9]+)$/ || $1 < 1 || $1 > 65535) {
        do_error($L->{$lang}{ERR_INVALID_PORT});
        return 0;
    }

    if ($state->{connect}->{port} == 8443 && $state->{transport}->{xray_enabled} eq 'off') {
        do_error($L->{$lang}{ERR_PORT_8443_RESERVED});
        return 0;
    }

    return 1;
}

sub _hide_options_show_main {
    my ($ui) = @_;

    if ($ui->{opt_main}->{ow}) {
        $ui->{opt_main}->{ow}->g_wm_withdraw();
    }

    if ($ui->{mainwin}->{mw}) {
        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_raise();
        $ui->{mainwin}->{mw}->g_focus();
    }

    _ui_pump();
}

sub _apply_autorun_setting {
    my ($state, $Registry) = @_;

    my $run_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows/CurrentVersion/Run/Cryptostorm client';

    if (($state->{startup}->{autorun} // 'off') eq 'on') {
        $Registry->{$run_key} = Win32::AbsPath::Fix("$0");
    }
    else {
        delete $Registry->{$run_key};
    }
}

sub _normalize_options_after_back {
    my ($state, $ui, $L, $lang) = @_;

    # Autoconnect requires a saved token. Preserve old behavior.
    if (($state->{startup}->{autoconnect} // 'off') eq 'on') {
        if (!defined($state->{connect}->{save_token}) || $state->{connect}->{save_token} eq 'off') {
            $state->{connect}->{save_token} = 'on';
        }
    }

    # Custom SOCKS is external to this client, so the killswitch cannot reliably
    # whitelist it. Built-in local transports are covered by the CS program rules.
    if (($state->{security}->{killswitch_enabled} // 'off') eq 'on'
        && (($state->{transport}->{socks_enabled} // 'off') eq 'on')) {

        Tkx::tk___messageBox(
            -parent  => $ui->{opt_main}->{ow} || $ui->{mainwin}->{mw},
            -type    => 'ok',
            -icon    => 'info',
            -title   => 'cryptostorm.is client',
            -message => $L->{$lang}{TXT_SOCKS_NO_KILLSWITCH}
                        || 'The killswitch will be disabled while a SOCKS proxy is being used',
        );

        $state->{security}->{killswitch_enabled} = 'off';
    }
}

sub _killswitch_rule_signature {
    my ($state) = @_;

    return join('|',
        'v10',
        $state->{security}->{killswitch_enabled} // 'off',
        $state->{security}->{no_ipv6} // 'off',
        $state->{app}->{program_files_dir} // '',
    );
}

sub _killswitch_endpoint_signature {
    my ($state) = @_;

    return join('|',
        'endpoint-v2',
        $state->{security}->{no_ipv6} // 'off',
        $state->{connect}->{server_display} // '',
        $state->{connect}->{remote_addr} // '',
        $state->{connect}->{remote_ipv4} // '',
        $state->{connect}->{remote_ipv6} // '',
        $state->{transport}->{ssh_enabled} // 'off',
        $state->{transport}->{ssh_tunnel} // '',
        $state->{transport}->{https_enabled} // 'off',
        $state->{transport}->{https_mode} // '',
        $state->{transport}->{stunnel_enabled} // 'off',
        $state->{transport}->{xray_enabled} // 'off',
        $state->{connect}->{proto} // '',
        $state->{connect}->{port} // '',
    );
}


sub _standalone_ipv6_block_needed_for_connect {
    return 0 if (($state->{security}->{killswitch_enabled} // 'off') eq 'on');

    my $disable_ipv6 = (($state->{security}->{no_ipv6} // 'off') eq 'on');
    my $using_local_tunnel =
           (($state->{transport}->{ssh_enabled}     // 'off') eq 'on')
        || (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
        || (($state->{transport}->{xray_enabled}    // 'off') eq 'on');

    # Disable IPv6 must mean no outside IPv6, even without the full killswitch.
    # This is especially important for SSH/stunnel/Xray because Disable IPv6
    # makes those helpers use an IPv4 remote endpoint; any remaining system IPv6
    # default route would otherwise leak outside the VPN.
    return 1 if $disable_ipv6;

    my $has_ipv6_route = host_has_usable_ipv6_route($state, ignore_disable_ipv6 => 1);
    return 1 unless $has_ipv6_route;

    my $remote = $state->{connect}->{remote_addr} // '';
    return 1 if length($remote) && $remote !~ /:/ && !$using_local_tunnel;

    return 0;
}

sub _standalone_ipv6_block_signature_for_connect {
    my $has_ipv6_route = host_has_usable_ipv6_route($state, ignore_disable_ipv6 => 1) ? 'v6route' : 'nov6route';
    return join('|',
        'ipv6-leak-block-v2',
        $state->{security}->{no_ipv6} // 'off',
        $has_ipv6_route,
        $state->{connect}->{remote_addr} // '',
        $state->{connect}->{remote_ipv4} // '',
        $state->{connect}->{remote_ipv6} // '',
        $state->{transport}->{ssh_enabled} // 'off',
        $state->{transport}->{stunnel_enabled} // 'off',
        $state->{transport}->{xray_enabled} // 'off',
        $state->{transport}->{https_enabled} // 'off',
        $state->{transport}->{https_mode} // '',
    );
}

sub _invalidate_ipv6_block_rule_cache {
    delete $state->{runtime}->{ipv6_block_rule_state};
    delete $state->{runtime}->{ipv6_block_rule_signature};
}

sub clear_ipv6_block_rule {
    my ($reason) = @_;
    my $rule = 'cryptostorm - Block IPv6 leaks';

    del_fw_rule($rule, 1);
    $state->{runtime}->{ipv6_block_rule_state} = 'off';
    $state->{runtime}->{ipv6_block_rule_signature} = 'cleared:' . ($reason // 'manual');
    delete $state->{runtime}->{ipv6_block_rule_error};
    delete $state->{runtime}->{clear_ipv6_block_rule_cb};
    return 1;
}

sub refresh_ipv6_block_rule_for_connect {
    my $rule = 'cryptostorm - Block IPv6 leaks';
    my $want = _standalone_ipv6_block_needed_for_connect() ? 'on' : 'off';
    my $sig  = _standalone_ipv6_block_signature_for_connect();

    # Avoid doing netsh work on every Connect click when the standalone IPv6
    # leak rule is already in the desired state for this exact route/transport
    # state. Firewall import/export or rule cleanup paths invalidate this cache.
    return 1 if (($state->{runtime}->{ipv6_block_rule_state} // '') eq $want
              && (($state->{runtime}->{ipv6_block_rule_signature} // '') eq $sig));

    if ($want eq 'on') {
        del_fw_rule($rule, 1);

        # Do not rely only on remoteip=::/0 here.  Some Windows Firewall
        # versions accept that syntax but do not match all outbound IPv6
        # traffic reliably.  Use the concrete IPv6 ranges users can leak
        # through, plus ::/0 as a best-effort catch-all.  All rules share
        # the same name so del rule name=... removes the whole set.
        my @required_ranges = (
            '2000::/3',   # global unicast Internet
            'fc00::/7',   # ULA
            'fe80::/10',  # link-local
            'ff00::/8',   # multicast
        );
        my @optional_ranges = (
            '::/0',       # catch-all where supported
        );

        my $ok = 1;
        my @errors;
        my @required_protocols = qw(any TCP UDP ICMPv6);
        for my $range (@required_ranges) {
            for my $proto (@required_protocols) {
                my $cmd = qq{netsh advfirewall firewall add rule name="$rule" dir=out action=block localip=any remoteip=$range protocol=$proto profile=any interfacetype=any enable=yes 2>&1};
                my ($rt, $status) = _run_netsh_cmd($cmd, tries => 3, delay => 0.25);
                if (!netsh_success_output($rt, $status)) {
                    $ok = 0;
                    push @errors, "Range: $range\nProtocol: $proto\nCommand: $cmd\n" . _cmd_error_text($rt, $status);
                }
            }
        }

        # Add catch-all rules too where Windows accepts them, but do not fail
        # the connection if that optional form is rejected.  The concrete
        # ranges/protocols above are what actually prevent IPv6 Internet leaks.
        for my $range (@optional_ranges) {
            for my $proto (@required_protocols) {
                my $cmd = qq{netsh advfirewall firewall add rule name="$rule" dir=out action=block localip=any remoteip=$range protocol=$proto profile=any interfacetype=any enable=yes 2>&1};
                _run_netsh_cmd($cmd, tries => 1, delay => 0.10);
            }
        }

        if ($ok) {
            $state->{runtime}->{ipv6_block_rule_state} = 'on';
            $state->{runtime}->{ipv6_block_rule_signature} = $sig;
            return 1;
        }

        _invalidate_ipv6_block_rule_cache();
        $state->{runtime}->{ipv6_block_rule_error} = join("\n\n", @errors);
        return 0;
    }

    del_fw_rule($rule, 1);
    $state->{runtime}->{ipv6_block_rule_state} = 'off';
    $state->{runtime}->{ipv6_block_rule_signature} = $sig;
    delete $state->{runtime}->{ipv6_block_rule_error};
    return 1;
}

sub _apply_killswitch_after_options {
    my ($state, $ui, $L, $lang) = @_;

    my $desired_sig = _killswitch_rule_signature($state);
    my $applied     = $state->{runtime}->{killswitch_applied} // '';
    my $applied_sig = $state->{runtime}->{killswitch_rule_signature} // '';

    if (($state->{security}->{killswitch_enabled} // 'off') eq 'off') {
        return 1 if $applied eq 'off' && $applied_sig eq $desired_sig;

        # Do not run a firewall restore just because Options was opened/closed
        # while the saved setting is off.  A stale in-memory signature mismatch
        # should not trigger netsh work or status-bar firewall updates.  Only
        # tear down rules here if this process knows it applied them.
        if ($applied eq 'on') {
            killswitch_off();
        }
        else {
            $state->{runtime}->{killswitch_applied} = 'off';
            $state->{runtime}->{killswitch_rule_signature} = $desired_sig;
            delete $state->{runtime}->{killswitch_endpoint_rule_signature};
        }
        return 1;
    }

    if ($applied eq 'on' && $applied_sig eq $desired_sig) {
        # Do not churn endpoint rules merely because the Options window was
        # opened/closed.  Endpoint rules are refreshed immediately before
        # connecting, after the selected server/transport has been normalized.
        return 1;
    }

    if (windows_firewall_service_running()) {
        return killswitch_on();
    }

    my $answer = Tkx::tk___messageBox(
        -parent  => $ui->{mainwin}->{mw},
        -type    => "yesno",
        -message => $L->{$lang}{QUESTION_WINFIRE1} . " " .
                    $L->{$lang}{QUESTION_WINFIRE2},
        -icon    => "question",
        -title   => "cryptostorm.is client",
    );

    if ($answer eq "yes") {
        if (!start_windows_firewall_service()) {
            do_error($L->{$lang}{QUESTION_WINFIRE1});
            $state->{security}->{killswitch_enabled} = "off";
            return 0;
        }
        return killswitch_on();
    }
    else {
        $state->{security}->{killswitch_enabled} = "off";
        return 0 unless killswitch_off();

        save_config(
            state     => $state,
            json_file => $state->{app}->{config_json_file},
        );
    }

    return 1;
}

sub refresh_killswitch_rules_for_connect {
    return 1 unless (($state->{security}->{killswitch_enabled} // 'off') eq 'on');

    my $desired_sig = _killswitch_rule_signature($state);
    if (($state->{runtime}->{killswitch_applied} // '') eq 'on'
        && (($state->{runtime}->{killswitch_rule_signature} // '') eq $desired_sig)) {
        return ensure_killswitch_endpoint_rule_for_connect();
    }

    # If the app was restarted while killswitch rules were already active and
    # the user chose not to disable them, do not rebuild the whole firewall just
    # before connecting.  Adopt the existing base rules and only refresh the
    # transport-specific endpoint rule.
    my ($rt, $status) = _run_netsh_cmd(
        'netsh advfirewall firewall show rule name="cryptostorm - Allow CS programs" 2>&1',
        tries => 1,
        timeout => 8,
    );
    if (defined($rt) && $rt =~ /cryptostorm/i) {
        $state->{runtime}->{killswitch_applied} = 'on';
        $state->{runtime}->{killswitch_rule_signature} = $desired_sig;
        return ensure_killswitch_endpoint_rule_for_connect();
    }

    return 0 unless killswitch_on();
    return ensure_killswitch_endpoint_rule_for_connect();
}

sub ensure_killswitch_endpoint_rule_for_connect {
    return 1 unless (($state->{security}->{killswitch_enabled} // 'off') eq 'on');
    return 0 if $state->{runtime}->{firewall_update_active};

    my $desired_sig = _killswitch_endpoint_signature($state);
    return 1 if (($state->{runtime}->{killswitch_endpoint_rule_signature} // '') eq $desired_sig);

    _fw_batch_start();
    _replace_killswitch_endpoint_rules();

    my $ok = _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_FW_ADD} || 'Failed to add firewall rules');
    $state->{runtime}->{killswitch_endpoint_rule_signature} = $desired_sig if $ok;

    return $ok;
}

sub _valid_firewall_ip {
    my ($ip) = @_;

    return 0 unless defined $ip && length $ip;
    return 0 if $ip eq '127.0.0.1' || $ip eq '::1';
    return 0 unless $ip =~ /^[0-9a-f:.]+$/i;

    return 1;
}

sub _ssh_tunnel_firewall_ips {
    return unless (($state->{transport}->{ssh_enabled} // 'off') eq 'on');

    my $target = _resolve_ssh_tunnel_target($state, $servers);
    return unless $target && ref($target) eq 'HASH';

    my @ips;

    push @ips, $target->{ipv4}
        if _valid_firewall_ip($target->{ipv4});

    push @ips, $target->{ipv6}
        if (($state->{security}->{no_ipv6} // 'off') eq 'off')
        && _valid_firewall_ip($target->{ipv6});

    if (!@ips && _valid_firewall_ip($target->{host})) {
        return if (($state->{security}->{no_ipv6} // 'off') eq 'on')
               && (($target->{host} // '') =~ /:/);

        push @ips, $target->{host};
    }

    my %seen;
    return grep { !$seen{lc $_}++ } @ips;
}

sub _https_tunnel_firewall_ips {
    return unless (($state->{transport}->{https_enabled} // 'off') eq 'on');
    return unless (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
               || (($state->{transport}->{xray_enabled} // 'off') eq 'on');

    my @ips;

    # For stunnel/Xray the firewall has to allow the helper process to reach
    # the real remote VPN node, not the local 127.0.0.1 OpenVPN remote.  If
    # Disable IPv6 is on, only allow the IPv4 endpoint that the config writer
    # will also choose.  If IPv6 is allowed, include both endpoint families so
    # the rule still matches if route preference changes between Options and
    # Connect.
    my $ipv4 = $state->{connect}->{remote_ipv4} // '';
    my $ipv6 = $state->{connect}->{remote_ipv6} // '';
    my $addr = $state->{connect}->{remote_addr} // '';

    push @ips, $ipv4 if _valid_firewall_ip($ipv4);

    if (($state->{security}->{no_ipv6} // 'off') eq 'off') {
        push @ips, $ipv6 if _valid_firewall_ip($ipv6);
        push @ips, $addr if _valid_firewall_ip($addr);
    }
    elsif (!@ips && _valid_firewall_ip($addr) && $addr !~ /:/) {
        push @ips, $addr;
    }

    my %seen;
    return grep { !$seen{lc $_}++ } @ips;
}

sub _replace_killswitch_endpoint_rules {
    del_fw_rule("cryptostorm - Allow VPN endpoint", 1);
    del_fw_rule("cryptostorm - Allow SSH tunnel endpoint", 1);
    del_fw_rule("cryptostorm - Allow HTTPS tunnel endpoint", 1);
    delete $state->{runtime}->{killswitch_endpoint_rule_signature};

    my $ssh_enabled   = (($state->{transport}->{ssh_enabled} // 'off') eq 'on');
    my $https_enabled = (($state->{transport}->{https_enabled} // 'off') eq 'on')
                     && (
                            (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
                         || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
                        );

    if ($ssh_enabled) {
        my @ssh_ips = _ssh_tunnel_firewall_ips();
        add_fw_rule(
            "cryptostorm - Allow SSH tunnel endpoint",
            "out",
            "remoteip=" . join(',', @ssh_ips) . " protocol=TCP",
        ) if @ssh_ips;

        return;
    }

    if ($https_enabled) {
        my @https_ips = _https_tunnel_firewall_ips();
        my $port = $state->{connect}->{port} || 443;
        my $program = (($state->{transport}->{xray_enabled} // 'off') eq 'on')
            ? ($state->{app}->{program_files_dir} . '\\xray.exe')
            : ($state->{app}->{program_files_dir} . '\\cs-https-tun.exe');

        add_fw_rule(
            "cryptostorm - Allow HTTPS tunnel endpoint",
            "out",
            "program=\"$program\" remoteip=" . join(',', @https_ips) . " remoteport=$port protocol=TCP",
        ) if @https_ips;

        return;
    }

    my $remote = $state->{connect}->{remote_addr} // '';
    if (_valid_firewall_ip($remote)) {
        return if (($state->{security}->{no_ipv6} // 'off') eq 'on') && $remote =~ /:/;
        add_fw_rule("cryptostorm - Allow VPN endpoint", "out", "remoteip=$remote");
    }
}

sub refresh_runtime_vpn_ips {
    return 1 if $state->{runtime}->{localip} && (
        (($state->{security}->{no_ipv6} // 'off') eq 'on') || $state->{runtime}->{localip6}
    );

    my $out = '';
    my $cmd = 'ipconfig /all 2>&1';
    my ($captured, $status) = _run_hidden_capture_cmd($cmd, timeout => 8);
    $out = $captured if defined $captured;

    if (!length $out && $^O !~ /MSWin32/i) {
        $out = `$cmd`;
        $out = '' unless defined $out;
    }

    if (!$state->{runtime}->{localip}
        && $out =~ /\b(10\.(?:66|67|70|71)\.\d{1,3}\.(?:25[0-5]|2[0-4]\d|1\d\d|\d\d|[2-9]))\b/) {
        $state->{runtime}->{localip} = $1;
    }

    if (($state->{security}->{no_ipv6} // 'off') eq 'off'
        && !$state->{runtime}->{localip6}
        && $out =~ /\b(fd00:10:60:(?:[a-f0-9]{1,4}:){4}[a-f0-9]{1,4})\b/i) {
        $state->{runtime}->{localip6} = $1;
    }

    return 1;
}

sub refresh_killswitch_tunnel_rules_after_connect {
    return 1 unless (($state->{security}->{killswitch_enabled} // 'off') eq 'on');
    return 0 if $state->{runtime}->{firewall_update_active};

    refresh_runtime_vpn_ips();

    _fw_batch_start();

    for my $rule (
        "cryptostorm - Allow internal VPN DNS",
        "cryptostorm - Allow internal IPv4 in",
        "cryptostorm - Allow internal IPv4 out",
        "cryptostorm - Allow internal IPv4 gateway in",
        "cryptostorm - Allow internal IPv4 gateway out",
        "cryptostorm - Allow internal IPv4 tunnel subnet",
        "cryptostorm - Allow internal IPv6 tunnel subnet",
        "cryptostorm - Allow internal IPv6 in",
        "cryptostorm - Allow internal IPv6 out",
        "cryptostorm - Allow internal IPv6 gateway in",
        "cryptostorm - Allow internal IPv6 gateway out",
    ) {
        del_fw_rule($rule, 1);
    }

    my $dns_ips = "10.31.33.7,10.31.33.8";
    $dns_ips .= ",2001:db8::7,2001:db8::8"
        if (($state->{security}->{no_ipv6} // 'off') eq 'off');

    add_fw_rule("cryptostorm - Allow internal VPN DNS", "out", "remoteip=$dns_ips");

    # Broad VPN-source rules are a fallback for cases where management/log
    # parsing has not yet populated the exact assigned address. They are still
    # scoped to cryptostorm's tunnel address space, so normal LAN/WAN source
    # addresses remain blocked while the killswitch is active.
    add_fw_rule("cryptostorm - Allow internal IPv4 tunnel subnet", "out", "localip=10.64.0.0-10.127.255.255 remoteip=any");
    if (($state->{security}->{no_ipv6} // 'off') eq 'off') {
        add_fw_rule("cryptostorm - Allow internal IPv6 tunnel subnet", "out", "localip=fd00:10:60::/48 remoteip=any");
    }

    if ($state->{runtime}->{localip}) {
        my $localip = $state->{runtime}->{localip};
        my $gw4 = $localip;
        $gw4 =~ s/\.\d+$/.1/;

        add_fw_rule("cryptostorm - Allow internal IPv4 in",  "out", "localip=$localip remoteip=any");
        add_fw_rule("cryptostorm - Allow internal IPv4 out", "out", "localip=any remoteip=$localip");
        add_fw_rule("cryptostorm - Allow internal IPv4 gateway in",  "out", "localip=any remoteip=$gw4");
        add_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "out", "localip=$gw4 remoteip=any");
    }

    if (($state->{security}->{no_ipv6} // 'off') eq 'off' && $state->{runtime}->{localip6}) {
        my $localip6 = $state->{runtime}->{localip6};
        my $localip6_host = ($localip6 =~ m{/}) ? $localip6 : "$localip6/128";
        my $gw6 = 'fe80::1';

        add_fw_rule("cryptostorm - Allow internal IPv6 in",  "out", "remoteip=2000::/3");
        add_fw_rule("cryptostorm - Allow internal IPv6 in",  "out", "localip=$localip6_host remoteip=any");
        add_fw_rule("cryptostorm - Allow internal IPv6 out", "out", "localip=any remoteip=$localip6_host");
        add_fw_rule("cryptostorm - Allow internal IPv6 gateway in",  "out", "localip=any remoteip=$gw6");
        add_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "out", "localip=$gw6 remoteip=any");
    }

    return _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_FW_ADD} || 'Failed to add firewall rules');
}

sub maybe_prompt_for_update {
    my $lang = $state->{app}->{lang} || 'English';

    return unless $state->{runtime}->{upgrade};
    if (($state->{runtime}->{upgrade} // 0)) {
        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_raise();
        $ui->{mainwin}->{mw}->g_focus();
        _ui_pump();
    }
    my $answer = Tkx::tk___messageBox(
        -parent  => $ui->{mainwin}->{mw},
        -type    => "yesno",
        -message => $L->{$lang}{QUESTION_NEWVER1} . "\n" .
                    $L->{$lang}{QUESTION_NEWVER2} . "\n",
        -icon    => "question",
        -title   => "cryptostorm.is client",
    );

    return unless $answer eq "yes";

    if (download_and_verify_update(state => $state, ui => $ui, L => $L)) {
        $state->{runtime}->{schedule_upgrade} = 1;

        Tkx::tk___messageBox(
            -parent  => $ui->{mainwin}->{mw},
            -type    => "ok",
            -message => $L->{$lang}{TXT_UPGRADING1} . "\n" .
                        $L->{$lang}{TXT_UPGRADING2},
            -icon    => "info",
            -title   => "cryptostorm.is client",
        );
    }
}

sub download_and_verify_update {
    my (%args) = @_;

    my $state = $args{state} or die "missing state";
    my $ui    = $args{ui}    or die "missing ui";
    my $L     = $args{L}     or die "missing L";


    my $lang = $state->{app}->{lang} || 'English';

    my $base_url = 'http://10.31.33.7';
    my $file     = 'cryptostorm_setup.exe';

    my $tmp_dir  = 'tmp';
    my $exe_path = "$tmp_dir\\$file";
    my $sig_path = "$tmp_dir\\$file.hash";

    mkdir $tmp_dir unless -d $tmp_dir;

    $ui->{mainwin}->{exit_btn}->configure(-state => 'disabled');

    my $http = HTTP::Tiny->new(
        agent   => 'Cryptostorm client',
        timeout => 30,
    );

    $state->{runtime}->{pbar} = 0;
    $state->{runtime}->{pbar_target} = 0;
    $state->{runtime}->{pbar_animating} = 0;

    for my $item (
        [$file,        $exe_path, 1],
        ["$file.hash", $sig_path, 0],
    ) {
        my ($remote_name, $local_path, $show_progress_bar) = @$item;
        my $url = "$base_url/$remote_name";

        my ($ok, $err) = _download_update_file(
            state             => $state,
            ui                => $ui,
            L                 => $L,
            lang              => $lang,
            http              => $http,
            url               => $url,
            remote_name       => $remote_name,
            local_path        => $local_path,
            show_progress_bar => $show_progress_bar,
        );

        if (!$ok) {
            unlink $local_path if -e $local_path;
            $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');
            do_error($err);
            return 0;
        }
    }

    my $ossl = $state->{app}->{ossl_exe} || 'openssl.exe';

    my $verify_cmd = qq("$ossl" dgst -sha512 -verify widget.pub -signature "$sig_path" "$exe_path");

    my @spin = ('[|]', '[/]', '[-]', '[\\]');
    my $spin_i = 0;
    $state->{runtime}->{status_text} = ($L->{$lang}{ERR_VERIFY} || 'Verifying') . " - $file $spin[0]";
    _ui_pump();

    my ($verify_out, $verify_status) = _run_hidden_capture_cmd(
        $verify_cmd,
        timeout => 120,
        tick_cb => sub {
            my $spin = $spin[$spin_i++ % @spin];
            $state->{runtime}->{status_text} = ($L->{$lang}{ERR_VERIFY} || 'Verifying') . " - $file $spin";
        },
    );
    $verify_out = '' unless defined $verify_out;

    if ($verify_out !~ /Verified OK/) {
        unlink $exe_path if -e $exe_path;

        $state->{runtime}->{status_text} = $L->{$lang}{ERR_VERIFY} . " - $file";
        $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');

        do_error(
            $L->{$lang}{ERR_VERIFY} . " - $file: $verify_out\n$verify_cmd"
        );

        return 0;
    }

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_DOWNLOAD_VERIFIED};
    $state->{runtime}->{pbar} = 100;
    _ui_pump();

    # Keep the traditional install-root copy so a user can still launch the
    # already-verified installer manually if needed.  Auto-upgrade deliberately
    # does NOT execute this copy: running Setup from inside {app} can make the
    # setup process itself participate in file-in-use/replacement checks.
    my $root_installer_path = "..\\$file";

    copy($exe_path, $root_installer_path)
        or do {
            $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');
            do_error("Failed to copy $exe_path to $root_installer_path: $!");
            return 0;
        };

    # Make a unique launch copy outside the application directory.  do_app_exit
    # starts a hidden waiter which launches this file only after client.exe is
    # completely gone, eliminating the updater-vs-old-process shutdown race.
    my $launch_dir = $ENV{TEMP} || $ENV{TMP} || '';
    $launch_dir =~ s/[\\\/]\z//;

    if (!$launch_dir || !-d $launch_dir) {
        $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');
        do_error("Could not find a usable Windows TEMP directory for the updater.");
        return 0;
    }

    my $launch_stamp = $$ . '_' . int(time * 1000) . '_' . int(rand(100000));
    my $launch_installer_path = "$launch_dir\\cryptostorm_setup_$launch_stamp.exe";

    copy($exe_path, $launch_installer_path)
        or do {
            $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');
            do_error("Failed to copy $exe_path to $launch_installer_path: $!");
            return 0;
        };

    $state->{runtime}->{upgrade_installer_path} = $launch_installer_path;

    unlink $exe_path if -e $exe_path;
    unlink $sig_path if -e $sig_path;
    rmdir $tmp_dir;

    $ui->{mainwin}->{exit_btn}->configure(-state => 'normal');

    return 1;
}

sub _download_update_file {
    my (%args) = @_;

    my $state       = $args{state} or die "missing state";
    my $ui          = $args{ui}    or die "missing ui";
    my $L           = $args{L}     or die "missing L";
    my $lang        = $args{lang}  || ($state->{app}->{lang} || 'English');
    my $http        = $args{http}  or die "missing http";
    my $url         = $args{url}   or die "missing url";
    my $remote_name = $args{remote_name} || $url;
    my $local_path  = $args{local_path}  or die "missing local_path";

    my $base_msg = ($L->{$lang}{TXT_DOWNLOADING_LATEST} || 'Downloading latest') . " $remote_name";
    my @spin = ('[|]', '[/]', '[-]', '[\\]');
    my $spin_i = 0;
    my $downloaded = 0;
    my $total = 0;
    my $last_ui = 0;

    my $fh;
    if (!open $fh, '>:raw', $local_path) {
        return (0, ($L->{$lang}{ERR_DOWNLOAD} || 'Download failed') . " $local_path: $!");
    }

    my $update_status = sub {
        my ($force) = @_;
        my $now = time;
        return if !$force && (($now - $last_ui) < 0.08);
        $last_ui = $now;

        my $spin = $spin[$spin_i++ % @spin];
        my $pct_text = '';

        if ($total && $total > 0) {
            my $pct = ($downloaded / $total) * 100;
            $pct = 100 if $pct > 100;
            $pct_text = sprintf(' %.2f%%', $pct);
            if ($args{show_progress_bar}) {
                $state->{runtime}->{pbar} = int($pct + 0.5);
                $state->{runtime}->{pbar_target} = $state->{runtime}->{pbar};
            }
        } elsif ($downloaded) {
            $pct_text = sprintf(' %d bytes', $downloaded);
        }

        $state->{runtime}->{status_text} = "$base_msg$pct_text $spin";
        _ui_pump();
    };

    $update_status->(1);

    my $write_error = '';
    my $res = $http->request('GET', $url, {
        data_callback => sub {
            my ($chunk, $res) = @_;
            return if length $write_error;

            if (!$total && $res && $res->{headers}) {
                my $cl = $res->{headers}{'content-length'};
                $cl = $cl->[0] if ref($cl) eq 'ARRAY';
                $total = $cl if defined($cl) && $cl =~ /^\d+$/;
            }

            my $ok = print {$fh} $chunk;
            if (!$ok) {
                $write_error = "$!";
                return;
            }

            $downloaded += length($chunk);
            $update_status->(0);
        },
    });

    my $close_ok = close $fh;

    if (length $write_error) {
        unlink $local_path if -e $local_path;
        return (0, ($L->{$lang}{ERR_DOWNLOAD} || 'Download failed') . " $local_path: $write_error");
    }

    if (!$close_ok) {
        unlink $local_path if -e $local_path;
        return (0, ($L->{$lang}{ERR_DOWNLOAD} || 'Download failed') . " $local_path: $!");
    }

    if (!$res || !$res->{success}) {
        unlink $local_path if -e $local_path;
        return (0, ($L->{$lang}{ERR_DOWNLOAD} || 'Download failed') . " $url: " . (($res && $res->{status}) || 0) . " " . (($res && $res->{reason}) || ''));
    }

    $downloaded = -s $local_path if -e $local_path;
    $downloaded ||= 0;

    if ($total && $downloaded < $total) {
        unlink $local_path if -e $local_path;
        return (0, ($L->{$lang}{ERR_DOWNLOAD} || 'Download failed') . " $url: incomplete download ($downloaded/$total bytes)");
    }

    if ($total && $args{show_progress_bar}) {
        $state->{runtime}->{pbar} = 100;
        $state->{runtime}->{pbar_target} = 100;
    }

    $state->{runtime}->{status_text} = "$base_msg 100.00%" if $total;
    _ui_pump();

    return (1, '');
}

sub power_event {
 my ($win, @args) = @_;
 if ($args[0] eq PBT_APMSUSPEND) {
  # suspending, so disconnect if connected
  if ($state->{runtime}->{exit_btn_mode} eq 'disconnect') {
   $state->{runtime}->{connected} = 1;
   $state->{runtime}->{pbar} = 0;
   $state->{tray}->{show_tip_once} = 0;
   $state->{runtime}->{status_text} = $L->{$lang}{TXT_DISCONNECTED};
   $ui->{mainwin}->{exit_btn}->configure(-text => $L->{$lang}{TXT_EXIT});
   $state->{runtime}->{exit_btn_mode} = 'exit';
   $ui->{mainwin}->{options_btn}->configure(-state => "normal");
   $ui->{mainwin}->{connect_btn}->configure(-state => "normal");
   $ui->{mainwin}->{server_picker}->configure(-state => "readonly");
   delete_logbox_status_lines();

   append_log_status_line(
       $ui,
       $L->{$lang}{TXT_SUSPENDING},
       "warnline",
       "status_suspending",
   );

   append_log_status_line(
       $ui,
       $L->{$lang}{TXT_DISCONNECTED},
       "badline",
       "status_disconnected",
   );

   $state->{runtime}->{last_log_status} = 'disconnected';
   shutdown_openvpn();
   $ui->{mainwin}->{exit_btn}->configure(-state => "normal");
  }
 }
 if (($args[0] eq PBT_APMRESUMEAUTOMATIC) || ($args[0] eq PBT_APMRESUMECRITICAL)) {
  # resuming from suspend, so reconnect if client was connected before suspend
  if ($state->{runtime}->{connected}) {
   $ui->{mainwin}->{world_img}->configure(-image => "mainicon");
   $ui->{mainwin}->{connect_btn}->invoke();
   $state->{runtime}->{connected} = 0;
  }
 }
}

sub animate_world_icon {
    my (%args) = @_;
    my $ui     = $args{ui}     or die "animate_world_icon: missing ui";
    my $prefix = $args{prefix} || 'b';
    my $final  = $args{final}  || 'mainicon';
    my $delay  = defined $args{delay} ? $args{delay} : 0.08;

    return unless $ui->{mainwin}->{world_img};

    $ui->{mainwin}->{world_img}->configure(-image => "mainicon");

    for my $i (1 .. 6) {
        $ui->{mainwin}->{world_img}->configure(-image => "$prefix$i");
        Tkx::update();
        select(undef, undef, undef, $delay);
    }

    for my $i (reverse 1 .. 6) {
        $ui->{mainwin}->{world_img}->configure(-image => "$prefix$i");
        Tkx::update();
        select(undef, undef, undef, $delay);
    }

    $ui->{mainwin}->{world_img}->configure(-image => $final);
}

sub do_error {
    my $error = $_[0];

    eval { $ui->{mainwin}->{world_img}->g_grid_remove(); };

    $ui->{mainwin}->{error_img}->g_grid(-column => 0, -row => 0) unless !defined($ui->{mainwin}->{error_img});

    Tkx::tk___messageBox(
        -icon    => "error",
        -message => "$error"
    );

    $ui->{mainwin}->{error_img}->g_grid_remove() unless !defined($ui->{mainwin}->{error_img});

    eval { $ui->{mainwin}->{world_img}->g_grid(-column => 0, -row => 0); };

    my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';
    if ($mode eq 'exit') {
        $ui->{mainwin}->{options_btn}->configure(-state => "normal") unless !defined($ui->{mainwin}->{options_btn});
    }

    if (defined($state->{startup}->{autoconnect}) && ($state->{startup}->{autoconnect} eq "on")) {
        $state->{runtime}->{status_text}    = $L->{$state->{app}->{lang}}{ERR_AUTO_CONNECT};
        $state->{startup}->{autoconnect}  = "off";
        save_config(state => $state, json_file => $state->{app}->{config_json_file});
    }

    return;
}

sub isEmpty {
 return undef unless -d $_[0];
 opendir my $dh, $_[0] or print $!;
 my $count = grep { ! /^\.{1,2}/ } readdir $dh;
 return $count;
}

sub get_next_free_local_port {
    my ($startport) = @_;

    if (defined $startport && $startport =~ /^random(?:_(tunnel|mgmt))?$/) {
        my $kind = $1 || 'local';
        my %avoid = map { $_ => 1 } (31337, 5000, 5061, 5062, 5063, 8443);

        # Use high ephemeral-ish ports.  Randomizing the local tunnel listener
        # avoids stale 31337 listeners from previous stunnel/Xray/SSH processes.
        for (1 .. 180) {
            my $tryport = 20000 + int(rand(29000)); # 20000..48999; avoid Windows ephemeral outbound range
            next if $avoid{$tryport};

            my $freeport = local_port_is_free($tryport);
            return $freeport if $freeport;

            _ui_pump();
        }

        # Last resort: deterministic scan in the same range, still skipping
        # profile-reserved ports.
        for my $tryport (20000 .. 48999) {
            next if $avoid{$tryport};
            my $freeport = local_port_is_free($tryport);
            return $freeport if $freeport;
            _ui_pump();
        }

        do_error($L->{$state->{app}->{lang}}{ERR_NO_FREE_PORT})
            if defined &do_error;

        return 0;
    }

    $startport ||= 31337;

    for my $tryport ($startport .. $startport + 100) {
        next if $tryport == 5061 || $tryport == 5062 || $tryport == 5063 || $tryport == 8443;

        my $freeport = local_port_is_free($tryport);
        return $freeport if $freeport;

        _ui_pump();
    }

    do_error($L->{$state->{app}->{lang}}{ERR_NO_FREE_PORT})
        if defined &do_error;

    return 0;
}

sub wait_local_tcp_port_free {
    my ($port, $timeout_ms) = @_;
    return 1 unless defined $port && $port =~ /^\d+$/ && $port > 0;

    $timeout_ms ||= 1500;
    my $deadline = time + ($timeout_ms / 1000);

    while (time < $deadline) {
        return 1 if local_port_is_free($port);
        _ui_pump();
        select undef, undef, undef, 0.10;
    }

    return local_port_is_free($port) ? 1 : 0;
}

sub _fw_batch_start {
    $state->{runtime}->{fw_batch_errors} = [];
}

sub _fw_batch_error {
    my ($message) = @_;
    $message = '' unless defined $message;

    if (ref($state->{runtime}->{fw_batch_errors}) eq 'ARRAY') {
        push @{ $state->{runtime}->{fw_batch_errors} }, $message;
        return;
    }

    do_error($message);
}

sub _fw_batch_finish {
    my ($context) = @_;
    my $errors = delete $state->{runtime}->{fw_batch_errors};

    return 1 unless ref($errors) eq 'ARRAY' && @$errors;

    my @shown = @$errors > 6 ? (@$errors[0 .. 5], '...') : @$errors;
    my $msg = ($context || 'Firewall update failed') . "\n\n" . join("\n\n", @shown);
    $msg .= "\n\nAdditional firewall errors were suppressed." if @$errors > 6;

    do_error($msg);
    return 0;
}


sub _fw_backup_path {
    my $base = $state->{app}->{program_files_dir} || '.';
    my $path = $base . "\\..\\user\\all.wfw";
    return Win32::AbsPath::Fix($path) || $path;
}


sub _cmd_exit_text {
    my ($status) = @_;
    return 'unknown' unless defined $status;
    return 'spawn failed' if $status == -1;
    return 'signal ' . ($status & 127) if ($status & 127);
    return 'exit ' . ($status >> 8);
}

sub _cmd_error_text {
    my ($out, $status) = @_;
    $out = '' unless defined $out;
    $out =~ s/\s+\z//;
    $out = '(no stdout/stderr captured)' unless length $out;
    return _cmd_exit_text($status) . "\n" . $out;
}

sub _fw_diag_text {
    my @diag;

    my $svc = `sc query MpsSvc 2>&1`;
    $svc = '' unless defined $svc;
    $svc =~ s/\s+\z//;
    push @diag, "sc query MpsSvc:\n" . ($svc || '(no output)');

    my $profile = `netsh advfirewall show currentprofile 2>&1`;
    $profile = '' unless defined $profile;
    $profile =~ s/\s+\z//;
    push @diag, "netsh currentprofile:\n" . ($profile || '(no output)');

    return join("\n\n", @diag);
}

sub _ui_pump {
    # Use a full Tk event pass while long-running firewall commands are active.
    # idletasks alone can leave the main window half-painted on slower Win7 VMs.
    eval { Tkx::update(); 1 } or eval { Tkx::update('idletasks'); };
}

sub connect_attempt_alive {
    my ($attempt_id) = @_;
    return 0 if defined($attempt_id)
             && (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
    return 0 if ($state->{runtime}->{stop} // 0);
    my $mode = $state->{runtime}->{exit_btn_mode} // '';
    return 0 if $mode =~ /^(aborting|disconnecting|exit)$/;
    return 1;
}

sub begin_tunnel_start_ui_lock {
    my ($attempt_id) = @_;
    return unless connect_attempt_alive($attempt_id);
    return if $state->{runtime}->{tunnel_start_ui_locked};

    $state->{runtime}->{tunnel_start_ui_locked} = 1;
    eval { $ui->{mainwin}->{exit_btn}->configure(-state => 'disabled'); 1 };
    _ui_pump();
}

sub end_tunnel_start_ui_lock {
    my ($attempt_id) = @_;
    delete $state->{runtime}->{tunnel_start_ui_locked};

    if (connect_attempt_alive($attempt_id)
        && (($state->{runtime}->{exit_btn_mode} // '') eq 'abort')) {
        eval { $ui->{mainwin}->{exit_btn}->configure(-state => 'normal'); 1 };
    }
    _ui_pump();
}

sub silent_tunnel_failure {
    my ($attempt_id) = @_;
    return !connect_attempt_alive($attempt_id);
}

sub _run_hidden_capture_cmd {
    my ($cmd, %opts) = @_;
    my $timeout = $opts{timeout} || 20;
    my $tick_cb = $opts{tick_cb};

    # Non-Windows fallback keeps syntax/dev tests working.
    if ($^O !~ /MSWin32/i) {
        eval { $tick_cb->() } if $tick_cb;
        my $out = `$cmd`;
        $out = '' unless defined $out;
        return ($out, $?);
    }

    my $comspec = $ENV{ComSpec} || (($ENV{SystemRoot} || 'C:\\Windows') . '\\System32\\cmd.exe');
    my $tmp = $ENV{TEMP} || $ENV{TMP} || '.';
    $tmp =~ s/[\\\/]\z//;

    my $stamp = $$ . '_' . int(time * 1000) . '_' . int(rand(100000));
    my $out_file = "$tmp\\cs_fw_$stamp.log";
    my $bat_file = "$tmp\\cs_fw_$stamp.cmd";

    my $bat;
    if (!open $bat, '>:raw', $bat_file) {
        return ("Could not write temporary command file: $bat_file: $!", -1);
    }

    print {$bat} "\@echo off\r\n";
    print {$bat} qq{$cmd > "$out_file" 2>&1\r\n};
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
        return ("Could not start hidden command: $err\n$cmd", -1);
    }

    my $deadline = time + $timeout;
    my $exit = 259;
    my $tick_i = 0;
    while (1) {
        $proc->GetExitCode($exit);
        last if defined($exit) && $exit != 259;

        if ($tick_cb && (($tick_i++ % 5) == 0)) {
            eval { $tick_cb->(); 1 };
        }

        _ui_pump();

        if (time >= $deadline) {
            eval { $proc->Kill(1); };
            $exit = 1;
            last;
        }

        select undef, undef, undef, 0.05;
    }

    my $out = '';
    if (-e $out_file && open my $fh, '<:raw', $out_file) {
        local $/;
        $out = <$fh> // '';
        close $fh;
    }

    unlink $out_file if -e $out_file;
    unlink $bat_file if -e $bat_file;

    # Return a Perl-system-compatible encoded status so _cmd_exit_text()
    # and older call sites keep interpreting failures correctly.
    return ($out, (($exit || 0) << 8));
}

sub _run_taskkill_wait {
    my ($cmd, %opts) = @_;
    my $timeout = $opts{timeout} || 5;
    my ($out, $status) = _run_hidden_capture_cmd($cmd, timeout => $timeout);
    return ($out, $status);
}

sub _run_netsh_cmd {
    my ($cmd, %opts) = @_;
    my $tries = $opts{tries} || 3;
    my $delay = defined $opts{delay} ? $opts{delay} : 0.25;
    my $timeout = $opts{timeout} || 20;

    my ($out, $status) = ('', 0);

    for my $attempt (1 .. $tries) {
        ($out, $status) = _run_hidden_capture_cmd($cmd, timeout => $timeout);
        $out = '' unless defined $out;

        return ($out, $status) if netsh_success_output($out, $status);

        # Win7/Win10 advfirewall can transiently reject commands immediately
        # after an import/delete-all/profile-policy change.  A short retry
        # avoids leaving the runtime in a poisoned firewall state.
        _ui_pump();
        select undef, undef, undef, $delay if $attempt < $tries;
    }

    return ($out, $status);
}

sub _fw_import_backup {
    my (%args) = @_;
    my $delete_on_success = $args{delete_on_success} ? 1 : 0;
    my $path = _fw_backup_path();
    return (0, 'missing', '') unless -e $path;

    my $cmd = qq{netsh advfirewall import "$path" 2>&1};
    my ($out, $status) = _run_netsh_cmd($cmd, tries => 8, delay => 0.75);
    my $ok = netsh_success_output($out, $status);
    if ($ok) {
        unlink($path) if $delete_on_success;
        return (1, $cmd, $out);
    }
    return (0, $cmd, _cmd_error_text($out, $status) . "\n\n" . _fw_diag_text());
}

sub _fw_export_backup {
    my $path = _fw_backup_path();
    return (1, 'existing', '') if -e $path;

    my $cmd = qq{netsh advfirewall export "$path" 2>&1};
    my ($out, $status) = _run_netsh_cmd($cmd, tries => 8, delay => 0.75);
    return (1, $cmd, $out) if netsh_success_output($out, $status);
    return (0, $cmd, _cmd_error_text($out, $status) . "\n\n" . _fw_diag_text());
}

sub _fw_set_ui_locked {
    my ($locked) = @_;

    eval {
        my $mw = $ui->{mainwin}->{mw};

        if ($locked) {
            $mw->g_wm_protocol('WM_DELETE_WINDOW', sub { return 1 });
            $mw->configure(-cursor => 'watch');
            $ui->{mainwin}->{options_btn}->configure(-state => "disabled") if $ui->{mainwin}->{options_btn};
            $ui->{mainwin}->{connect_btn}->configure(-state => "disabled") if $ui->{mainwin}->{connect_btn};
            $ui->{mainwin}->{server_picker}->configure(-state => "disabled") if $ui->{mainwin}->{server_picker};
            $ui->{mainwin}->{exit_btn}->configure(-state => "disabled") if $ui->{mainwin}->{exit_btn};
        }
        else {
            my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';
            $mw->configure(-cursor => '');

            if ($mode =~ /^(?:preparing|abort|aborting|disconnecting|disconnect)$/) {
                # A firewall update can finish while do_connect is still pumping
                # Tk events.  Do not restore Connect/Options in that state, or
                # the user can re-enter Options/Connect mid-attempt.
                $mw->g_wm_protocol('WM_DELETE_WINDOW', sub { return 1 });
                $ui->{mainwin}->{options_btn}->configure(-state => "disabled") if $ui->{mainwin}->{options_btn};
                $ui->{mainwin}->{connect_btn}->configure(-state => "disabled") if $ui->{mainwin}->{connect_btn};
                $ui->{mainwin}->{server_picker}->configure(-state => "disabled") if $ui->{mainwin}->{server_picker};

                if ($ui->{mainwin}->{exit_btn}) {
                    $ui->{mainwin}->{exit_btn}->configure(
                        -state => ($mode eq 'abort' || $mode eq 'disconnect') ? "normal" : "disabled",
                    );
                }
            }
            else {
                $mw->g_wm_protocol('WM_DELETE_WINDOW', \&do_app_exit);
                $ui->{mainwin}->{options_btn}->configure(-state => "normal") if $ui->{mainwin}->{options_btn};
                $ui->{mainwin}->{connect_btn}->configure(-state => "normal") if $ui->{mainwin}->{connect_btn};
                $ui->{mainwin}->{server_picker}->configure(-state => "readonly") if $ui->{mainwin}->{server_picker};
                $ui->{mainwin}->{exit_btn}->configure(-state => "normal") if $ui->{mainwin}->{exit_btn};
            }
        }
    };

    _ui_pump();
}

sub _fw_restore_ui_after_killswitch {
    _fw_set_ui_locked(0);
}

sub _restore_firewall_after_killswitch_failure {
    eval {
        my ($import_ok, $import_cmd, $import_out) = _fw_import_backup(delete_on_success => 1);

        # If the backup import fails, leave all.wfw in place.  Do not delete the
        # user's only copy of their previous firewall state.
        if (!$import_ok) {
            _run_netsh_cmd('netsh advfirewall set allprofiles settings inboundusernotification enable 2>&1', tries => 3);
            _run_netsh_cmd('netsh advfirewall set allprofiles firewallpolicy BlockInbound,AllowOutbound 2>&1', tries => 3);
        }

        for my $rule (_killswitch_rule_names()) {
            `netsh advfirewall firewall del rule name="$rule" 2>&1`;
        }
    };

    $state->{security}->{killswitch_enabled} = 'off';
    $state->{runtime}->{killswitch_applied} = 'off';
    $state->{runtime}->{killswitch_rule_signature} = _killswitch_rule_signature($state);
    delete $state->{runtime}->{killswitch_endpoint_rule_signature};

    eval {
        save_config(
            state     => $state,
            json_file => $state->{app}->{config_json_file},
        );
    };
}

sub _killswitch_rule_names {
    return (
        "cryptostorm - Allow cryptostorm.is and .nu",
        "cryptostorm - Allow loopback",
        "cryptostorm - Allow CS programs",
        "cryptostorm - Allow DHCP",
        "cryptostorm - Allow internal IPv4 in",
        "cryptostorm - Allow internal IPv4 out",
        "cryptostorm - Allow internal IPv4 tunnel subnet",
        "cryptostorm - Allow internal IPv6 tunnel subnet",
        "cryptostorm - Allow internal IPv6 in",
        "cryptostorm - Allow internal IPv6 out",
        "cryptostorm - Allow internal IPv4 gateway in",
        "cryptostorm - Allow internal IPv4 gateway out",
        "cryptostorm - Allow internal IPv6 gateway in",
        "cryptostorm - Allow internal IPv6 gateway out",
        "cryptostorm - Allow IPv6 control",
        "cryptostorm - Allow internal VPN DNS",
        "cryptostorm - Allow LAN",
        "cryptostorm - Allow VPN endpoint",
        "cryptostorm - Allow SSH tunnel endpoint",
        "cryptostorm - Allow HTTPS tunnel endpoint",
        "cryptostorm - Allow VPN IPs",
    );
}

sub killswitch_on {
 return 0 if $state->{runtime}->{firewall_update_active};
 $state->{runtime}->{firewall_update_active} = 1;
 my $fw_done = sub { delete $state->{runtime}->{firewall_update_active}; return $_[0]; };
 _fw_set_ui_locked(1);

 _fw_batch_start();

 my $tmpbar = $state->{runtime}->{status_text};
 clear_ipv6_block_rule('killswitch-on');
 # Backup current rules
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_EXPORTING_RULES};
 _ui_pump();
 my $rt;
 my ($backup_ok, $backup_cmd, $backup_out) = _fw_export_backup();
 if (!$backup_ok) {
  _fw_batch_error(($L->{$lang}{ERR_KILLSWITCH_EXPORT} || 'Failed to export rules') . "\nCommand: $backup_cmd\n$backup_out");
  _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_EXPORT} || 'Failed to export firewall rules');
  $state->{runtime}->{status_text} = $tmpbar;
  _fw_restore_ui_after_killswitch();
  return $fw_done->(0);
 }

 # Clear existing rules
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_CLEARING_EXISTING_RULES};
 _ui_pump();
 &del_fw_rule("all", 1);
 _invalidate_ipv6_block_rule_cache();

 # Set all profiles to block everything in and out
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_BLOCKING_EVERYTHING};
 _ui_pump();
 my ($prof_out, $prof_status);
 ($prof_out, $prof_status) = _run_netsh_cmd('netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound 2>&1', tries => 3);
 _fw_batch_error("Failed to set private firewall profile\nError: $prof_out") unless netsh_success_output($prof_out, $prof_status);
 ($prof_out, $prof_status) = _run_netsh_cmd('netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound 2>&1', tries => 3);
 _fw_batch_error("Failed to set domain firewall profile\nError: $prof_out") unless netsh_success_output($prof_out, $prof_status);
 ($prof_out, $prof_status) = _run_netsh_cmd('netsh advfirewall set publicprofile firewallpolicy blockinbound,blockoutbound 2>&1', tries => 3);
 _fw_batch_error("Failed to set public firewall profile\nError: $prof_out") unless netsh_success_output($prof_out, $prof_status);
 # Disable notifications
 ($prof_out, $prof_status) = _run_netsh_cmd('netsh advfirewall set allprofiles settings inboundusernotification disable 2>&1', tries => 3);
 _fw_batch_error("Failed to disable firewall notifications\nError: $prof_out") unless netsh_success_output($prof_out, $prof_status);

 # Allow DHCP
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_DHCP};
 _ui_pump();
 &add_fw_rule(
  "cryptostorm - Allow DHCP",
  "out",
  q{program="%SystemRoot%\\system32\\svchost.exe" localip=0.0.0.0 localport=68 remoteip=255.255.255.255 remoteport=67 protocol=UDP}
 );

	 # Allow Local Network Access
	 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_ALLOWING_LAN};
	 _ui_pump();
	 &add_fw_rule("cryptostorm - Allow LAN", "in",  "remoteip=LocalSubnet");
	 &add_fw_rule("cryptostorm - Allow LAN", "out", "remoteip=LocalSubnet");

	 # IPv6 needs ICMPv6 neighbor discovery/router control for link-local gateways.
	 if (($state->{security}->{no_ipv6} // 'off') eq 'off') {
	  &add_fw_rule("cryptostorm - Allow IPv6 control", "in",  "protocol=ICMPv6 remoteip=fe80::/10");
	  &add_fw_rule("cryptostorm - Allow IPv6 control", "out", "protocol=ICMPv6 remoteip=fe80::/10");
	  &add_fw_rule("cryptostorm - Allow IPv6 control", "in",  "protocol=ICMPv6 remoteip=ff00::/8");
	  &add_fw_rule("cryptostorm - Allow IPv6 control", "out", "protocol=ICMPv6 remoteip=ff00::/8");
	 }

	 # Allow local control/proxy paths. This does not allow external traffic.
	 # All local transports and OpenVPN management are bound to 127.0.0.1.
	 &add_fw_rule("cryptostorm - Allow loopback", "in",  "remoteip=127.0.0.1");
	 &add_fw_rule("cryptostorm - Allow loopback", "out", "remoteip=127.0.0.1");

	 # Allow programs this client uses
	 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_PROGRAMS};
	 _ui_pump();
	 my @whitelisted_programs = (
	   $state->{app}->{program_files_dir} . '\\client.exe',
	   $state->{app}->{program_files_dir} . '\\csvpn.exe',
	   $state->{app}->{program_files_dir} . '\\cs-https-tun.exe',
	   $state->{app}->{program_files_dir} . '\\cs-ssh-tun.exe',
	   $state->{app}->{program_files_dir} . '\\xray.exe',
	   $^X,
	 );

	 my %seen_program;
	 @whitelisted_programs = grep {
	  defined $_ && length $_ && !$seen_program{lc $_}++
	 } @whitelisted_programs;

 foreach my $program (@whitelisted_programs) {
  &add_fw_rule("cryptostorm - Allow CS programs", "out", qq{program="$program" service=any});
  &add_fw_rule("cryptostorm - Allow CS programs", "in",  qq{program="$program" service=any});
 }

 # Allow cryptostorm.is / .nu
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_STATIC_IPS};
 _ui_pump();
 my $csis_ipv4 = "46.165.221.100";
 my $csis_ipv6 = "2a00:c98:2030:a005:feed:df:c0ff:eeee";
 my $csnu_ipv4 = "46.165.221.67";
 my $csnu_ipv6 = "2a00:c98:2030:a005:c0ff:eeee:eeee:eeee";
 if (($state->{security}->{no_ipv6} // 'off') eq 'on') {
  add_fw_rule("cryptostorm - Allow cryptostorm.is and .nu", "out", "remoteip=$csnu_ipv4,$csis_ipv4");
 }
 else {
  add_fw_rule("cryptostorm - Allow cryptostorm.is and .nu", "out", "remoteip=$csnu_ipv4,$csnu_ipv6,$csis_ipv4,$csis_ipv6");
 }

 # Allow VPN server's internal DNS servers (disabled initially)
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_ADDING_VPN_DNS_RULES};
 _ui_pump();
 if (($state->{security}->{no_ipv6} // 'off') eq 'on') {
  add_fw_rule("cryptostorm - Allow internal VPN DNS", "out", "remoteip=10.31.33.7,10.31.33.8 enable=no");
 }
 else {
  add_fw_rule("cryptostorm - Allow internal VPN DNS", "out", "remoteip=10.31.33.7,10.31.33.8,2001:db8::7,2001:db8::8 enable=no");
 }
 
 # Allow internal VPN IPs (disabled initially, assigned later)
 $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_ADDING_INTERNAL_VPN_IP_RULES};
 _ui_pump();
 add_fw_rule("cryptostorm - Allow internal IPv4 in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 out", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 gateway in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "out", "remoteip=any enable=no");
 if (($state->{security}->{no_ipv6} // 'off') eq 'off') {
  add_fw_rule("cryptostorm - Allow internal IPv6 in", "out", "remoteip=any enable=no");
  add_fw_rule("cryptostorm - Allow internal IPv6 out", "out", "remoteip=any enable=no");
  add_fw_rule("cryptostorm - Allow internal IPv6 gateway in", "out", "remoteip=any enable=no");
  add_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "out", "remoteip=any enable=no");
 }

 _replace_killswitch_endpoint_rules();

 my $fw_ok = _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_FW_ADD} || 'Failed to add firewall rules');

 # Restore UI
 $state->{runtime}->{status_text} = $tmpbar;
 if ($fw_ok) {
  $state->{runtime}->{killswitch_applied} = 'on';
  $state->{runtime}->{killswitch_rule_signature} = _killswitch_rule_signature($state);
  $state->{runtime}->{killswitch_endpoint_rule_signature} = _killswitch_endpoint_signature($state);
 }
 else {
  _restore_firewall_after_killswitch_failure();
 }
 _fw_restore_ui_after_killswitch();
 return $fw_done->($fw_ok);
}

sub toggle_fw_rule {
 my ($rule_name,$toggle) = @_;
 $toggle = $toggle eq "on" ? "yes" : $toggle eq "off" ? "no" : $toggle;
 my $cmd = qq{netsh advfirewall firewall set rule name="$rule_name" new enable=$toggle 2>&1};
 my ($rt, $status) = _run_netsh_cmd($cmd, tries => 3, delay => 0.25);
 if (!netsh_success_output($rt, $status)) {
  _fw_batch_error($L->{$lang}{ERR_KILLSWITCH_FW_TOGGLE} . ": $rule_name
Command: $cmd
" . _cmd_error_text($rt, $status));
  return 0;
 }
 return 1;
}

sub add_fw_rule {
 my ($rule_name, $dir, $extra_args) = @_;
 my $cmd = qq{netsh advfirewall firewall add rule name="$rule_name" dir=$dir action=allow $extra_args 2>&1};
 my ($rt, $status) = _run_netsh_cmd($cmd, tries => 3, delay => 0.25);
 if (!netsh_success_output($rt, $status)) {
  _fw_batch_error($L->{$lang}{ERR_KILLSWITCH_FW_ADD} . ": $rule_name (dir=$dir)
Command: $cmd
" . _cmd_error_text($rt, $status));
  return 0;
 }
 return 1;
}

sub del_fw_rule {
 my ($rule_name, $ignore_errors) = @_;
 my $cmd = qq{netsh advfirewall firewall del rule name="$rule_name" 2>&1};
 my ($rt, $status) = _run_netsh_cmd($cmd, tries => 3, delay => 0.25);
 return 1 if $rt =~ /No rules match/i;
 if (!netsh_success_output($rt, $status)) {
  return 1 if $ignore_errors;
  _fw_batch_error($L->{$lang}{ERR_KILLSWITCH_FW_DEL} . ": $rule_name
Command: $cmd
" . _cmd_error_text($rt, $status));
  return 0;
 }
 return 1;
}

sub killswitch_off {
 return 0 if $state->{runtime}->{firewall_update_active};
 $state->{runtime}->{firewall_update_active} = 1;
 my $fw_done = sub { delete $state->{runtime}->{firewall_update_active}; return $_[0]; };

 my $tmpbar = $state->{runtime}->{status_text};
 _fw_set_ui_locked(1);
 _fw_batch_start();
 my $rt;

 my $backup_path = _fw_backup_path();
 if (-e $backup_path) {
  my ($import_ok, $import_cmd, $import_out) = _fw_import_backup(delete_on_success => 1);
  if (!$import_ok) {
   _fw_batch_error(($L->{$lang}{ERR_KILLSWITCH_FW_DEL} || 'Failed to update firewall rules') . "\nCommand: $import_cmd\n$import_out");
   my $fw_ok = _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_FW_DEL} || 'Failed to update firewall rules');
   $state->{runtime}->{status_text} = $tmpbar;
   _fw_restore_ui_after_killswitch();
   return $fw_done->($fw_ok);
  }

  $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_IMPORTED_PREVIOUS_RULES};
  _invalidate_ipv6_block_rule_cache();
  _ui_pump();
 }
 else {
  # No backup exists.  This can happen after a previous failed import, manual
  # cleanup, or a stale config value.  In that case do not attempt an import;
  # just remove our rules and put the standard profile policy back.
  $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow DHCP" 2>&1`;
  $rt = '' unless defined $rt;
  if ($rt =~ /cryptostorm/i) {
   $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_IS_ENABLED_DISABLING};
   _ui_pump();
   for my $rule (_killswitch_rule_names()) {
    del_fw_rule($rule, 1);
   }
   $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_RULES_DELETED};
   _ui_pump();
  }

  my ($restore_out, $restore_status) = _run_netsh_cmd('netsh advfirewall set allprofiles settings inboundusernotification enable 2>&1', tries => 3);
  _fw_batch_error("Failed to enable firewall notifications\nError: $restore_out") unless netsh_success_output($restore_out, $restore_status);
  $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_FW_NOTIFICATIONS_ENABLED};
  _ui_pump();
  ($restore_out, $restore_status) = _run_netsh_cmd('netsh advfirewall set allprofiles firewallpolicy BlockInbound,AllowOutbound 2>&1', tries => 3);
  _fw_batch_error("Failed to restore firewall profile policies\nError: $restore_out") unless netsh_success_output($restore_out, $restore_status);
  $state->{runtime}->{status_text} = $L->{$lang}{TXT_KILLSWITCH_FW_PROFILE_POLICIES_RESTORED};
  _ui_pump();
 }

 my $fw_ok = _fw_batch_finish($L->{$lang}{ERR_KILLSWITCH_FW_DEL} || 'Failed to delete firewall rules');
 $state->{runtime}->{status_text} = $tmpbar;
 if ($fw_ok) {
  $state->{runtime}->{killswitch_applied} = 'off';
  $state->{runtime}->{killswitch_rule_signature} = _killswitch_rule_signature($state);
  delete $state->{runtime}->{killswitch_endpoint_rule_signature};

  # The standalone IPv6 leak block is only used while connected without the
  # full killswitch.  If a previous import restored it, remove it now.
  clear_ipv6_block_rule('killswitch-off');
 }
 _fw_restore_ui_after_killswitch();
 return $fw_done->($fw_ok);
}

sub isoncs {
    return 0 unless defined $state->{connect}->{manport}
                 && defined $state->{connect}->{manpass};

    return 0 if (($state->{runtime}->{exit_btn_mode} // '') eq 'exit');

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $state->{connect}->{manport},
        Proto    => 'tcp',
        Timeout  => 1,
    ) or return 0;

    $sock->autoflush(1);

    print $sock "$state->{connect}->{manpass}\r\n";

    my $is_connected = 0;
    my $authorized   = 0;

    while (my $line = <$sock>) {
        print STDERR "[isoncs] line=$line" if $ENV{CS_DEBUG_ISONCS};

        if ($line =~ /INFO:OpenVPN Management Interface Version/i) {
            $authorized = 1;
            last;
        }

        # Some management builds may not emit the exact line expected.
        last if $line =~ /^ERROR:/i;
    }

    if ($authorized) {
        print $sock "state\r\n";

        while (my $resp = <$sock>) {
            print STDERR "[isoncs] resp=$resp" if $ENV{CS_DEBUG_ISONCS};

            if ($resp =~ /\bCONNECTED\b/i) {
                $is_connected = 1;
                last;
            }

            last if $resp =~ /^END\b/i;
            last if $resp =~ /^SUCCESS:/i;
            last if $resp =~ /^ERROR:/i;
        }
    }

    eval { print $sock "exit\r\n"; };
    close($sock);

    return $is_connected;
}


sub canonical_tls_cipher {
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

sub tls_cipher_fixed_port {
    my ($tls) = @_;
    $tls = canonical_tls_cipher($tls);

    return 5061 if $tls eq 'Ed25519';
    return 5062 if $tls eq 'Ed448';
    return 5063 if $tls eq 'ML-DSA-87';
    return undef;
}

sub tls_profile_reserved_port {
    my ($port) = @_;
    return 0 unless defined $port && $port =~ /^\d+$/;
    return $port == 5061 || $port == 5062 || $port == 5063 || $port == 8443;
}

sub tls_default_secp_port {
    return 443;
}

sub windows_firewall_service_running {
    my @services = qw(MpsSvc SharedAccess);

    for my $svc (@services) {
        my %status;
        next unless eval { Win32::Service::GetStatus('', $svc, \%status) };
        return 1 if (($status{CurrentState} || 0) == 4); # SERVICE_RUNNING
    }

    # Fallback for odd service-query failures/localization.  "netsh advfirewall
    # show allprofiles" returns exit code 0 only when the advfirewall stack is usable.
    my $out = `netsh advfirewall show allprofiles 2>&1`;
    return ($? == 0) ? 1 : 0;
}

sub start_windows_firewall_service {
    my $out = `net start MpsSvc 2>&1`;
    return 1 if $? == 0;
    return 1 if defined($out) && $out =~ /already been started|already running|is already/i;

    $out = `net start SharedAccess 2>&1`;
    return 1 if $? == 0;
    return 1 if defined($out) && $out =~ /already been started|already running|is already/i;

    return 0;
}

sub netsh_success_output {
    my ($out, $status) = @_;
    $out = '' unless defined $out;
    return 1 if defined($status) && $status == 0;
    return 1 if $out =~ /\bOk\.?\b/i;
    return 1 if $out =~ /The command.*completed successfully/i;
    return 0;
}

sub confgen {
    my (%args) = @_;

    my $state  = $args{state}  or die "confgen: missing state";
    my $ui     = $args{ui}     or die "confgen: missing ui";
    my $L      = $args{L}      or die "confgen: missing L";
    my $launch = $args{launch} || {};

    my $remote_addr = $state->{connect}->{remote_addr}
        or die "confgen: missing remote_addr";

    my $remote_port = $state->{connect}->{port}
        or die "confgen: missing remote port";

    my $https_transport_on = (($state->{transport}->{https_enabled} // 'off') eq 'on');
    my $https_mode = $state->{transport}->{https_mode} // 'stunnel';
    my $https_forces_secp = $https_transport_on
        && (($state->{transport}->{ssh_enabled} // 'off') ne 'on')
        && (
               (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')
            || (($state->{transport}->{xray_enabled}    // 'off') eq 'on')
            || ($https_mode =~ /^(?:stunnel|xray)$/)
        );

    my $tls_cipher = canonical_tls_cipher($state->{connect}->{tls_cipher});

    if ($https_forces_secp) {
        $tls_cipher = 'secp521r1';
        $state->{connect}->{tls_cipher} = $tls_cipher;
        # Do not rewrite the selected remote port for stunnel/Xray. Server-side
        # HTTPS tunnel routing currently forwards to the secp521r1 OpenVPN
        # profile; the port remains whatever the user selected.
    }
    else {
        $state->{connect}->{tls_cipher} = $tls_cipher;
        if (my $forced_tls_port = tls_cipher_fixed_port($tls_cipher)) {
            $remote_port = $forced_tls_port;
            $state->{connect}->{port} = $forced_tls_port;
        }
    }

    my $effective_remote_addr = $remote_addr;
    my $effective_remote_port = $remote_port;

    # Local HTTPS transports should use the same endpoint family selected for
    # OpenVPN.  Prefer IPv6 when the host has working IPv6 routing so the user
    # gets the full IPv4+IPv6 tunnel profile; fall back to IPv4 when Disable
    # IPv6 is enabled or no usable IPv6 route exists.  The helper endpoint gets
    # a temporary bypass route before OpenVPN installs the VPN default route.
    ensure_local_tunnel_bypass_route($remote_addr) if $https_transport_on;

    if ($https_transport_on && (($state->{transport}->{stunnel_enabled} // 'off') eq 'on')) {
        my $tun = write_stunnel_config(
            state => $state,
            ui    => $ui,
            L     => $L,

            remote_addr => $remote_addr,
            remote_port => $remote_port,

            get_next_free_local_port => \&get_next_free_local_port,
            is_tunnel_up             => \&is_tunnel_up,
            do_error                 => \&do_error,
            stunnel_exe              => $state->{app}->{program_files_dir} . '\\cs-https-tun.exe',
        );

        $effective_remote_addr = $tun->{local_addr};
        $effective_remote_port = $tun->{local_port};
    }
    elsif ($https_transport_on && (($state->{transport}->{xray_enabled} // 'off') eq 'on')) {
        my $tun = write_xray_config(
            state => $state,
            ui    => $ui,
            L     => $L,

            remote_addr => $remote_addr,
            remote_port => $remote_port,

            get_next_free_local_port => \&get_next_free_local_port,
            is_tunnel_up             => \&is_tunnel_up,
            do_error                 => \&do_error,
            xray_exe                 => $state->{app}->{program_files_dir} . '\\xray.exe',
        );

        $effective_remote_addr = $tun->{local_addr};
        $effective_remote_port = $tun->{local_port};
    }

    if (!$https_transport_on && (($state->{transport}->{ssh_enabled} // 'off') ne 'on')) {
        delete $state->{transport}->{local_tunnel_port};
        if (($effective_remote_addr // '') eq '127.0.0.1' || ($effective_remote_addr // '') eq '::1') {
            die "confgen: local tunnel address selected while all tunnels are disabled";
        }
    }

    write_openvpn_config(
        state => $state,
        ui    => $ui,
        L     => $L,

        launch => $launch,

        remote_addr => $effective_remote_addr,
        remote_port => $effective_remote_port,

        ovpn_path => '..\\\user\\\vpn.ovpn',
        log_path  => '..\\\bin\\\openvpn.log',
        auth_path => '..\\\user\\\client.dat',

        get_next_free_local_port => \&get_next_free_local_port,
    );

    return $launch->{config_path} || '..\\user\\vpn.ovpn';
}

sub reset_dns_to_dhcp_btn_cmd {
    my ($state, $ui, $Registry, $recover_ref) = @_;

    my $btn = $ui->{opt_advanced}->{reset_dns_to_dhcp_btn};
    $btn->configure(-state => "disabled") if $btn;

    my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};

    foreach (keys %$interfaces) {
        my $guid = $_;
        next if $guid =~ /NameServer/;
        $guid =~ s/\/$//;

        $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$guid/NameServer"} = "";
    }

    system(1, "ipconfig /registerdns >NUL 2>NUL");

    if (-e "..\\user\\mydns.txt") {
        unlink("..\\user\\mydns.txt");
    }

    @$recover_ref = () if $recover_ref;

    $btn->configure(-state => "normal") if $btn;

    Tkx::tk___messageBox(
        -parent  => $ui->{opt_main}->{ow},
        -type    => "ok",
        -message => "DNS for all network adapters has been set to DHCP",
        -icon    => "info",
        -title   => "cryptostorm.is client",
    );
}

sub local_port_is_free {
    my ($port) = @_;

    return 0 unless defined $port;
    return 0 unless $port =~ /^\d+$/;
    return 0 if $port < 1 || $port > 65535;

    my $tcp = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 0,
    );

    return 0 unless $tcp;
    close($tcp);

    # Xray binds both TCP and UDP on the same local port.  The old probe only
    # checked TCP, so a UDP-only conflict could make Xray exit immediately with
    # little/no useful output.  Requiring both to be free is harmless for SSH and
    # stunnel, and prevents those intermittent first-attempt failures.
    my $udp = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Proto     => 'udp',
        ReuseAddr => 0,
    );

    return 0 unless $udp;
    close($udp);

    return $port;
}

sub local_tcp_listener_ready {
    my ($port) = @_;

    return 0 unless defined $port && $port =~ /^\d+$/ && $port > 0;

    # Prefer a passive LISTENING check for stunnel/Xray.  Actively connecting
    # to a local tunnel can trigger an outbound remote attempt while the
    # killswitch rules are still settling, which can make a healthy listener
    # look like a startup failure on slower Win7 systems.
    my $needle1 = quotemeta("127.0.0.1:$port");
    my $needle2 = quotemeta("0.0.0.0:$port");
    my $out = `netstat -na -p TCP 2>NUL`;
    $out = '' unless defined $out;

    for my $line (split(/\r?\n/, $out)) {
        return 1 if $line =~ /\bTCP\s+$needle1\s+\S+\s+LISTENING\b/i;
        return 1 if $line =~ /\bTCP\s+$needle2\s+\S+\s+LISTENING\b/i;
    }

    return 0;
}

sub is_tunnel_up {
    my ($port, $timeout_ms) = @_;

    $timeout_ms ||= 7000;

    my $deadline = time + ($timeout_ms / 1000);

    while (time < $deadline) {
        return 1 if local_tcp_listener_ready($port);

        # Do not actively connect to the helper here.  A probe connection makes
        # stunnel/Xray immediately dial the remote endpoint, which can look like
        # a startup failure if the killswitch endpoint rule is still settling.
        eval { _ui_pump(); };
        select undef, undef, undef, 0.10;
    }

    return -1;
}

sub is_valid_ip {
 my $ip = shift;
 # Try IPv4
 return 1 if $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
             !grep { $_ > 255 } ($1, $2, $3, $4);
 # Try IPv6 (colon-separated, at least one colon required)
 return 1 if $ip =~ /:/ && Socket::inet_pton(AF_INET6, $ip);
 return 0;
}

sub _default_ipv4_gateway {
    my $routes = `route print -4 2>NUL`;
    return '' unless defined $routes && length $routes;

    my $active = 0;
    for my $line (split(/\r?\n/, $routes)) {
        $active = 1 if $line =~ /^\s*Active Routes:/i;
        last if $line =~ /^\s*Persistent Routes:/i;
        next unless $active;

        if ($line =~ /^\s*0\.0\.0\.0\s+0\.0\.0\.0\s+(\S+)\s+(\S+)\s+\d+\s*$/) {
            my ($gw, $iface) = ($1, $2);
            next if $gw =~ /^(?:0\.0\.0\.0|127\.|On-link)$/i;
            next if $iface =~ /^127\./;
            return $gw;
        }
    }

    return '';
}

sub _default_ipv6_gateway {
    my $routes = `route -6 print 2>NUL`;
    return unless defined $routes && length $routes;

    my $active = 0;
    for my $line (split(/\r?\n/, $routes)) {
        $active = 1 if $line =~ /^\s*Active Routes:/i;
        last if $line =~ /^\s*Persistent Routes:/i;
        next unless $active;

        if ($line =~ /^\s*(\d+)\s+\d+\s+::\/0\s+(\S+)\s*$/i) {
            my ($ifidx, $gw) = ($1, $2);
            next if $gw =~ /^(?:On-link|::|::1)$/i;
            return ($gw, $ifidx);
        }
    }

    return;
}

sub ensure_local_tunnel_bypass_route {
    my ($addr) = @_;

    return 1 unless defined $addr && length $addr;
    return 1 unless is_valid_ip($addr);

    if ($addr =~ /:/) {
        return 1 if $addr =~ /^(?:::|::1)$/i;
        return 1 if (($state->{security}->{no_ipv6} // 'off') eq 'on');

        my ($gw, $ifidx) = _default_ipv6_gateway();
        return 1 unless defined $gw && length $gw && defined $ifidx && length $ifidx;

        my $routes = $state->{runtime}->{local_tunnel_bypass_ipv6_routes} ||= {};
        return 1 if $routes->{$addr};

        my $cmd = qq(route -6 ADD $addr/128 $gw IF $ifidx METRIC 1 2>&1);
        my $out = `$cmd`;
        $out = '' unless defined $out;

        if ($? == 0 || $out =~ /(?:OK|The object already exists|already exists)/i) {
            $routes->{$addr} = { gateway => $gw, ifidx => $ifidx };
            return 1;
        }

        my $cmd2 = qq(netsh interface ipv6 add route $addr/128 $ifidx $gw store=active 2>&1);
        my $out2 = `$cmd2`;
        $out2 = '' unless defined $out2;

        if ($? == 0 || $out2 =~ /(?:OK|The object already exists|already exists)/i) {
            $routes->{$addr} = { gateway => $gw, ifidx => $ifidx };
            return 1;
        }

        $state->{runtime}->{last_tunnel_route_error} = "Command: $cmd\n$out\nCommand: $cmd2\n$out2";
        return 1;
    }

    return 1 if $addr =~ /^(?:0\.0\.0\.0|127\.)/;

    my $gw = _default_ipv4_gateway();
    return 1 unless length $gw;

    my $routes = $state->{runtime}->{local_tunnel_bypass_ipv4_routes} ||= {};
    return 1 if $routes->{$addr};

    my $cmd = qq(route ADD $addr MASK 255.255.255.255 $gw METRIC 1 2>&1);
    my $out = `$cmd`;
    $out = '' unless defined $out;

    if ($? == 0 || $out =~ /(?:OK|The object already exists|already exists)/i) {
        $routes->{$addr} = $gw;
        return 1;
    }

    # Do not fail tunnel startup just because a best-effort route could not be
    # added.  The generated OpenVPN config also contains an IPv4 net_gateway
    # bypass route.  Save details so a later tunnel error can include them.
    $state->{runtime}->{last_tunnel_route_error} = "Command: $cmd\n$out";
    return 1;
}

sub cleanup_local_tunnel_bypass_routes {
    my $routes4 = delete $state->{runtime}->{local_tunnel_bypass_ipv4_routes};

    if ($routes4 && ref($routes4) eq 'HASH') {
        for my $addr (keys %$routes4) {
            next unless defined $addr && $addr =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
            system(1, qq(route DELETE $addr >NUL 2>NUL));
        }
    }

    my $routes6 = delete $state->{runtime}->{local_tunnel_bypass_ipv6_routes};

    if ($routes6 && ref($routes6) eq 'HASH') {
        for my $addr (keys %$routes6) {
            next unless defined $addr && $addr =~ /:/;
            my $entry = $routes6->{$addr};
            my $ifidx = (ref($entry) eq 'HASH') ? ($entry->{ifidx} // '') : '';
            my $gw    = (ref($entry) eq 'HASH') ? ($entry->{gateway} // '') : '';
            system(1, qq(route -6 DELETE $addr/128 >NUL 2>NUL));
            system(1, qq(netsh interface ipv6 delete route $addr/128 $ifidx $gw store=active >NUL 2>NUL))
                if length $ifidx && length $gw;
        }
    }

    return 1;
}

sub host_has_usable_ipv6_route {
    my ($state, %opts) = @_;

    return 0 if !$opts{ignore_disable_ipv6}
             && (($state->{security}->{no_ipv6} // 'off') eq 'on');

    my $routes = `route -6 print 2>NUL`;
    return 0 unless defined $routes && length $routes;

    my $active = 0;

    for my $line (split(/\r?\n/, $routes)) {
        $active = 1 if $line =~ /^\s*Active Routes:/i;
        last if $line =~ /^\s*Persistent Routes:/i;
        next unless $active;

        return 1 if $line =~ /^\s*\d+\s+\d+\s+::\/0\s+/;
        return 1 if $line =~ /^\s*\d+\s+\d+\s+2000::\/3\s+/i;
    }

    return 0;
}

sub host_has_usable_ipv4_route {
    my $routes = `route print -4 2>NUL`;
    return 0 unless defined $routes && length $routes;

    my $active = 0;

    for my $line (split(/\r?\n/, $routes)) {
        $active = 1 if $line =~ /^\s*Active Routes:/i;
        last if $line =~ /^\s*Persistent Routes:/i;
        next unless $active;

        return 1 if $line =~ /^\s*0\.0\.0\.0\s+0\.0\.0\.0\s+\S+\s+(?!127\.0\.0\.1\b)\S+\s+\d+\s*$/;
    }

    return 0;
}

sub refresh_ui_from_state {
    my ($state, $ui) = @_;

    return unless $state->{runtime}->{ui_ready};

    my $socks      = ($state->{transport}->{socks_enabled}   // 'off') eq 'on';
    my $ssh        = ($state->{transport}->{ssh_enabled}     // 'off') eq 'on';
    my $https      = ($state->{transport}->{https_enabled}   // 'off') eq 'on';
    my $https_mode = $state->{transport}->{https_mode} // 'stunnel';
    my $noauth     = ($state->{transport}->{socks_noauth}    // 'on')  eq 'on';
    my $tls        = canonical_tls_cipher($state->{connect}->{tls_cipher} // 'secp521r1');

    $https_mode = 'stunnel' unless $https_mode =~ /^(stunnel|xray)$/;
    $state->{transport}->{https_mode} = $https_mode;

    normalize_sni_for_https_mode($state);

    # derive these from https_enabled + https_mode
    $state->{transport}->{stunnel_enabled} = ($https && $https_mode eq 'stunnel') ? 'on' : 'off';
    $state->{transport}->{xray_enabled}    = ($https && $https_mode eq 'xray')    ? 'on' : 'off';

    my $stunnel = $state->{transport}->{stunnel_enabled} eq 'on';
    my $xray    = $state->{transport}->{xray_enabled} eq 'on';

    if ($stunnel || $xray) {
        $tls = 'secp521r1';
        $state->{connect}->{tls_cipher} = $tls;
    }
    else {
        $state->{connect}->{tls_cipher} = $tls;
    }

    my $force_tcp = $socks || $ssh || $stunnel;

    # Preserve whether proto was UDP before we force it to TCP,
    # so it can be restored once forced-TCP conditions go away.
    my $current_proto = $state->{connect}->{proto} // '';

    if ($force_tcp) {
        if ($current_proto eq 'UDP') {
            $state->{connect}->{proto_before_forced_tcp} = 'UDP';
        }
        $state->{connect}->{proto} = 'TCP';
    }
    else {
        if (($state->{connect}->{proto_before_forced_tcp} // '') eq 'UDP') {
            $state->{connect}->{proto} = 'UDP';
            delete $state->{connect}->{proto_before_forced_tcp};
        }
        elsif (($state->{connect}->{proto} // '') ne 'UDP' && ($state->{connect}->{proto} // '') ne 'TCP') {
            $state->{connect}->{proto} = 'UDP';
        }
    }

    safe_configure(
        $ui->{opt_connecting}->{proto_combo},
        -values => $force_tcp ? ['TCP'] : ['UDP', 'TCP'],
        -state  => $force_tcp ? 'disabled' : 'readonly',
    );

    my $socks_basic_state = $socks ? 'normal' : 'disabled';
    my $socks_auth_state  = ($socks && !$noauth) ? 'normal' : 'disabled';

    for my $w (
        $ui->{opt_advanced}->{socks_ip_lbl},
        $ui->{opt_advanced}->{socks_ip_entry},
        $ui->{opt_advanced}->{socks_port_lbl},
        $ui->{opt_advanced}->{socks_port_entry},
        $ui->{opt_advanced}->{socks_noauth_check},
    ) {
        safe_configure($w, -state => $socks_basic_state);
    }

    for my $w (
        $ui->{opt_advanced}->{socks_user_lbl},
        $ui->{opt_advanced}->{socks_user_entry},
        $ui->{opt_advanced}->{socks_pass_lbl},
        $ui->{opt_advanced}->{socks_pass_entry},
    ) {
        safe_configure($w, -state => $socks_auth_state);
    }

    safe_configure($ui->{opt_advanced}->{socks_check},   -state => ($ssh || $https) ? 'disabled' : 'normal');
    safe_configure($ui->{opt_advanced}->{ssh_check},     -state => ($socks || $https) ? 'disabled' : 'normal');
    safe_configure($ui->{opt_advanced}->{https_check},   -state => ($socks || $ssh) ? 'disabled' : 'normal');
    safe_configure($ui->{opt_advanced}->{stunnel_radio}, -state => $https ? 'normal' : 'disabled');
    safe_configure($ui->{opt_advanced}->{xray_radio},    -state => $https ? 'normal' : 'disabled');

    if ($https) {
        safe_grid($ui->{opt_advanced}->{stunnel_radio}, -column => 2, -row => 8, -sticky => 'w');
        safe_grid($ui->{opt_advanced}->{xray_radio},    -column => 3, -row => 8, -sticky => 'w');

        safe_configure($ui->{opt_advanced}->{tunnel_lbl}, -state => 'normal', -text => ' SNI host:  ');

        safe_grid_remove($ui->{opt_advanced}->{ssh_tunnel_combo});

        if ($stunnel) {
            safe_grid_remove($ui->{opt_advanced}->{xray_sni_combo});
            safe_grid($ui->{opt_advanced}->{sni_entry}, -column => 1, -row => 9);
        }
        elsif ($xray) {
            safe_grid_remove($ui->{opt_advanced}->{sni_entry});
            safe_grid($ui->{opt_advanced}->{xray_sni_combo}, -column => 1, -row => 9);
        }
    }
    elsif ($ssh) {
        safe_grid_remove($ui->{opt_advanced}->{stunnel_radio});
        safe_grid_remove($ui->{opt_advanced}->{xray_radio});
        safe_grid_remove($ui->{opt_advanced}->{sni_entry});
        safe_grid_remove($ui->{opt_advanced}->{xray_sni_combo});

        safe_configure($ui->{opt_advanced}->{tunnel_lbl}, -state => 'normal', -text => 'Tunnel host:');
        safe_grid($ui->{opt_advanced}->{ssh_tunnel_combo}, -column => 1, -row => 9);
        safe_configure($ui->{opt_advanced}->{ssh_tunnel_combo}, -state => 'readonly');
    }
    else {
        safe_grid_remove($ui->{opt_advanced}->{stunnel_radio});
        safe_grid_remove($ui->{opt_advanced}->{xray_radio});
        safe_grid_remove($ui->{opt_advanced}->{sni_entry});
        safe_grid_remove($ui->{opt_advanced}->{xray_sni_combo});

        safe_configure($ui->{opt_advanced}->{tunnel_lbl}, -state => 'disabled', -text => 'Tunnel host:');
        safe_grid($ui->{opt_advanced}->{ssh_tunnel_combo}, -column => 1, -row => 9);
        safe_configure($ui->{opt_advanced}->{ssh_tunnel_combo}, -state => 'disabled');
    }

    safe_configure(
        $ui->{opt_security}->{tls_cipher_combo},
        -values => ['secp521r1','Ed25519','Ed448','ML-DSA-87'],
        -state  => ($stunnel || $xray) ? 'disabled' : 'readonly',
    );

    if (!$stunnel && !$xray && $tls eq 'Ed25519') {
        $state->{connect}->{port} = 5061;
        safe_configure($ui->{opt_connecting}->{port_entry}, -state => 'disabled');
        safe_configure($ui->{opt_connecting}->{random_port_check}, -state => 'disabled');
    }
    elsif (!$stunnel && !$xray && $tls eq 'Ed448') {
        $state->{connect}->{port} = 5062;
        safe_configure($ui->{opt_connecting}->{port_entry}, -state => 'disabled');
        safe_configure($ui->{opt_connecting}->{random_port_check}, -state => 'disabled');
    }
    elsif (!$stunnel && !$xray && $tls eq 'ML-DSA-87') {
        $state->{connect}->{port} = 5063;
        safe_configure($ui->{opt_connecting}->{port_entry}, -state => 'disabled');
        safe_configure($ui->{opt_connecting}->{random_port_check}, -state => 'disabled');
    }
    else {
        if (($state->{connect}->{random_port} // 'off') eq 'on') {
            my $p = int(rand(65534) + 1);
            while (tls_profile_reserved_port($p)) {
                $p = int(rand(65534) + 1);
            }
            $state->{connect}->{port} = $p;
        }
        elsif (($state->{connect}->{port} // '') !~ /^\d+$/
            || ($tls eq 'secp521r1' && tls_profile_reserved_port($state->{connect}->{port}))) {
            $state->{connect}->{port} = tls_default_secp_port();
        }

        safe_configure($ui->{opt_connecting}->{port_entry}, -state => 'normal');
        safe_configure($ui->{opt_connecting}->{random_port_check}, -state => 'normal');
    }

    # Transport toggles can add/remove the wider stunnel/Xray controls on the
    # Advanced tab while Options is already open, so resize the notebook again
    # after refreshing widget visibility/state.
    autosize_options_window();

    # Main window status label refresh happens automatically through textvariable,
    # but forcing an update here helps during event bursts.
    eval { _ui_pump(); 1 };
}

sub widget_exists {
    my ($w) = @_;
    return 0 unless defined $w;
    return 0 unless blessed($w);
    return eval { Tkx::winfo('exists', $w) ? 1 : 0 } || 0;
}

sub safe_configure {
    my ($w, %args) = @_;
    return unless widget_exists($w);
    eval { $w->configure(%args); 1 } or warn "configure failed: $@";
}

sub safe_grid {
    my ($w, %args) = @_;
    return unless widget_exists($w);
    eval { $w->g_grid(%args); 1 } or warn "grid failed: $@";
}

sub safe_grid_remove {
    my ($w) = @_;
    return unless widget_exists($w);
    eval { Tkx::grid_remove($w); 1 } or warn "grid_remove failed: $@";
}

sub set_status_text {
    my ($state, $text) = @_;
    $state->{runtime}->{status_text} = $text;
}

sub append_log_line {
    my ($ui, $line, $tag) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    $line = '' unless defined $line;
    $line =~ s/\r?\n+\z//;
    $line =~ s/[\r\n]+/ /g;

    my $follow = exists $state->{runtime}->{log_follow}
        ? $state->{runtime}->{log_follow}
        : 1;

    eval {
        $logbox->configure(-state => 'normal');

        if (defined $tag && length $tag) {
            $logbox->insert('end', $line, $tag);
            $logbox->insert('end', "\n");
        }
        else {
            $logbox->insert('end', $line . "\n");
        }

        $logbox->configure(-state => 'disabled');

        if ($follow) {
            _ui_pump();
            $logbox->see('end');
            $logbox->yview('moveto', 1);
        }

        1;
    } or do {
        warn "append_log_line failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub is_xray_sni {
    my ($state, $host) = @_;
    return 0 unless defined $host;

    return exists $state->{transport}->{xray_snis}->{ lc $host };
}

sub normalize_sni_for_https_mode {
    my ($state) = @_;

    my $mode = $state->{transport}->{https_mode} // 'stunnel';
    my $host = $state->{transport}->{sni_host} // '';

    if ($mode eq 'xray') {
        unless (is_xray_sni($state, $host)) {
            my $first_sni = $state->{transport}->{xray_snis_order}->[0];
            $state->{transport}->{sni_host} = $first_sni if defined $first_sni;
        }
    }
    else {
        if (is_xray_sni($state, $host)) {
            $state->{transport}->{sni_host} = 'www.yahoo.com';
        }
    }
}

sub load_lang_compat {
    my $file = shift;
    open my $fh, "<:encoding(UTF-8)", $file or die $!;

    my %lang;
    my $key;

    while (<$fh>) {
        chomp;
        next if /^\s*$/ || /^\s*[#;]/;

        if (/^\S+/ && !/=/
        ) {
            ($key) = split;
        }
        elsif (/^\s{2}(.+?)\s*=\s*(.+)$/ && defined $key) {
            my ($langname, $val) = ($1, $2);
            $langname =~ s/^\s+//;
            $langname =~ s/\s+$//;
            $lang{$langname}{$key} = $val;
        }
    }

    close $fh;
    return \%lang;
}

sub start_openvpn_log_poller {
    return if $openvpn_log_poll_scheduled;
    $openvpn_log_poll_scheduled = 1;

    my $attempt_id = $state->{runtime}->{connect_attempt_id} // 0;

    if (($state->{runtime}->{mgmt_watch_attempt_id} // -1) != $attempt_id) {
        $state->{runtime}->{mgmt_watch_attempt_id} = $attempt_id;

        start_management_success_watcher(
            state      => $state,
            attempt_id => $attempt_id,
            on_connected => sub {
                return mark_openvpn_connected(
                    source     => 'management',
                    attempt_id => $attempt_id,
                );
            },
        );
    }

    Tkx::after(50, sub { poll_openvpn_log() });
}

sub poll_openvpn_log {
    eval {
        poll_openvpn_log_file();

        watch_logbox(
            state                      => $state,
            ui                         => $ui,
            L                          => $L,
            Registry                   => $Registry,
            do_error                   => \&do_error,
            shutdown_openvpn           => \&shutdown_openvpn,
            save_config                => \&save_config,
            toggle_fw_rule             => \&toggle_fw_rule,
            update_node_list           => \&update_node_list,
            hidewin                    => \&hidewin,
            append_log_line            => \&append_log_line,
			delete_logbox_text_line    => \&delete_logbox_text_line,
			stop_world_icon_spinner    => \&stop_world_icon_spinner,
			delete_logbox_status_lines => \&delete_logbox_status_lines,
            append_log_status_line     => \&append_log_status_line,
			on_openvpn_connected => sub {
    			my (%a) = @_;

    			return mark_openvpn_connected(
        			%a,
        			source     => $a{source} || 'log',
        			attempt_id => $a{attempt_id} // ($state->{runtime}->{connect_attempt_id} // 0),
    			);
			},
			start_post_connect_checks => sub {
    			my ($attempt_id) = @_;

    			$attempt_id //= $state->{runtime}->{connect_attempt_id} // 0;

    			start_post_connect_checks(
        			state => $state,
        			on_done => sub {
            			my ($result) = @_;

            			return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
            			return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'disconnect');

            			if ($result && ($result->{upgrade} // 0)) {
                			maybe_prompt_for_update();
            			}

            			# Only set Connected if we are still actually connected.
            			$state->{runtime}->{status_text} =
                			$L->{$state->{app}->{lang}}{TXT_CONNECTED};
        			},
    			);
			},
        );

        1;
    } or do {
        my $err = $@ || 'unknown OpenVPN log poll error';
        warn "poll_openvpn_log: $err\n";
    };

    if (!($state->{runtime}->{stop} // 0)) {
        Tkx::after(50, sub { poll_openvpn_log() });
    }
    else {
        $openvpn_log_poll_scheduled = 0;
    }
}

sub poll_openvpn_log_file {
    my $log_path = $state->{runtime}->{openvpn_log_path} || '..\\bin\\openvpn.log';
    return unless -e $log_path;

    my $lastpos = $state->{runtime}->{openvpn_log_pos} || 0;

    open my $logfh, '<', $log_path or return;

    seek($logfh, $lastpos, 0);

    while (my $line = <$logfh>) {
        my $pos_after = tell($logfh);

        # Do not consume an incomplete final line. OpenVPN on Windows can flush
        # oddly, especially through local TCP transports.
        if ($line !~ /\n\z/) {
            last;
        }

        $lastpos = $pos_after;

        $line =~ s/\r?\n\z//;
        $line =~ s/^[0-9\.]+ [0-9a-f]+ //;

        next if $line =~ /UDPv[46]\s+(READ|WRITE)/;
        next if $line =~ /TUN\s+(READ|WRITE)/;
        next if $line =~ /windows-driver/;
        next if $line =~ /edirect-gateway and redirect-private/;
        next if $line =~ /PID_ERR replay/;
        next if $line =~ /Assertion failed/;
        next if $line =~ /CreateFile failed/;
        next if $line =~ /sending exit notification to peer/;
        next if $line =~ /\-\-mute/;
        next if $line =~ /mode = /;
        next if $line =~ /config =/;
        next if $line =~ /Current Parameter Settings/;
        next if $line =~ /MTU parms/;
        next if $line =~ /MANAGEMENT/;
        next if $line =~ /msg_channel=/;
        next if $line =~ /Epoch Data/;

        push @{ $state->{runtime}->{log_lines} }, $line;
    }

    close $logfh;

    $state->{runtime}->{openvpn_log_pos} = $lastpos;
	
	print STDERR "[log-poll] queued=" . scalar(@{ $state->{runtime}->{log_lines} || [] })
    . " pos=" . ($state->{runtime}->{openvpn_log_pos} || 0)
    . "\n" if $ENV{CS_DEBUG_LOGPOLL};
}

sub update_selected_remote_endpoints {
    my ($state, $servers, $default_server_label) = @_;

    my $selected = $state->{connect}->{server_display} // $default_server_label;
    my $can_ipv4 = host_has_usable_ipv4_route();
    my $has_ipv6_route = host_has_usable_ipv6_route($state, ignore_disable_ipv6 => 1);
    my $prefer_ipv6 =
           ((($state->{security}->{no_ipv6} // 'off') eq 'off') && $has_ipv6_route)
        || (!$can_ipv4 && (($state->{security}->{no_ipv6} // 'off') eq 'off') && $has_ipv6_route);

    # Disable IPv6 is authoritative. Do not let a still-present system IPv6
    # default route make local tunnel helpers or OpenVPN pick an IPv6 endpoint
    # while the killswitch is intentionally blocking IPv6.
    if (($state->{security}->{no_ipv6} // 'off') eq 'on') {
        $prefer_ipv6 = 0;
    }

    # Plain SOCKS proxies, including Tor Browser's local listener, are most
    # reliable with IPv4 literal targets.  Avoid handing OpenVPN an IPv6 remote
    # through SOCKS unless there is no IPv4 address for the selected node.
    if (($state->{transport}->{socks_enabled} // 'off') eq 'on' && $can_ipv4) {
        $prefer_ipv6 = 0;
    }

    # Global random
    if ($selected eq $default_server_label) {
        my @eligible = grep {
               ($prefer_ipv6 && defined $_->{ipv6} && length $_->{ipv6})
            || ($can_ipv4 && defined $_->{ipv4} && length $_->{ipv4})
        } @$servers;

        @eligible = grep {
            defined $_->{ipv4} && length $_->{ipv4}
        } @$servers if !@eligible;

        @eligible = grep {
            defined $_->{ipv6} && length $_->{ipv6}
        } @$servers if !@eligible && (($state->{security}->{no_ipv6} // 'off') eq 'off');

        if (@eligible) {
            my $picked = $eligible[ int(rand(@eligible)) ];
            $state->{connect}->{selected_server_name} = $picked->{name};
            $state->{connect}->{remote_ipv4} = $picked->{ipv4};
            $state->{connect}->{remote_ipv6} = $picked->{ipv6};
        }
        else {
            $state->{connect}->{selected_server_name} = undef;
            $state->{connect}->{remote_ipv4} = undef;
            $state->{connect}->{remote_ipv6} = undef;
        }
    }

    # Named server
    else {
        my ($server) = grep {
            defined $_->{name} && $_->{name} eq $selected
        } @$servers;

        if ($server) {
            $state->{connect}->{selected_server_name} = $server->{name};
            $state->{connect}->{remote_ipv4} = $server->{ipv4};
            $state->{connect}->{remote_ipv6} = $server->{ipv6};
        }
        else {
            $state->{connect}->{selected_server_name} = undef;
            $state->{connect}->{remote_ipv4} = undef;
            $state->{connect}->{remote_ipv6} = undef;
        }
    }

    if ($prefer_ipv6 && ($state->{connect}->{remote_ipv6} // '') =~ /:/) {
        $state->{connect}->{remote_addr} = $state->{connect}->{remote_ipv6};
    }
    elsif (($state->{connect}->{remote_ipv4} // '') ne '') {
        $state->{connect}->{remote_addr} = $state->{connect}->{remote_ipv4};
    }
    else {
        $state->{connect}->{remote_addr} = $state->{connect}->{remote_ipv6};
    }
}

sub show_logbox {
    my ($state, $ui) = @_;

    return if $state->{runtime}->{logbox_visible};
    $state->{runtime}->{logbox_visible} = 1;

    $ui->{mainwin}->{frame}->{4}->g_grid(
        -column => 0,
        -row    => 3,
        -sticky => "nswe",
    );

    $ui->{mainwin}->{logbox}->g_grid(
        -column => 0,
        -row    => 0,
        -sticky => "nsew",
    );

    $ui->{mainwin}->{scroll}->g_grid(
        -column => 1,
        -row    => 0,
        -sticky => "ns",
    );

    $ui->{mainwin}->{frame}->{4}->g_grid_columnconfigure(0, -weight => 1);
    $ui->{mainwin}->{frame}->{4}->g_grid_rowconfigure(0, -weight => 1);

    _ui_pump();

    my $w = Tkx::winfo('reqwidth',  $ui->{mainwin}->{mw});
    my $h = Tkx::winfo('reqheight', $ui->{mainwin}->{mw});

    my $x = int((Tkx::winfo('screenwidth',  $ui->{mainwin}->{mw}) - $w) / 2);
    my $y = int((Tkx::winfo('screenheight', $ui->{mainwin}->{mw}) - $h) / 2);

    $ui->{mainwin}->{mw}->g_wm_geometry("${w}x${h}+$x+$y");

    _ui_pump();
}

sub shutdown_openvpn_graceful_async {
    my (%args) = @_;

    my $state     = $args{state}     || die "shutdown_openvpn_graceful_async: missing state";
    my $on_done   = $args{on_done}   || sub {};
    my $on_status = $args{on_status} || sub {};

    my $proto = uc($state->{connect}->{proto} // 'UDP');

    # UDP needs time for explicit-exit-notify to go out and for OpenVPN to exit cleanly.
    # TCP usually needs less, but this still keeps the UI non-blocking.
    my $grace_ms = $args{grace_ms}
                || ($proto eq 'UDP' ? 8000 : 4500);

    my $manport = $state->{connect}->{manport};
    my $manpass = $state->{connect}->{manpass};

    my $started_at = time;
    my $deadline   = $started_at + ($grace_ms / 1000);

    $on_status->('Stopping OpenVPN...');

    my $sigterm_sent = _send_openvpn_sigterm_once(
        state   => $state,
        manport => $manport,
        manpass => $manpass,
    );

    # Even if management signaling failed, do not immediately taskkill during normal disconnect.
    # Give OpenVPN a chance to exit from whatever close path is already happening.
    my $poll;
    $poll = sub {
        if (!isoncs_light($state)) {
            $on_done->();
            return;
        }

        if (time >= $deadline) {
            my $exe = $state->{app}->{ovpn_exe} || 'openvpn.exe';

            # Hide TASKKILL's "SUCCESS: ..." noise in dev consoles too.
            _run_taskkill_wait(qq(TASKKILL /F /T /IM "$exe" >NUL 2>NUL), timeout => 6);

            Tkx::after(500, sub {
                $on_done->();
            });

            return;
        }

        Tkx::after(250, $poll);
    };

    Tkx::after(250, $poll);

    return 1;
}

sub _send_openvpn_sigterm_once {
    my (%args) = @_;

    my $state   = $args{state};
    my $manport = $args{manport};
    my $manpass = $args{manpass};

    return 0 unless $manport && $manpass;

    my $ok = 0;

    eval {
        my $sock = IO::Socket::INET->new(
            PeerHost => '127.0.0.1',
            PeerPort => $manport,
            Proto    => 'tcp',
            Timeout  => 0.75,
        );

        return 0 unless $sock;

        $sock->autoflush(1);

        # Management password auth.
        print {$sock} "$manpass\r\n";

        # Give management a tiny chance to process auth before command.
        select undef, undef, undef, 0.05;

        print {$sock} "signal SIGTERM\r\n";

        # Do not wait for OpenVPN to disappear here.
        # Do not TASKKILL here.
        select undef, undef, undef, 0.05;

        print {$sock} "exit\r\n";
        close $sock;

        $ok = 1;
        1;
    } or do {
        $ok = 0;
    };

    return $ok;
}

sub isoncs_light {
    my ($state) = @_;

    return 0 unless defined $state->{connect}->{manport}
                 && defined $state->{connect}->{manpass};

    return 0 if (($state->{runtime}->{exit_btn_mode} // '') eq 'exit');

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $state->{connect}->{manport},
        Proto    => 'tcp',
        Timeout  => 0.20,
    ) or return 0;

    $sock->autoflush(1);

    print {$sock} "$state->{connect}->{manpass}\r\n";
    print {$sock} "state\r\n";

    my $connected = 0;
    my $deadline = time + 0.25;

    while (time < $deadline) {
        my $line = <$sock>;
        last unless defined $line;

        if ($line =~ /CONNECTED,SUCCESS/) {
            $connected = 1;
            last;
        }

        last if $line =~ /^END/;
    }

    print {$sock} "exit\r\n";
    close $sock;

    return $connected;
}

sub replace_logbox_tagged_line {
    my ($tag, $new_text) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    eval {
        my $follow = exists $state->{runtime}->{log_follow}
            ? $state->{runtime}->{log_follow}
            : 1;

        $logbox->configure(-state => 'normal');

        while (1) {
            my @range = $logbox->tag_nextrange($tag, '1.0', 'end');
            last unless @range >= 2;

            my ($start, $end) = @range;
            $logbox->delete("$start linestart", "$start lineend +1c");
        }

        $logbox->insert('end', $new_text . "\n", $tag);

        $logbox->configure(-state => 'disabled');

        $logbox->yview('moveto', 1.0) if $follow;

        1;
    } or do {
        warn "replace_logbox_tagged_line($tag) failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub _tag_ranges {
    my ($logbox, $tag) = @_;

    my @range = $logbox->tag_nextrange($tag, '1.0', 'end');

    # Tkx may return a Tcl list as one scalar.
    @range = Tkx::SplitList($range[0]) if @range == 1;

    return @range;
}

sub delete_logbox_tagged_lines {
    my ($tag) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;
    return unless defined $tag && length $tag;

    eval {
        $logbox->configure(-state => 'normal');

        while (1) {
            my @range = _tag_ranges($logbox, $tag);
            last unless @range >= 2;

            my ($start, $end) = @range;
            $logbox->delete("$start linestart", "$start lineend +1c");
        }

        $logbox->configure(-state => 'disabled');
        1;
    } or do {
        warn "delete_logbox_tagged_lines($tag) failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub delete_logbox_status_lines {
    for my $tag (qw/status_connected status_disconnecting status_disconnected status_abort status_suspending/) {
        delete_logbox_tagged_lines($tag);
    }
}

sub append_log_status_line {
    my ($ui, $line, $style_tag, $status_tag) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    $line = '' unless defined $line;
    $line =~ s/\r?\n+\z//;
    $line =~ s/[\r\n]+/ /g;

    my $follow = exists $state->{runtime}->{log_follow}
        ? $state->{runtime}->{log_follow}
        : 1;

    eval {
        $logbox->configure(-state => 'normal');

        my $start = $logbox->index('end-1c');

        $logbox->insert('end', $line . "\n", $style_tag);

        my $end = $logbox->index('end-1c');

        $logbox->tag_add($status_tag, $start, $end)
            if defined $status_tag && length $status_tag;

        $logbox->configure(-state => 'disabled');

        if ($follow) {
            _ui_pump();
            $logbox->yview('moveto', 1);
        }

        1;
    } or do {
        warn "append_log_status_line failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };
}

sub replace_logbox_status_line {
    my ($status_tag, $new_text, $style_tag) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return 0 unless $logbox;
    return 0 unless defined $status_tag && length $status_tag;

    $new_text = '' unless defined $new_text;
    $new_text =~ s/\r?\n+\z//;
    $new_text =~ s/[\r\n]+/ /g;

    my $found = 0;

    eval {
        my $follow = exists $state->{runtime}->{log_follow}
            ? $state->{runtime}->{log_follow}
            : 1;

        $logbox->configure(-state => 'normal');

        while (1) {
            my @range = _tag_ranges($logbox, $status_tag);
            last unless @range >= 2;

            my ($start, $end) = @range;
            $logbox->delete("$start linestart", "$start lineend +1c");
            $found = 1;
        }

        if ($found) {
            my $start = $logbox->index('end-1c');

            $logbox->insert('end', $new_text . "\n", $style_tag);

            my $end = $logbox->index('end-1c');

            $logbox->tag_add($status_tag, $start, $end);
        }

        $logbox->configure(-state => 'disabled');

        $logbox->yview('moveto', 1) if $found && $follow;

        1;
    } or do {
        warn "replace_logbox_status_line($status_tag) failed: $@";
        eval { $logbox->configure(-state => 'disabled') };
    };

    return $found;
}

sub _tail_text {
    my ($txt, $max) = @_;
    $txt = '' unless defined $txt;
    $max ||= 3000;
    $txt =~ s/\r\n/\n/g;
    $txt =~ s/\r/\n/g;
    return $txt if length($txt) <= $max;
    return substr($txt, length($txt) - $max);
}

sub tunnel_netstat_snapshot {
    my ($port) = @_;
    return '' unless defined $port && $port =~ /^\d+$/;
    my $out = `netstat -ano -p TCP 2>NUL`;
    $out = '' unless defined $out;
    my @lines = grep { /(?:127\.0\.0\.1|0\.0\.0\.0):\Q$port\E\b/ } split /\r?\n/, $out;
    return join("\n", @lines);
}

sub start_ssh_tunnel {
    my (%args) = @_;

    my $state = $args{state} || die "start_ssh_tunnel: missing state";
    my $L     = $args{L};
    my $servers = $args{servers} || [];
    my $lang  = $state->{app}->{lang} || 'English';
    my $is_tcp_accepting = $args{is_tcp_accepting} || die "start_ssh_tunnel: missing is_tcp_accepting";

    my $get_next_free_local_port = $args{get_next_free_local_port}
        || die "start_ssh_tunnel: missing get_next_free_local_port";

    my $is_tunnel_up = $args{is_tunnel_up}
        || die "start_ssh_tunnel: missing is_tunnel_up";

    my $do_error = $args{do_error};

    my $ssh_exe = $args{ssh_exe}
        || $state->{app}->{program_files_dir} . '\\cs-ssh-tun.exe';

    my $attempt_id = $state->{runtime}->{connect_attempt_id} // 0;
    begin_tunnel_start_ui_lock($attempt_id);

    my $old_status = $state->{runtime}->{status_text};
    my $old_local_port = $state->{transport}->{local_tunnel_port};

    if ($state->{runtime}->{ssh_pid}) {
        _run_taskkill_wait("taskkill /F /T /PID $state->{runtime}->{ssh_pid} >NUL 2>NUL", timeout => 5);
    }
    _run_taskkill_wait("taskkill /F /T /IM cs-ssh-tun.exe >NUL 2>NUL", timeout => 5);

    delete $state->{transport}->{local_tunnel_port};
    delete $state->{runtime}->{ssh_pid};

    wait_local_tcp_port_free($old_local_port, 2500) if $old_local_port;

    if (!-e $ssh_exe) {
        my $msg = ($L && $L->{$lang}{ERR_MISSING_SSH_EXE})
            || "Missing SSH tunnel executable";
        $do_error->("$msg:\n$ssh_exe")
            if $do_error && !silent_tunnel_failure($attempt_id);

        end_tunnel_start_ui_lock($attempt_id);
        return 0;
    }

    $state->{runtime}->{status_text} =
        ($L && $L->{$lang}{TXT_STARTING_SSH_TUNNEL})
        || "Starting SSH tunnel...";
    _ui_pump();

    my $local_port = $get_next_free_local_port->('random_tunnel');

    if (!$local_port) {
        $do_error->($L->{$lang}{ERR_NO_FREE_PORT} || "No free local port")
            if $do_error && $L && !silent_tunnel_failure($attempt_id);

        end_tunnel_start_ui_lock($attempt_id);
        return 0;
    }

    $state->{transport}->{local_tunnel_port} = $local_port;

    my $target = _resolve_ssh_tunnel_target($state, $servers);

    if (!$target || !$target->{host}) {
        $do_error->(($L && $L->{$lang}{ERR_MISSING_SSH_TARGET})
                || ($L && $L->{$lang}{ERR_TUNNEL})
                || "Missing SSH tunnel target")
            if $do_error && !silent_tunnel_failure($attempt_id);

        delete $state->{transport}->{local_tunnel_port};
        end_tunnel_start_ui_lock($attempt_id);
        return 0;
    }

    my $ssh_host    = $target->{host};
    my $ssh_hostkey = _normalize_ssh_hostkey($target->{ssh_hostkey});

    $state->{runtime}->{local_tunnel_remote_addr} = $ssh_host;
    $state->{runtime}->{local_tunnel_remote_port} = 22;
    $state->{runtime}->{local_tunnel_remote_ipv4} = $target->{ipv4} || '';
    $state->{runtime}->{local_tunnel_remote_ipv6} = $target->{ipv6} || '';

    ensure_local_tunnel_bypass_route($ssh_host);

    my $ssh_log = $args{ssh_log} || $state->{app}->{program_files_dir} . '\\..\\user\\ssh-tun.log';

    unlink $ssh_log if -e $ssh_log;

    my @plink_args = (
        _win_q($ssh_exe),
        '-v',
        '-batch',
        '-no-antispoof',
    );

    if ($ssh_hostkey) {
        push @plink_args, '-hostkey', _win_q($ssh_hostkey);
    }

    push @plink_args, (
        '-pw', 'sshtunnel',
        '-N',
        '-D', "$local_port",
        '-l', 'sshtunnel',
        _win_q($ssh_host),
    );

    my $plink_cmd = join(' ', @plink_args);

    # Use cmd.exe only for redirection. The doubled quote before the exe path is intentional.
    my $cmd = 'cmd.exe /d /c "' . $plink_cmd . ' > ' . _win_q($ssh_log) . ' 2>&1"';

    my $pid = system(1, $cmd);

    if (!defined($pid) || !$pid) {
        delete $state->{transport}->{local_tunnel_port};
        end_tunnel_start_ui_lock($attempt_id);

        $do_error->($L->{$lang}{ERR_TUNNEL} || "Unable to start SSH tunnel")
            if $do_error && $L && !silent_tunnel_failure($attempt_id);

        return 0;
    }

    $state->{runtime}->{ssh_pid} = $pid;

    my $ready = 0;
    my $fatal = '';
    my $deadline = time + 20;

    while (time < $deadline) {
        if (!connect_attempt_alive($attempt_id)) {
            $fatal = "Connect attempt was aborted while SSH tunnel was starting";
            last;
        }

        if (local_tcp_listener_ready($local_port)) {
            $ready = 1;
            last;
        }

        my $txt = _slurp_file($ssh_log);

        if ($txt =~ /Local port\s+(?:127\.0\.0\.1:)?\Q$local_port\E\s+SOCKS dynamic forwarding/i) {
            $ready = 1;
            last;
        }

        if ($txt =~ /(FATAL ERROR:.*|Network error:.*|Access denied|Cannot confirm a host key.*|Unable to open connection.*)/i) {
            $fatal = $1;
            last;
        }

        # Do not treat the launcher PID exiting as fatal by itself.  On some
        # Windows builds system(1, cmd.exe /c ...) can report the wrapper as gone
        # while plink is still starting or while Windows is still creating the
        # SOCKS listener.  The log parser above catches real plink failures;
        # otherwise wait out the readiness window and include log/netstat details.

        _ui_pump();
        select undef, undef, undef, 0.10;
    }

    if (!$ready) {
        my $txt = _slurp_file($ssh_log);
        my $tail = _tail_text($txt, 4000);
        my $netstat = tunnel_netstat_snapshot($local_port);
        my $msg = ($L->{$lang}{ERR_TUNNEL} || "Unable to start SSH tunnel");
        $msg .= "\n\nSSH target: $ssh_host" if defined $ssh_host && length $ssh_host;
        $msg .= "\nLocal port: $local_port" if $local_port;
        $msg .= "\nReason: $fatal" if defined $fatal && length $fatal;
        $msg .= "\n\nssh-tun.log:\n$tail" if length $tail;
        $msg .= "\n\nnetstat:\n$netstat" if length $netstat;
        $state->{runtime}->{last_tunnel_error} = $msg;

        if ($ENV{CS_DEBUG_SSH}) {
            print STDERR "[SSH] tunnel not ready on local port $local_port\n";
            print STDERR "[SSH] fatal=$fatal\n" if $fatal;
            print STDERR "[SSH] output:\n$txt\n" if length $txt;
        }

        if ($state->{runtime}->{ssh_pid} && kill(0, $state->{runtime}->{ssh_pid})) {
            _run_taskkill_wait("taskkill /F /T /PID $state->{runtime}->{ssh_pid} >NUL 2>NUL", timeout => 5);
        }

        delete $state->{runtime}->{ssh_pid};
        delete $state->{transport}->{local_tunnel_port};
        end_tunnel_start_ui_lock($attempt_id);

        $do_error->($msg)
            if $do_error && $L && !silent_tunnel_failure($attempt_id);

        return 0;
    }

    end_tunnel_start_ui_lock($attempt_id);
    return 1;
}

sub _read_exact_timeout {
    my ($sock, $want, $timeout) = @_;

    my $buf = '';
    my $sel = IO::Select->new($sock);
    my $deadline = time + ($timeout || 2);

    while (length($buf) < $want && time < $deadline) {
        my $remaining = $deadline - time;
        last if $remaining <= 0;

        my $wait = $remaining < 0.20 ? $remaining : 0.20;
        next if !$sel->can_read($wait);

        my $chunk = '';
        my $n = sysread($sock, $chunk, $want - length($buf));
        return undef unless defined $n && $n > 0;

        $buf .= $chunk;
    }

    return length($buf) == $want ? $buf : undef;
}

sub socks5_connect_test {
    my ($local_port, $target_host, $target_port) = @_;

    return (0, "missing local SOCKS port") unless $local_port;
    return (0, "missing target host") unless defined $target_host && length $target_host;

    $target_port ||= 443;

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $local_port,
        Proto    => 'tcp',
        Timeout  => 2,
    ) or return (0, "local SOCKS connect failed: $!");

    $sock->autoflush(1);

    print $sock "\x05\x01\x00";

    my $method = _read_exact_timeout($sock, 2, 2);
    if (!defined $method || $method ne "\x05\x00") {
        close($sock);
        return (0, "SOCKS method negotiation failed");
    }

    my ($atype, $addr);

    if ($target_host =~ /^(\d{1,3})(?:\.(\d{1,3})){3}$/) {
        my @octets = split /\./, $target_host;
        if (grep { $_ > 255 } @octets) {
            close($sock);
            return (0, "invalid IPv4 target");
        }

        $atype = "\x01";
        $addr  = pack('C4', @octets);
    }
    elsif ($target_host =~ /:/) {
        my $packed = eval { Socket::inet_pton(AF_INET6, $target_host) };

        if (!defined $packed || length($packed) != 16) {
            close($sock);
            return (0, "invalid IPv6 target");
        }

        $atype = "\x04";
        $addr  = $packed;
    }
    else {
        if (length($target_host) > 255) {
            close($sock);
            return (0, "target hostname too long");
        }

        $atype = "\x03";
        $addr  = chr(length($target_host)) . $target_host;
    }

    print $sock "\x05\x01\x00" . $atype . $addr . pack('n', $target_port);

    my $head = _read_exact_timeout($sock, 4, 5);
    if (!defined $head || length($head) != 4) {
        close($sock);
        return (0, "SOCKS connect reply timed out");
    }

    my ($ver, $rep, $rsv, $reply_atype) = unpack('C4', $head);

    if ($ver != 5) {
        close($sock);
        return (0, "SOCKS connect reply had bad version $ver");
    }

    if ($rep != 0) {
        close($sock);
        return (0, "SOCKS connect failed with reply code $rep");
    }

    my $skip =
        $reply_atype == 1 ? 4 :
        $reply_atype == 4 ? 16 :
        $reply_atype == 3 ? undef :
        0;

    if (!defined $skip) {
        my $len = _read_exact_timeout($sock, 1, 1);
        $skip = defined $len ? unpack('C', $len) : 0;
    }

    _read_exact_timeout($sock, $skip + 2, 1) if $skip >= 0;

    close($sock);
    return (1, "SOCKS connect succeeded");
}

sub _normalize_ssh_hostkey {
    my ($hostkey) = @_;

    $hostkey = '' unless defined $hostkey;
    $hostkey =~ s/^\s+|\s+$//g;

    return '' unless length $hostkey;

    # so latest_list.json can store just the base64 SHA256 value.
    if ($hostkey !~ /^SHA256:/i) {
        $hostkey = "SHA256:$hostkey";
    }

    return $hostkey;
}

sub _resolve_ssh_tunnel_target {
    my ($state, $servers) = @_;

    $servers ||= [];

    my $selected = $state->{transport}->{ssh_tunnel};
    return unless defined $selected && length $selected;

    my $can_ipv4 = host_has_usable_ipv4_route();
    my $has_ipv6_route = host_has_usable_ipv6_route($state, ignore_disable_ipv6 => 1);
    my $use_ipv6 =
           ((($state->{security}->{no_ipv6} // 'off') eq 'off') && $has_ipv6_route)
        || (!$can_ipv4 && (($state->{security}->{no_ipv6} // 'off') eq 'off') && $has_ipv6_route);

    $use_ipv6 = 0 if (($state->{security}->{no_ipv6} // 'off') eq 'on');

    my $server;

    for my $s (@$servers) {
        next unless ref($s) eq 'HASH';
        next unless defined $s->{name} && $s->{name} eq $selected;

        if (defined $s->{ssh_hostkey} && length $s->{ssh_hostkey}) {
            $server = $s;
            last;
        }

        $server ||= $s;
    }

    if (!$server) {
        my $raw = $selected;
        $raw =~ s/^\s+|\s+$//g;

        return if (($state->{security}->{no_ipv6} // 'off') eq 'on') && ($raw =~ /:/);

    return {
        host        => $raw,
        ipv4        => ($raw =~ /^\d{1,3}(?:\.\d{1,3}){3}$/) ? $raw : '',
        ipv6        => ($raw =~ /:/) ? $raw : '',
        ssh_hostkey => $state->{transport}->{ssh_hostkey} || '',
    } if length $raw;

        return;
    }

    my $ipv4 = $server->{ipv4} || '';
    my $ipv6 = $server->{ipv6} || '';

    my $host;
    if (($state->{security}->{no_ipv6} // 'off') eq 'on') {
        $host = $ipv4 || '';
    }
    else {
        # Prefer IPv6 for the helper's outer SSH connection when the system has
        # a usable IPv6 default route.  That preserves IPv6 tunneling semantics
        # for users with IPv6 connectivity.  The selected helper endpoint gets
        # a temporary bypass route before OpenVPN installs the VPN default route.
        $host = (($use_ipv6 && $ipv6) ? $ipv6 : '') || $ipv4 || $ipv6;
    }
    $host =~ s/^\s+|\s+$//g if defined $host;

    my $hostkey =
           $server->{ssh_hostkey}
        || $state->{transport}->{ssh_hostkey}
        || '';

    $hostkey =~ s/^\s+|\s+$//g if defined $hostkey;

    return {
        host        => $host || '',
        ipv4        => $ipv4 || '',
        ipv6        => $ipv6 || '',
        ssh_hostkey => $hostkey || '',
    };
}

sub is_local_tcp_accepting {
    my ($port, $timeout_ms) = @_;

    $timeout_ms ||= 7000;

    my $deadline = time + ($timeout_ms / 1000);

    while (time < $deadline) {
        return 1 if _legacy_ipv4_connect_check($port);

        Tkx::update();
        select undef, undef, undef, 0.10;
    }

    return -1;
}

sub clear_local_tunnel_runtime {
    my ($wait_ms) = @_;
    $wait_ms ||= 1500;

    my $old_port = $state->{transport}->{local_tunnel_port};
    delete $state->{transport}->{local_tunnel_port};
    delete @{$state->{runtime}}{qw(local_tunnel_remote_addr local_tunnel_remote_port local_tunnel_remote_ipv4 local_tunnel_remote_ipv6)};
    cleanup_local_tunnel_bypass_routes();

    for my $pid_key (qw(ssh_pid stunnel_pid xray_pid)) {
        if ($state->{runtime}->{$pid_key}) {
            _run_taskkill_wait("taskkill /F /T /PID $state->{runtime}->{$pid_key} >NUL 2>NUL", timeout => 5);
            delete $state->{runtime}->{$pid_key};
        }
    }

    wait_local_tcp_port_free($old_port, $wait_ms) if $old_port;
}

sub reset_local_tunnel_helpers {
    my (%args) = @_;
    my $wait_ms = $args{wait_ms} || 1200;

    my $old_port = $state->{transport}->{local_tunnel_port};

    delete $state->{transport}->{local_tunnel_port};
    delete @{$state->{runtime}}{qw(local_tunnel_remote_addr local_tunnel_remote_port local_tunnel_remote_ipv4 local_tunnel_remote_ipv6)};
    cleanup_local_tunnel_bypass_routes();
    delete $state->{runtime}->{last_tunnel_error};
    delete $state->{runtime}->{tunnel_start_ui_locked};

    for my $pid_key (qw(ssh_pid stunnel_pid xray_pid)) {
        if ($state->{runtime}->{$pid_key}) {
            _run_taskkill_wait("taskkill /F /T /PID $state->{runtime}->{$pid_key} >NUL 2>NUL", timeout => 5);
            delete $state->{runtime}->{$pid_key};
        }
    }

    # These are bundled helper processes; kill by image as a fallback because a
    # failed/aborted startup can lose the child PID while the listener survives.
    for my $image (qw(cs-ssh-tun.exe cs-https-tun.exe xray.exe)) {
        _run_taskkill_wait(qq{taskkill /F /T /IM $image >NUL 2>NUL}, timeout => 5);
    }

    wait_local_tcp_port_free($old_port, $wait_ms) if $old_port;

    # Let WFP/Win7 networking settle before immediately launching a replacement.
    my $deadline = time + ($wait_ms / 1000);
    while (time < $deadline) {
        _ui_pump();
        select undef, undef, undef, 0.05;
    }

    return 1;
}

sub _legacy_ipv4_connect_check {
    my ($port) = @_;

    return 0 unless defined $port && $port =~ /^\d+$/;

    my $proto = getprotobyname('tcp');
    my $iaddr = inet_aton('127.0.0.1');
    my $paddr = sockaddr_in($port, $iaddr);

    socket(my $sock, PF_INET, SOCK_STREAM, $proto) or return 0;

    my $ok = eval {
        connect($sock, $paddr) or die "connect";
        1;
    };

    close($sock);

    return $ok ? 1 : 0;
}

sub management_is_connected_light {
    my ($state) = @_;

    return 0 unless defined $state->{connect}->{manport}
                 && defined $state->{connect}->{manpass};

    return 0 if $state->{runtime}->{mgmt_probe_active};

    local $state->{runtime}->{mgmt_probe_active} = 1;

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $state->{connect}->{manport},
        Proto    => 'tcp',
        Timeout  => 0.35,
    ) or return 0;

    $sock->autoflush(1);

    my $sel = IO::Select->new($sock);
    my $buf = '';

    my $read_some = sub {
        my ($seconds) = @_;

        my $deadline = time + $seconds;

        while (time < $deadline) {
            last unless $sel->can_read(0.10);

            my $chunk = '';
            my $n = sysread($sock, $chunk, 4096);

            last unless defined $n && $n > 0;

            $buf .= $chunk;
        }
    };

    # The password prompt is usually "ENTER PASSWORD:" with no newline.
    $read_some->(0.35);

    print $sock "$state->{connect}->{manpass}\r\n";

    $read_some->(0.50);

    print $sock "state\r\n";

    $read_some->(1.00);

    eval { print $sock "exit\r\n"; };
    close($sock);

    if ($buf =~ /\bCONNECTED\b/i) {
        _update_runtime_ips_from_management_state($state, $buf);
        return 1;
    }

    if ($ENV{CS_DEBUG_MGMT}) {
        my $safe = $buf;
        $safe =~ s/\r/\\r/g;
        $safe =~ s/\n/\\n/g;
        print STDERR "[mgmt-light] raw=$safe\n";
    }

    return 0;
}

sub _update_runtime_ips_from_management_state {
    my ($state, $buf) = @_;

    return unless defined $buf && length $buf;

    for my $line (split /\r?\n/, $buf) {
        $line =~ s/^>STATE://;
        next unless $line =~ /\bCONNECTED\b/i || $line =~ /\bASSIGN_IP\b/i;

        if (!$state->{runtime}->{localip}
            && $line =~ /\b(10\.(?:66|67|70|71)\.\d{1,3}\.(?:25[0-5]|2[0-4]\d|1\d\d|\d\d|[2-9]))\b/) {
            $state->{runtime}->{localip} = $1;
        }

        if (!$state->{runtime}->{localip6}
            && $line =~ /\b(fd00:10:60:(?:[a-f0-9]{1,4}:){4}[a-f0-9]{1,4})\b/i) {
            $state->{runtime}->{localip6} = $1;
        }
    }
}

sub start_management_success_watcher {
    my (%args) = @_;

    my $state        = $args{state}        || die "start_management_success_watcher: missing state";
    my $attempt_id   = $args{attempt_id}   // ($state->{runtime}->{connect_attempt_id} // 0);
    my $on_connected = $args{on_connected} || die "start_management_success_watcher: missing on_connected";

    my $deadline = time + 120;
    my $ticks = 0;

    my $tick;
    $tick = sub {
        return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);

        my $mode = $state->{runtime}->{exit_btn_mode} // '';
        return unless $mode eq 'abort';

        return if (($state->{runtime}->{connected_attempt_id} // -1) == $attempt_id);

        $ticks++;

        if (management_is_connected_light($state)) {
            $on_connected->();
            return;
        }

        if (time > $deadline) {
            return;
        }

        Tkx::after(2000, $tick);
    };

    Tkx::after(3000, $tick);

    return 1;
}

sub mark_openvpn_connected {
    my (%args) = @_;

    my $source     = $args{source} || 'unknown';
    my $attempt_id = $args{attempt_id} // ($state->{runtime}->{connect_attempt_id} // 0);
    my $lang       = $state->{app}->{lang} || 'English';

    return 0 if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);

    my $mode = $state->{runtime}->{exit_btn_mode} // '';
    return 0 if $mode =~ /^(aborting|disconnecting|exit)$/;

    # Already marked connected for this attempt.
    return 1 if (($state->{runtime}->{connected_attempt_id} // -1) == $attempt_id);

    $state->{runtime}->{connected_attempt_id} = $attempt_id;

    delete $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Network/NewNetworkWindowOff/"}
        if $Registry;

    if (($state->{security}->{killswitch_enabled} // 'off') eq "on") {
        management_is_connected_light($state)
            unless $state->{runtime}->{localip} || $state->{runtime}->{localip6};

        refresh_killswitch_tunnel_rules_after_connect();
    }

    $state->{runtime}->{pbar}           = 100;
    $state->{runtime}->{pbar_target}    = 100;
    $state->{runtime}->{pbar_animating} = 0;

    stop_world_icon_spinner($state, $ui, 'g3');

    if (($state->{connect}->{save_token} // 'off') eq "on") {
        save_config(
            state     => $state,
            json_file => $state->{app}->{config_json_file},
        );
    }

    delete_logbox_status_lines();

    $ui->{mainwin}->{world_img}->configure(-image => "g3");

    append_log_status_line(
        $ui,
        $L->{$lang}{TXT_CONNECTED},
        "goodline",
        "status_connected",
    );

    $state->{runtime}->{last_log_status} = 'connected';

    $state->{runtime}->{status_text}   = $L->{$lang}{TXT_CONNECTED};
    $state->{runtime}->{exit_btn_mode} = 'disconnect';

    $ui->{mainwin}->{exit_btn}->configure(
        -text  => $L->{$lang}{TXT_DISCONNECT},
        -state => 'normal',
    );
    alarm(0);

    _ui_pump();

    Tkx::after(900, sub {
        return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
        return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'disconnect');

        hidewin();

        Tkx::after(100, sub {
            return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
            return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'disconnect');

            system(1, 'netsh interface ipv6 set privacy state=enabled');
        });

        Tkx::after(300, sub {
            return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
            return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'disconnect');

            start_post_connect_checks(
                state => $state,
                on_done => sub {
                    my ($result) = @_;

                    return if (($state->{runtime}->{connect_attempt_id} // -1) != $attempt_id);
                    return unless (($state->{runtime}->{exit_btn_mode} // '') eq 'disconnect');

                    if ($result && ($result->{upgrade} // 0)) {
                        maybe_prompt_for_update();
                    }

                    $state->{runtime}->{status_text} =
                        $L->{$state->{app}->{lang}}{TXT_CONNECTED};
                },
            );
        });
    });

    return 1;
}

sub _launch_upgrade_installer_after_exit {
    my ($installer) = @_;

    return 0 unless defined $installer && length $installer && -e $installer;
    return 0 unless $^O =~ /MSWin32/i;

    my $tmp = $ENV{TEMP} || $ENV{TMP} || '';
    $tmp =~ s/[\\\/]\z//;
    return 0 unless $tmp && -d $tmp;

    my $comspec = $ENV{ComSpec} || (($ENV{SystemRoot} || 'C:\\Windows') . '\\System32\\cmd.exe');
    return 0 unless -e $comspec;

    # The installer generated by download_and_verify_update() has a controlled
    # basename in this same temp directory.  Deriving it from %~dp0 in the
    # batch file avoids embedding an arbitrary TEMP path in a command line.
    my ($installer_name) = $installer =~ /([^\\\/]+)\z/;
    return 0 unless defined $installer_name && $installer_name =~ /^cryptostorm_setup_[A-Za-z0-9_.-]+\.exe\z/i;

    # The auto-launch path must actually be the file in this TEMP directory,
    # not merely another file with an acceptable basename.
    my $installer_abs = Win32::AbsPath::Fix($installer) || $installer;
    my $expected_abs  = Win32::AbsPath::Fix("$tmp\\$installer_name") || "$tmp\\$installer_name";
    $installer_abs =~ tr|/|\\|;
    $expected_abs  =~ tr|/|\\|;
    return 0 unless lc($installer_abs) eq lc($expected_abs);

    my $stamp = $$ . '_' . int(time * 1000) . '_' . int(rand(100000));
    my $waiter = "$tmp\\cs_upgrade_$stamp.cmd";

    my $fh;
    return 0 unless open $fh, '>:raw', $waiter;

    # tasklist is available on every supported Windows version (Win7+).  The
    # output text itself need not be English; we only search the filtered row
    # for the numeric PID surrounded by column whitespace.
    print {$fh} "\@echo off\r\n";
    print {$fh} "setlocal\r\n";
    print {$fh} "set \"PARENT_PID=$$\"\r\n";
    print {$fh} "set \"INSTALLER=%~dp0$installer_name\"\r\n";
    print {$fh} ":wait_parent\r\n";
    print {$fh} "tasklist /FI \"PID eq %PARENT_PID%\" /NH 2>NUL | findstr /R /C:\"[ ]%PARENT_PID%[ ]\" >NUL\r\n";
    print {$fh} "if not errorlevel 1 (\r\n";
    print {$fh} "  ping -n 2 127.0.0.1 >NUL 2>NUL\r\n";
    print {$fh} "  goto wait_parent\r\n";
    print {$fh} ")\r\n";
    print {$fh} "rem Extra grace period after the old client process disappears.\r\n";
    print {$fh} "ping -n 3 127.0.0.1 >NUL 2>NUL\r\n";
    print {$fh} "if not exist \"%INSTALLER%\" exit /b 2\r\n";
    print {$fh} "start \"\" /wait \"%INSTALLER%\"\r\n";
    print {$fh} "set \"RC=%ERRORLEVEL%\"\r\n";
    print {$fh} "del /f /q \"%INSTALLER%\" >NUL 2>NUL\r\n";
    print {$fh} "del /f /q \"%~f0\" >NUL 2>NUL\r\n";
    print {$fh} "exit /b %RC%\r\n";
    close $fh;

    my $cmdline = qq($comspec /D /S /C call "$waiter");
    my $proc;
    my $created = Win32::Process::Create(
        $proc,
        $comspec,
        $cmdline,
        0,                      # do not inherit client/PAR/Tkx handles
        $CREATE_NO_WINDOW_FLAG,
        $tmp,                   # do not keep bin\\ as the child cwd
    );

    if (!$created) {
        unlink $waiter if -e $waiter;
        return 0;
    }

    return 1;
}

sub _win_q {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/"/\\"/g;
    return qq("$s");
}

sub _slurp_file {
    my ($path) = @_;
    return '' unless defined $path && -e $path;

    local $/;
    open my $fh, '<', $path or return '';
    binmode $fh;
    my $txt = <$fh>;
    close $fh;

    return defined $txt ? $txt : '';
}
