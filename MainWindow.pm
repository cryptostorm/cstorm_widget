package MainWindow;

use strict;
use warnings;
use Exporter qw(import);
use Tkx;
use Win32::Clipboard;
use File::Copy qw(copy);

our @EXPORT_OK = qw(build_main_window);

sub build_main_window {
    my (%args) = @_;

    my $state   = $args{state}   or die "build_main_window: missing state";
    my $ui      = $args{ui}      or die "build_main_window: missing ui";
    my $L       = $args{L}       or die "build_main_window: missing L";
    my $lang    = $args{lang}    or die "build_main_window: missing lang";
    my $servers = $args{servers} or die "build_main_window: missing servers";
	
	my $callbacks = $args{callbacks} || {};

    my $do_connect = $callbacks->{do_connect} or die "build_main_window: missing connect_cmd";
    my $do_options = $callbacks->{do_options} or die "build_main_window: missing options_cmd";
    my $do_exit   = $callbacks->{do_exit} or die "build_main_window: missing exit_cmd";
	
	my $TrackTrayMenu = $callbacks->{TrackTrayMenu};
	my $showwin = $callbacks->{showwin};
    my $hidewin = $callbacks->{hidewin};
	my $isoncs = $callbacks->{isoncs};
    my $killswitch_on  = $callbacks->{killswitch_on}  || sub { return 0 };
    my $killswitch_off = $callbacks->{killswitch_off} || sub { return 0 };
	
	my $apply_language_to_ui = $callbacks->{apply_language_to_ui};

    my $token_plain_regex = $args{token_plain_regex} // '';
    my $token_hash_regex  = $args{token_hash_regex}  // '';

    $ui->{mainwin}->{frame}->{1} = $ui->{mainwin}->{mw}->new_ttk__frame(-relief => "flat");
    $ui->{mainwin}->{world_img} = $ui->{mainwin}->{frame}->{1}->new_ttk__label(-anchor => "center", -justify => "center", -image => 'mainicon', -compound => 'top', -text => "Server:\n\nToken:", -font => "logo_font");
    $ui->{mainwin}->{error_img} = $ui->{mainwin}->{frame}->{1}->new_ttk__label(-anchor => "center", -justify => "center", -image => 'erroricon', -compound => 'top', -text => "Server:\n\nToken:", -font => "logo_font");
    $ui->{mainwin}->{top_lbl} = $ui->{mainwin}->{frame}->{1}->new_tk__text();
    $ui->{mainwin}->{top_lbl}->tag(qw/configure link1 -foreground blue -underline 1/);
    $ui->{mainwin}->{top_lbl}->tag(qw/configure link2 -foreground blue -underline 1/);
    $ui->{mainwin}->{top_lbl}->tag(qw/configure link3 -foreground blue -underline 1/);
    $ui->{mainwin}->{top_lbl}->tag_bind("link1", "<Button-1>", sub { system 1, "start https://cryptostorm.is/#section5"; $ui->{mainwin}->{top_lbl}->tag(qw/configure link1 -foreground purple -underline 1/);});
    $ui->{mainwin}->{top_lbl}->tag_bind("link1", "<Double-1>", sub { });
    $ui->{mainwin}->{top_lbl}->tag_bind("link1", "<Enter>", sub { $ui->{mainwin}->{top_lbl}->configure(-cursor => 'hand2'); });
    $ui->{mainwin}->{top_lbl}->tag_bind("link1", "<Leave>", sub { $ui->{mainwin}->{top_lbl}->configure(-cursor => 'arrow'); });
    $ui->{mainwin}->{top_lbl}->tag_bind("link3", "<Button-1>", sub { system 1, "start https://cryptostorm.nu/"; $ui->{mainwin}->{top_lbl}->tag(qw/configure link3 -foreground purple -underline 1/); });
    $ui->{mainwin}->{top_lbl}->tag_bind("link3", "<Double-1>", sub { });
    $ui->{mainwin}->{top_lbl}->tag_bind("link3", "<Enter>", sub { $ui->{mainwin}->{top_lbl}->configure(-cursor => 'hand2'); });
    $ui->{mainwin}->{top_lbl}->tag_bind("link3", "<Leave>", sub { $ui->{mainwin}->{top_lbl}->configure(-cursor => 'arrow'); });
    $ui->{mainwin}->{top_lbl}->insert("1.0", "\n" . $L->{$lang}{TXT_MAINWINDOW1} . "\n" . $L->{$lang}{TXT_MAINWINDOW2} . " ");
    $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_HERE}, 'link1');
    $ui->{mainwin}->{top_lbl}->insert('insert', "\n \n");
    $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_MAINWINDOW5} . " ");
    $ui->{mainwin}->{top_lbl}->insert('insert', $L->{$lang}{TXT_HERE}, 'link3');
    $ui->{mainwin}->{top_lbl}->insert('insert', ".\n");
    $ui->{mainwin}->{top_lbl}->configure(-width => 55, -height => 10, -borderwidth => 0, -state=> 'disabled', -font => "TkTextFont", -cursor => 'arrow', -wrap => 'none', -background => 'SystemButtonFace', -selectbackground => 'SystemButtonFace', -selectforeground => "black");
    $ui->{mainwin}->{frame}->{2} = $ui->{mainwin}->{mw}->new_ttk__frame(-relief => "flat");
    # tk entry here instead of ttk so that we can use -borderwidth and -relief
    $ui->{mainwin}->{token_entry} = $ui->{mainwin}->{frame}->{2}->new_tk__entry(-textvariable => \$state->{connect}->{token}, -width => 35, -font => "token_font", -state => "normal", -borderwidth => 1, -relief => "solid", -show => '*',);
	install_token_focus_clearer($state, $ui);
	Tkx::bind($ui->{mainwin}->{token_entry}, "<3>", [
	    sub {
	        my ($x, $y) = @_;
	        my $menu = $ui->{mainwin}->{token_entry}->new_menu(-tearoff => 0);
	        my $token = $state->{connect}->{token} // '';
	
	        $menu->add_command(
	            -label => $L->{$state->{app}->{lang}}{TXT_COPY},
	            -state => (($token =~ /^($token_plain_regex)$/) || ($token =~ /^($token_hash_regex)$/))
	                ? "normal"
	                : "disabled",
	            -command => sub {
	                Tkx::clipboard("clear");
	                Tkx::clipboard("append", $state->{connect}->{token} // '');
	            },
	        );
	
	        my $clip = eval { Win32::Clipboard()->Get() } // '';
	
	        $menu->add_command(
	            -label => $L->{$state->{app}->{lang}}{TXT_PASTE},
	            -state => (($clip =~ /^($token_plain_regex)$/) || ($clip =~ /^($token_hash_regex)$/))
	                ? "normal"
	                : "disabled",
	            -command => sub {
	                $state->{connect}->{token} = $clip;
	            },
	        );
	
	        $menu->g_tk___popup($x, $y);
	    },
	    Tkx::Ev('%X', '%Y')
	]);
    Tkx::tooltip($ui->{mainwin}->{token_entry}, $L->{$lang}{TXT_TOOLTIP_TOKEN});
	
	$state->{runtime}->{token_entry_focus} = 0;
	$state->{runtime}->{token_entry_hover} = 0;

	my $refresh_token_visibility = sub {
    	my $show_plain =
	        ($state->{runtime}->{token_entry_focus} // 0)
    	    || ($state->{runtime}->{token_entry_hover} // 0);

	    $ui->{mainwin}->{token_entry}->configure(
	        -show => $show_plain ? '' : '*'
	    );
	};

	$ui->{mainwin}->{token_entry}->g_bind('<FocusIn>', sub {
	    $state->{runtime}->{token_entry_focus} = 1;
	    $refresh_token_visibility->();
	});

	$ui->{mainwin}->{token_entry}->g_bind('<FocusOut>', sub {
	    $state->{runtime}->{token_entry_focus} = 0;
	    $refresh_token_visibility->();
	});

	$ui->{mainwin}->{token_entry}->g_bind('<Enter>', sub {
	    $state->{runtime}->{token_entry_hover} = 1;
	    $refresh_token_visibility->();
	});

	$ui->{mainwin}->{token_entry}->g_bind('<Leave>', sub {
	    $state->{runtime}->{token_entry_hover} = 0;
	    $refresh_token_visibility->();
	});

    $state->{connect}->{server_display} = $L->{$lang}{TXT_DEFAULT_SERVER}
        unless defined $state->{connect}->{server_display};

    $ui->{mainwin}->{server_picker} = ServerPicker->new(
        $ui->{mainwin}->{frame}->{2},
        -textvariable => \$state->{connect}->{server_display},
        -servers      => $servers,
        -default_text => $L->{$lang}{TXT_DEFAULT_SERVER},
    );

    $ui->{mainwin}->{server_picker}->g_grid(
        -row    => 0,
        -column => 0,
        -sticky => 'w',
        -padx   => 4,
        -pady   => 4,
    );


    $ui->{mainwin}->{frame}->{3} = $ui->{mainwin}->{mw}->new_ttk__frame(-relief => "flat");
    $ui->{mainwin}->{connect_btn} = $ui->{mainwin}->{frame}->{3}->new_ttk__button(-text => "\n" . $L->{$lang}{TXT_CONNECT} . "\n", -command => $do_connect);
    $ui->{mainwin}->{options_btn} = $ui->{mainwin}->{frame}->{3}->new_ttk__button(-text => $L->{$lang}{TXT_OPTIONS}, -command => $do_options);
    $ui->{mainwin}->{exit_btn} = $ui->{mainwin}->{mw}->new_ttk__button(-text => $L->{$lang}{TXT_EXIT}, -command => $do_exit);
    $ui->{mainwin}->{save_token_check} = $ui->{mainwin}->{frame}->{2}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_SAVE}, -variable => \$state->{connect}->{save_token}, -onvalue => "on", -offvalue => "off");
    if ($state->{connect}->{token}) {
     $state->{connect}->{save_token} = "on";
    }
    $ui->{mainwin}->{pbar_frame} = $ui->{mainwin}->{mw}->new_ttk__frame(-padding => "3 0 0 0", -relief => "flat");
    $ui->{mainwin}->{pbar} = $ui->{mainwin}->{pbar_frame}->new_ttk__progressbar(-orient => "horizontal", -length => 100, -mode => "determinate", -variable => \$state->{runtime}->{pbar} );
    $ui->{mainwin}->{pbar}->g_grid (-column => 0, -row => 0, -sticky => "we");
    $ui->{mainwin}->{status_lbl} = $ui->{mainwin}->{mw}->new_ttk__label(-textvariable => \$state->{runtime}->{status_text}, -padding => "0 0 0 0", -relief => "sunken", -width => 28, -anchor => "w");
    $ui->{mainwin}->{frame}->{4} = $ui->{mainwin}->{mw}->new_ttk__frame(-relief => "flat");
    
	$ui->{mainwin}->{logbox} = $ui->{mainwin}->{frame}->{4}->new_tk__text(
        -width  => 40,
        -height => 14,
        -undo   => 1,
        -state  => "disabled",
        -bg     => "black",
        -fg     => "lightgrey",
    );
	
	$ui->{mainwin}->{logbox}->configure(
        -takefocus       => 1,
        -exportselection => 1,
        -cursor          => 'xterm',

    );
	
	$ui->{mainwin}->{logbox}->g_bind('<Button-1>', sub {
        $ui->{mainwin}->{logbox}->g_focus();

        my ($first, $last) = eval { $ui->{mainwin}->{logbox}->yview() };
        $state->{runtime}->{log_follow} = 0
            unless defined $last && $last >= 0.98;

        return;
    });

    $ui->{mainwin}->{logbox}->g_bind('<ButtonRelease-1>', sub {
        my ($first, $last) = eval { $ui->{mainwin}->{logbox}->yview() };
        $state->{runtime}->{log_follow} = 1
            if defined $last && $last >= 0.98;

        return;
    });

    $ui->{mainwin}->{scroll} = $ui->{mainwin}->{frame}->{4}->new_ttk__scrollbar(-orient => "vertical");

    my $logbox_path = _tk_widget_path($ui->{mainwin}->{logbox});
    my $scroll_path = _tk_widget_path($ui->{mainwin}->{scroll});

    $ui->{mainwin}->{scroll}->configure(
        -command => [$logbox_path, "yview"],
    );

    $ui->{mainwin}->{logbox}->configure(
        -yscrollcommand => sub {
            my ($first, $last) = @_;

            eval {
                Tkx::eval("$scroll_path set $first $last");
                1;
            };

            # Programmatic inserts/scrolls should not disable tailing.
            return if $state->{runtime}->{logbox_programmatic_scroll};

            # If the user scrolls back to the bottom, resume tailing.
            if (defined $last && $last >= 0.98) {
                $state->{runtime}->{log_follow} = 1;
            }

            # Do NOT set log_follow = 0 here.
            # User actions do that explicitly.
    },
);

    $ui->{mainwin}->{logbox}->tag_configure("goodline", -background => "green", -font => "helvetica 14 bold", -relief => "raised");
    $ui->{mainwin}->{logbox}->tag_configure("badline",  -background => "red", -font => "helvetica 14 bold", -relief => "raised");
    $ui->{mainwin}->{logbox}->tag_configure("warnline", -foreground => "black", -font => "helvetica 14 bold", -background => "yellow", -relief => "raised");

	$ui->{mainwin}->{logbox}->g_bind("<MouseWheel>", [
	    sub {
        	my ($delta) = @_;

        	$state->{runtime}->{log_follow} = 0;

        	my $units = ($delta > 0) ? -3 : 3;
        	$ui->{mainwin}->{logbox}->yview("scroll", $units, "units");

        	Tkx::after(50, sub {
	            my ($first, $last) = eval { $ui->{mainwin}->{logbox}->yview() };
            	$state->{runtime}->{log_follow} = 1
	                if defined $last && $last >= 0.98;
        	});

        	return "break";
    	},
    	Tkx::Ev('%D')
	]);

	$ui->{mainwin}->{scroll}->g_bind("<ButtonPress-1>", sub {
    	$state->{runtime}->{log_follow} = 0;
	});

	$ui->{mainwin}->{scroll}->g_bind("<ButtonRelease-1>", sub {
    	my ($first, $last) = eval { $ui->{mainwin}->{logbox}->yview() };
    	$state->{runtime}->{log_follow} = 1
        	if defined $last && $last >= 0.98;
	});
	
	$ui->{mainwin}->{logbox}->g_bind('<Home>', sub {
        my $logbox = $ui->{mainwin}->{logbox};
        return "break" unless $logbox;

        $state->{runtime}->{log_follow} = 0;

        eval {
           	$logbox->mark_set('insert', '1.0');
           	$logbox->yview('moveto', 0);
           	1;
        };

        return "break";
    });

  	$ui->{mainwin}->{logbox}->g_bind('<End>', sub {
       	my $logbox = $ui->{mainwin}->{logbox};
       	return "break" unless $logbox;

       	$state->{runtime}->{log_follow} = 1;

       	eval {
           	$logbox->mark_set('insert', 'end');
           	$logbox->yview('moveto', 1);
           	1;
       	};

       	return "break";
    });
	
	$ui->{mainwin}->{logbox}->g_bind("<Button-3>", [
        sub {
            my ($x, $y) = @_;

            my $menu = $ui->{mainwin}->{mw}->new_menu(-tearoff => 0);

            $menu->add_command(
                -label => $L->{$state->{app}->{lang}}{TXT_COPY},
                -command => sub {
                    copy_logbox_selection_or_all($ui);
                },
            );

            $menu->g_tk___popup($x, $y);
        },
        Tkx::Ev('%X', '%Y')
    ]);

    $ui->{mainwin}->{lang_img} = $ui->{mainwin}->{frame}->{1}->new_ttk__label(-anchor => "ne", -justify => "center", -image => 'langimage', -compound => 'top', -text => "EN", -font => "logo_font");

    $ui->{mainwin}->{lang_picker} = LangPicker->new(
        -widget       => $ui->{mainwin}->{lang_img},
        -parent       => $ui->{mainwin}->{frame}->{1},
        -textvariable => \$state->{app}->{lang},
        -state_lang   => \$state->{app}->{lang},
        -default_text => 'English',
        -lang_ini     => '..\\user\\lang.txt',
        -res_dir      => '..\\res',
        -use_flags    => 1,
        -use_abbrev   => 1,

        -on_change    => sub {
            my ($new_lang) = @_;

            $state->{app}->{lang} = $new_lang;
            $lang = $new_lang;   # only if other code still uses this scalar

            $apply_language_to_ui->($ui, $state, $L);
        },
    );

	$ui->{mainwin}->{frame}->{4}->g_grid_columnconfigure(0, -weight => 1);
    $ui->{mainwin}->{frame}->{4}->g_grid_rowconfigure(0, -weight => 1);
    $ui->{mainwin}->{mw}->g_bind("<Return>", sub { $ui->{mainwin}->{connect_btn}->invoke(); });
	$ui->{mainwin}->{mw}->g_wm_protocol('WM_DELETE_WINDOW', sub {
    	my $mode = $state->{runtime}->{exit_btn_mode} // 'exit';

    	if ($mode eq 'disconnect') {
        	$callbacks->{hidewin}->();
        	return;
    	}

    	if ($mode eq 'abort') {
        	$callbacks->{do_exit}->();   # do_exit already dispatches abort mode
        	return;
    	}

    	if ($mode eq 'disconnecting' || $mode eq 'aborting') {
	        return;
	    }

	    $callbacks->{do_exit}->();
	});
    $ui->{mainwin}->{frame}->{1}->g_grid(-column => 0, -row => 0);
    $ui->{mainwin}->{world_img}->g_grid(-column => 0, -row => 0);
    $ui->{mainwin}->{lang_img}->g_grid(-column => 2, -row => 0, -sticky => "n", -columnspan => 5);
    $ui->{mainwin}->{top_lbl}->g_grid(-column => 1, -row => 0);
    $ui->{mainwin}->{frame}->{2}->g_grid(-column => 0, -row => 0, -sticky => "s");
    $ui->{mainwin}->{token_entry}->g_grid(-column => 0, -row => 3);
    $ui->{mainwin}->{save_token_check}->g_grid(-column => 4, -row => 3, -sticky => "w");
    $ui->{mainwin}->{frame}->{3}->g_grid(-column => 0, -row => 0, -sticky => "se");
    $ui->{mainwin}->{pbar_frame}->g_grid(-column => 0, -row => 2, -sticky => "we");
    $ui->{mainwin}->{status_lbl}->g_grid(-column => 0, -row => 1, -sticky => "w");
    $ui->{mainwin}->{options_btn}->g_grid(-column => 1, -row => 1, -sticky => "e");
    $ui->{mainwin}->{connect_btn}->g_grid(-column => 1, -row => 2, -sticky => "nswe");
    $ui->{mainwin}->{exit_btn}->g_grid(-column => 0, -row => 1, -sticky => "e");

    Tkx::update('idletasks');
    my $width  = Tkx::winfo('reqwidth',  $ui->{mainwin}->{mw});
    my $height = Tkx::winfo('reqheight', $ui->{mainwin}->{mw});
    my $fullheight = $height * 2;
    eval {
        $ui->{mainwin}->{pbar}->configure(-length => $width);
        $ui->{mainwin}->{status_lbl}->configure(-width => ($width / 60));
    };
    # Options notebook is sized from its actual tab contents in client.pl.
    # Do not force the old 465x230 size here; that clipped the Advanced tab on
    # some small Windows displays.
    my $mw_x = int((Tkx::winfo('screenwidth',  $ui->{mainwin}->{mw})  - $width  ) / 2);
    my $mw_y = int((Tkx::winfo('screenheight', $ui->{mainwin}->{mw})  - $height ) / 2);
    $ui->{mainwin}->{mw}->g_wm_geometry("+$mw_x+$mw_y");
    Tkx::update('idletasks');

    $ui->{mainwin}->{token_entry}->g_bind("<Button-3>", [
        sub {
            my ($x, $y) = @_;

            my $menu  = $ui->{mainwin}->{mw}->new_menu(-tearoff => 0);
            my $token = $state->{connect}->{token} // '';

            $menu->add_command(
                -label => $L->{$state->{app}->{lang}}{TXT_COPY},
                -state => (($token =~ /^($token_plain_regex)$/) || ($token =~ /^($token_hash_regex)$/))
                    ? "normal"
                    : "disabled",
                -command => sub {
                    Tkx::clipboard("clear");
                    Tkx::clipboard("append", $state->{connect}->{token} // '');
                },
            );

            my $clip = eval { Win32::Clipboard()->Get() } // '';

            $menu->add_command(
                -label => $L->{$state->{app}->{lang}}{TXT_PASTE},
                -state => (($clip =~ /^($token_plain_regex)$/) || ($clip =~ /^($token_hash_regex)$/))
                    ? "normal"
                    : "disabled",
                -command => sub {
                    $state->{connect}->{token} = $clip;
                },
            );

            $menu->g_tk___popup($x, $y);
        },
        Tkx::Ev('%X', '%Y')
    ]);

    if ((($state->{security}->{killswitch_enabled} // 'off') eq "on") && (($state->{transport}->{socks_enabled} // 'off') eq "on")) {
        Tkx::tk___messageBox(-icon => "info", -message => $L->{$lang}{TXT_SOCKS_NO_KILLSWITCH});
        $state->{security}->{killswitch_enabled} = "off";
    }
    if ((-e "..\\user\\all.wfw") || ((( $state->{security}->{killswitch_enabled} // 'off') eq "on") && (($state->{startup}->{autorun} // 'off') ne "on"))) {
        my $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow DHCP"`;
        if ($rt =~ /cryptostorm/) {
            my $killswitch_msgbox = Tkx::tk___messageBox(-parent => $ui->{mainwin}->{mw}, -type => "yesno",
                                                         -message => $L->{$lang}{QUESTION_KILLSWITCH1} . "\n" .
									                                 $L->{$lang}{QUESTION_KILLSWITCH2},
                                                         -icon => "question", -title => "cryptostorm.is client");
            if ($killswitch_msgbox eq "yes") {
                $killswitch_off->();
                $state->{security}->{killswitch_enabled} = "off";
            }
        }
        else {
            unlink("..\\user\\all.wfw");
            $killswitch_on->();
        }
    }
    $state->{runtime}->{status_text} = $L->{$lang}{TXT_NOT_CONNECTED};
    if (($state->{startup}->{autoconnect} // 'off') eq "on") {
        $ui->{mainwin}->{mw}->g_wm_deiconify();
        $ui->{mainwin}->{mw}->g_raise();
        $ui->{mainwin}->{mw}->g_focus();
        $do_connect->();
    }
    if ($state->{runtime}->{upgrade}) {
        sleep 3;
        my $upgrade_or_not;
        $upgrade_or_not = Tkx::tk___messageBox(-parent => $ui->{mainwin}->{mw}, -type =>    "yesno",
                                               -message => $L->{$lang}{QUESTION_NEWVER1} . "\n" .
				                                           $L->{$lang}{QUESTION_NEWVER2} . "\n",
                                               -icon => "question", -title => "cryptostorm.is client");
        if ($upgrade_or_not eq "yes") {
            if ($state->{connect}->{token}) {
                copy($state->{app}->{auth_file},$ENV{'TEMP'} . "\\client.dat");
                copy($state->{app}->{config_file},$ENV{'TEMP'} . "\\config.ini");
            }
            system("start http://10.31.33.7/cryptostorm_setup.exe");
            exit;
        }
    }

    my $TrayIcon  = new Win32::GUI::Icon("..\\res\\world1.ico");
    my $TrayWinHidden = Win32::GUI::Window->new(
                 -name => 'TrayWindow',
                 -text => 'TrayWindow',
                 -width => 1,
                 -height => 1,
                 -visible => 0,
    );
    my $TrayNotify = $TrayWinHidden->AddNotifyIcon(
                -onRightClick => $TrackTrayMenu,
                -onClick => $showwin,
				-name => "Open",
                -icon => $TrayIcon,
                -tip => "cryptostorm.is client",
                -balloon_icon => "info");


    return 1;
}

sub _tk_widget_path {
    my ($w) = @_;

    return $w unless ref $w;

    return eval {
        Tkx::winfo("pathname", $w->g_winfo_id);
    } || "$w";
}

sub _widget_path {
    my ($w) = @_;
    return '' unless defined $w;
    return "$w";
}

sub _path_is_inside {
    my ($child, $parent) = @_;
    return 0 unless defined $child && defined $parent;
    return 1 if $child eq $parent;
    return $child =~ /^\Q$parent\E\./ ? 1 : 0;
}

sub install_token_focus_clearer {
    my ($state, $ui) = @_;

    my $mw    = $ui->{mainwin}->{mw};
    my $token = $ui->{mainwin}->{token_entry};

    return unless $mw && $token;

    my $token_path = _widget_path($token);

    $mw->g_bind('<Button-1>', [
        sub {
            my ($clicked_path) = @_;
            return unless defined $clicked_path;

            # Clicked token entry: leave token visible/focused.
            return if _path_is_inside($clicked_path, $token_path);

            # Do not steal focus from logbox selection/scrolling.
            if ($ui->{mainwin}->{logbox}) {
                my $logbox_path = _widget_path($ui->{mainwin}->{logbox});
                return if _path_is_inside($clicked_path, $logbox_path);
            }

            if ($ui->{mainwin}->{scroll}) {
                my $scroll_path = _widget_path($ui->{mainwin}->{scroll});
                return if _path_is_inside($clicked_path, $scroll_path);
            }

            # Do not steal focus from ServerPicker/LangPicker.
            if ($ui->{mainwin}->{server_picker} && $ui->{mainwin}->{server_picker}->can('widget')) {
                my $sp_path = _widget_path($ui->{mainwin}->{server_picker}->widget);
                return if _path_is_inside($clicked_path, $sp_path);
            }

            if ($ui->{mainwin}->{lang_picker} && $ui->{mainwin}->{lang_picker}->can('widget')) {
                my $lp_path = _widget_path($ui->{mainwin}->{lang_picker}->widget);
                return if _path_is_inside($clicked_path, $lp_path);
            }

            # Any other main-window click hides the token.
            $state->{runtime}->{token_entry_focus} = 0;
            $state->{runtime}->{token_entry_hover} = 0;

            eval {
                $token->configure(-show => '*');
                $mw->g_focus();
                1;
            };

            return;
        },
        Tkx::Ev('%W')
    ]);
}

sub copy_logbox_selection_or_all {
    my ($ui) = @_;

    my $logbox = $ui->{mainwin}->{logbox};
    return unless $logbox;

    my $text = '';

    # Prefer selected text.
    eval {
        $text = $logbox->get('sel.first', 'sel.last');
        1;
    } or do {
        $text = '';
    };

    # Fallback to whole logbox.
    if (!defined($text) || $text eq '') {
        eval {
            $text = $logbox->get('1.0', 'end-1c');
            1;
        } or do {
            $text = '';
        };
    }

    return unless defined($text) && length($text);

    Tkx::clipboard('clear');
    Tkx::clipboard('append', $text);

    return 1;
}

1;