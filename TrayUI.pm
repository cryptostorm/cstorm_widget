package TrayUI;

use strict;
use warnings;
use Exporter qw(import);
use Win32::GUI;

our @EXPORT_OK = qw(
    init_tray
    hide_to_tray
    show_from_tray
    rebuild_tray_menu
    track_tray_menu
    remove_tray
);

my $TrayIcon;
my $TrayWinHidden;
my $TrayNotify;
my $TrayMenu;

sub init_tray {
    my (%args) = @_;

    my $state      = $args{state}      or die "init_tray: missing state";
    my $ui         = $args{ui}         or die "init_tray: missing ui";
    my $icon_path  = $args{icon_path}  || '..\\res\\world1.ico';
    my $on_show    = $args{on_show};
    my $on_exit    = $args{on_exit};
    my $on_hide    = $args{on_hide};

    $state->{tray}->{hidden}        ||= 'Hide';
    $state->{tray}->{show_tip_once} ||= 0;

    $TrayIcon = Win32::GUI::Icon->new($icon_path);

    $TrayWinHidden = Win32::GUI::Window->new(
        -name    => 'TrayWindow',
        -text    => 'TrayWindow',
        -width   => 1,
        -height  => 1,
        -visible => 0,
    );

    $TrayNotify = $TrayWinHidden->AddNotifyIcon(
        -name         => 'Open',
        -icon         => $TrayIcon,
        -tip          => 'cryptostorm.is client',
        -balloon_icon => 'info',
        -onRightClick => sub {
            track_tray_menu();
            return 0;
        },
        -onClick => sub {
            $on_show->() if $on_show;
            return 0;
        },
    );

    rebuild_tray_menu(
        state   => $state,
        ui      => $ui,
        on_show => $on_show,
        on_hide => $on_hide,
        on_exit => $on_exit,
    );

    return 1;
}

sub hide_to_tray {
    my (%args) = @_;

    my $state = $args{state} or die "hide_to_tray: missing state";
    my $ui    = $args{ui}    or die "hide_to_tray: missing ui";

    my $on_show = $args{on_show};
    my $on_hide = $args{on_hide};
    my $on_exit = $args{on_exit};

    return unless $ui->{mainwin}->{mw};

    my $wm_state = $ui->{mainwin}->{mw}->g_wm_state;

    if ($wm_state eq "normal" || $wm_state eq "iconic") {
        $state->{tray}->{hidden} = "Show";

        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_wm_withdraw();

        rebuild_tray_menu(
            state   => $state,
            ui      => $ui,
            on_show => $on_show,
            on_hide => $on_hide,
            on_exit => $on_exit,
            balloon => 1,
        );
    }

    return 1;
}

sub show_from_tray {
    my (%args) = @_;

    my $state = $args{state} or die "show_from_tray: missing state";
    my $ui    = $args{ui}    or die "show_from_tray: missing ui";

    my $on_show = $args{on_show};
    my $on_hide = $args{on_hide};
    my $on_exit = $args{on_exit};

    return unless $ui->{mainwin}->{mw};

    my $wm_state = $ui->{mainwin}->{mw}->g_wm_state;

    if ($wm_state eq "iconic" || $wm_state eq "normal") {
        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_focus();
    }

    if ($wm_state eq "withdrawn") {
        $state->{tray}->{hidden} = "Hide";

        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_raise();
        $ui->{mainwin}->{mw}->g_focus();

        rebuild_tray_menu(
            state   => $state,
            ui      => $ui,
            on_show => $on_show,
            on_hide => $on_hide,
            on_exit => $on_exit,
            balloon => 0,
        );
    }

    return 1;
}

sub rebuild_tray_menu {
    my (%args) = @_;

    my $state  = $args{state} or die "rebuild_tray_menu: missing state";
    my $on_show = $args{on_show};
    my $on_hide = $args{on_hide};
    my $on_exit = $args{on_exit};

    my $balloon = (($args{balloon} // 0) && !($state->{tray}->{show_tip_once} // 0)) ? 1 : 0;

    if (defined $TrayNotify) {
        Win32::GUI::NotifyIcon::Change(
            $TrayNotify,
            -balloon         => $balloon,
            -balloon_tip     => "Connected to cryptostorm.",
            -tip             => "Cryptostorm Client",
            -balloon_timeout => 10,
        );
    }

    my $hidden = $state->{tray}->{hidden} || "Hide";

    if ($hidden eq "Show") {
        $TrayMenu = Win32::GUI::Menu->new(
            "Options" => "Options",
            ">Show client" => {
                -name    => "Toggle",
                -onClick => sub {
                    $on_show->() if $on_show;
                    return 0;
                },
            },
            ">-" => { -name => "LS" },
            ">Exit" => {
                -name    => "Exit",
                -onClick => sub {
                    $on_exit->() if $on_exit;
                    return 0;
                },
            },
        );
    }
    else {
        $TrayMenu = Win32::GUI::Menu->new(
            "Options" => "Options",
            ">Hide client" => {
                -name    => "Toggle",
                -onClick => sub {
                    $on_hide->() if $on_hide;
                    return 0;
                },
            },
            ">-" => { -name => "LS" },
            ">Exit" => {
                -name    => "Exit",
                -onClick => sub {
                    $on_exit->() if $on_exit;
                    return 0;
                },
            },
        );
    }

    $state->{tray}->{show_tip_once} = 1 if $balloon;

    return 1;
}

sub track_tray_menu {
    if (defined $TrayNotify && defined $TrayMenu) {
        $TrayNotify->Win32::GUI::TrackPopupMenu($TrayMenu->{"Options"});
    }

    return 0;
}

sub remove_tray {
    eval {
        $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
    };

    undef $TrayMenu;
    undef $TrayNotify;
    undef $TrayWinHidden;
    undef $TrayIcon;

    return 1;
}

1;