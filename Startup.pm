package Startup;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(
    run_startup
    init_tkx_resources
    check_platform_requirements
    cleanup_legacy_wintun
    enforce_single_instance
    restore_legacy_dns_if_needed
    detect_versions
    setup_main_windows
);

use Tkx;
use Win32;
use Win32::Process::List;

sub run_startup {
    my (%args) = @_;

    my $state         = $args{state}         or die "run_startup: missing state";
    my $ui            = $args{ui}            or die "run_startup: missing ui";
    my $L             = $args{L}             or die "run_startup: missing L";
    my $lang          = $args{lang}          or die "run_startup: missing lang";
    my $version       = $args{version}       // '';
    my $do_error      = $args{do_error}      or die "run_startup: missing do_error callback";
    my $do_exit       = $args{do_exit}       or die "run_startup: missing do_exit callback";
    my $isoncs        = $args{isoncs};
    my $hidewin       = $args{hidewin};
    my $backtomain    = $args{backtomain};

    init_tkx_resources(
        state   => $state,
        ui      => $ui,
        L       => $L,
        lang    => $lang,
        version => $version,
    );

    check_platform_requirements(
        state    => $state,
        ui       => $ui,
        L        => $L,
        lang     => $lang,
        do_error => $do_error,
        do_exit  => $do_exit,
    );

    cleanup_legacy_wintun(
        state => $state,
        ui    => $ui,
        L     => $L,
        lang  => $lang,
    );

    enforce_single_instance(
        state    => $state,
        ui       => $ui,
        L        => $L,
        lang     => $lang,
        do_exit  => $do_exit,
    );

    detect_versions(
        state => $state,
    );

    setup_main_windows(
        state      => $state,
        ui         => $ui,
        L          => $L,
        lang       => $lang,
        version    => $version,
        isoncs     => $isoncs,
        hidewin    => $hidewin,
        do_exit    => $do_exit,
        backtomain => $backtomain,
    );

    return 1;
}

sub init_tkx_resources {
    my (%args) = @_;
    my $state   = $args{state};
    my $ui      = $args{ui};
    my $version = $args{version};

    our $hiddenornot = "Hide";

    Tkx::package_require("style");
    Tkx::package_require("tooltip");
    Tkx::style__use("as", -priority => 70);

    Tkx::font_create("logo_font",  -family => "Helvetica", -size => 10, -weight => "bold");
    Tkx::font_create("token_font", -family => "Arial",     -size => 10);

    Tkx::image_create_photo("langimage", -file => "..\\res\\flags\\us.png");
    Tkx::image_create_photo("mainicon",  -file => "..\\res\\greyworld.png");
    Tkx::image_create_photo("mainicon2", -file => "..\\res\\world2.png");
    Tkx::image_create_photo("opticon",   -file => "..\\res\\world3.png");
    Tkx::image_create_photo("opticon2",  -file => "..\\res\\world4.png");
    Tkx::image_create_photo("erroricon", -file => "..\\res\\gears.png");

    for my $prefix (qw(b g r)) {
        for my $n (1..6) {
            Tkx::image_create_photo("${prefix}${n}", -file => "..\\res\\${prefix}${n}.png");
        }
    }

    Tkx::namespace_import("::tooltip::tooltip");
    Tkx::tk(appname => "cryptostorm.is client");

    $ui->{mainwin}->{mw} = Tkx::widget->new(".");
    Tkx::wm_iconphoto($ui->{mainwin}->{mw}, "mainicon");
    $ui->{mainwin}->{mw}->g_wm_withdraw();

    $ui->{opt_main}->{ow} = $ui->{mainwin}->{mw}->new_toplevel;
    $ui->{opt_main}->{ow}->g_wm_withdraw();

    return 1;
}

sub check_platform_requirements {
    my (%args) = @_;
    my $state    = $args{state};
    my $ui       = $args{ui};
    my $L        = $args{L};
    my $lang     = $args{lang};
    my $do_error = $args{do_error};
    my $do_exit  = $args{do_exit};

    if (Win32::IsAdminUser() != 1) {
        $do_error->($L->{$lang}{ERR_NEED_ADMIN});
        exit;
    }

    my ($os_string, $os_major, $os_minor, $os_build, $os_id) = Win32::GetOSVersion();

    $state->{runtime}->{os_string} = $os_string;
    $state->{runtime}->{os_major}  = $os_major;
    $state->{runtime}->{os_minor}  = $os_minor;
    $state->{runtime}->{os_build}  = $os_build;
    $state->{runtime}->{os_id}     = $os_id;

    if ($os_major < 6) {
        $do_error->($L->{$lang}{ERR_OLD_WIN});
        $do_exit->();
    }

    return 1;
}

sub cleanup_legacy_wintun {
    my (%args) = @_;
    my $state = $args{state};
    my $ui    = $args{ui};
    my $L     = $args{L};
    my $lang  = $args{lang};

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_WINTUN_CLEANUP};
    Tkx::update();

    if (-e "cswintun.exe") {
        system("cswintun.exe stop");

        if (($state->{runtime}->{os_major} // 0) >= 10) {
            system("cswintun.exe uninstall");
            Tkx::update();
        }

        unlink("cswintun.exe");
    }

    return 1;
}

sub enforce_single_instance {
    my (%args) = @_;
    my $state   = $args{state};
    my $ui      = $args{ui};
    my $L       = $args{L};
    my $lang    = $args{lang};
    my $do_exit = $args{do_exit};

    my $pi = Win32::Process::List->new();
    $state->{runtime}->{pid} = $$;

    my %procs = $pi->GetProcesses();
    my $proccount = 0;

    foreach my $pids (keys %procs) {
        next if $pids == $state->{runtime}->{pid};

        if ($procs{$pids} =~ /csvpn/i) {
            system(1, "TASKKILL /F /T /PID $pids");
        }

        if ($procs{$pids} =~ /^client(?:-dev)?\.exe$/i) {
            $proccount++;

            if ($proccount == 2) {
                my $onlyone_msgbox = Tkx::tk___messageBox(
                    -parent  => $ui->{mainwin}->{mw},
                    -type    => "yesno",
                    -message => $L->{$lang}{QUESTION_ONLYONE1} . "\n" .
                                $L->{$lang}{QUESTION_ONLYONE2} . "\n",
                    -icon    => "question",
                    -title   => "cryptostorm.is client",
                );

                if ($onlyone_msgbox eq "yes") {
                    system(1, "TASKKILL /F /T /PID $pids");
                }
                elsif ($onlyone_msgbox eq "no") {
                    system(1, "TASKKILL /F /T /PID " . $state->{runtime}->{pid});
                }
            }
        }
    }

    return 1;
}

sub detect_versions {
    my (%args) = @_;
    my $state = $args{state};

    my $ovpn_exe = $state->{app}->{ovpn_exe} or return 1;
	my $ossh_exe = $state->{app}->{ossh_exe} or return 1;
	my $stunnel_exe = $state->{app}->{stunnel_exe} or return 1;
	my $xray_exe = $state->{app}->{xray_exe} or return 1;
    
	my $get_ossl_ovpn_version = `$ovpn_exe --version`;
    if ($get_ossl_ovpn_version =~ /OpenVPN ([0-9\.]+)/) {
        $state->{app}->{ovpn_ver} = $1;
    }
    
	if ($get_ossl_ovpn_version =~ /OpenSSL ([0-9\.a-z]+)/) {
        $state->{app}->{ossl_ver} = $1;
    }
	
	my $get_plink_version = `$ossh_exe --version`;
    if ($get_plink_version =~ /plink: Release ([0-9\.]+)/) {
	    $state->{app}->{ossh_ver} = $1;
	}
	
	my $get_stunnel_version = `$stunnel_exe -version`;
    if ($get_stunnel_version =~ /stunnel ([0-9\.]+)/) {
	    $state->{app}->{stunnel_ver} = $1;
	}
	
	my $get_xray_version = `$xray_exe version`;
    if ($get_xray_version =~ /^Xray ([0-9\.]+)/) {
	    $state->{app}->{xray_ver} = $1;
	}

    return 1;
}

sub setup_main_windows {
    my (%args) = @_;
    my $state      = $args{state};
    my $ui         = $args{ui};
    my $L          = $args{L};
    my $lang       = $args{lang};
    my $version    = $args{version};
    my $isoncs     = $args{isoncs};
    my $hidewin    = $args{hidewin};
    my $do_exit    = $args{do_exit};
    my $backtomain = $args{backtomain};

    if (($state->{startup}->{no_splash} // 'off') ne "on") {
        my $splash = $ui->{mainwin}->{mw}->new_tkx_SplashScreen(
            -image   => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
            -width   => '480',
            -height  => '272',
            -show    => 1,
            -topmost => 1,
        );

        Tkx::after(500 => sub {
            $splash->g_destroy();
            $ui->{mainwin}->{mw}->g_wm_deiconify();
            $ui->{mainwin}->{mw}->g_raise();
            $ui->{mainwin}->{mw}->g_focus();
        });
    }

    $ui->{mainwin}->{mw}->g_wm_protocol('WM_DELETE_WINDOW', sub {
        if ($isoncs && $isoncs->() > 0) {
            $hidewin->() if $hidewin;
        }
        else {
            $do_exit->() if $do_exit;
        }
    });

    $ui->{mainwin}->{mw}->g_wm_resizable(0, 0);
    Tkx::wm_title($ui->{mainwin}->{mw}, "cryptostorm widget v$version");
    Tkx::wm_attributes($ui->{mainwin}->{mw}, -toolwindow => 0, -topmost => 0);

    $state->{runtime}->{status_text} = $L->{$lang}{TXT_NOT_CONNECTED};

    $ui->{opt_main}->{ow}->g_wm_protocol('WM_DELETE_WINDOW', sub {
        $backtomain->() if $backtomain;
    });

    $ui->{opt_main}->{ow}->g_wm_resizable(0, 0);
    Tkx::wm_attributes($ui->{opt_main}->{ow}, -toolwindow => 0, -topmost => 0);
    Tkx::wm_title($ui->{opt_main}->{ow}, $L->{$lang}{TXT_OPTIONS});
    Tkx::wm_iconphoto($ui->{opt_main}->{ow}, "mainicon");

    $ui->{opt_main}->{frame} = $ui->{opt_main}->{ow}->new_ttk__frame(-relief => "flat");

    return 1;
}

1;