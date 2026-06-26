package ServerPicker;

use strict;
use warnings;
use Tkx;
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

sub new {
    my ($class, $parent, %opt) = @_;

    my $self = bless {
        parent       => $parent,
        frame        => undef,
        textvariable => $opt{-textvariable},
        servers      => $opt{-servers} || [],
        default_text => defined $opt{-default_text} ? $opt{-default_text} : 'Global random',
        popup        => undef,
        images       => {},
        item_widgets => [],
        current_ix   => 0,
        cols         => 2,
		state        => $opt{-state} || 'normal',
    }, $class;

    # Default if nothing valid is selected yet
    if (!defined ${ $self->{textvariable} } || ${ $self->{textvariable} } eq '') {
        ${ $self->{textvariable} } = $self->{default_text};
    }

    my $frame = $parent->new_ttk__frame(-padding => 0, -borderwidth => 1);
    $self->{frame} = $frame;

    my $inner = $frame->new_frame(
        -relief             => 'solid',
        -borderwidth        => 1,
        -highlightthickness => 0,
        -cursor             => 'hand2',
    );
    $self->{inner} = $inner;

    my $flag_label = $inner->new_label(
        -borderwidth       => 0,
        -highlightthickness => 0,
        -anchor            => 'w',
    );
    $self->{flag_label} = $flag_label;

    my $text_label = $inner->new_label(
        -textvariable      => $self->{textvariable},
        -anchor            => 'w',
        -borderwidth       => 1,
        -padx              => 6,
        -pady              => 4,
        -cursor            => 'hand2',
        -width             => 30,
    );
    $self->{text_label} = $text_label;

    my $arrow_label = $inner->new_label(
        -text              => chr(0x25BE),   # ▼
        -borderwidth       => 1,
        -highlightthickness => 0,
        -padx              => 6,
        -cursor            => 'hand2',
    );
    $self->{arrow_label} = $arrow_label;

    $inner->g_grid(-row => 0, -column => 0, -sticky => 'ew');
    $flag_label->g_grid(-row => 0, -column => 0, -sticky => 'w', -padx => [6, 0]);
    $text_label->g_grid(-row => 0, -column => 1, -sticky => 'w');
    $arrow_label->g_grid(-row => 0, -column => 2, -sticky => 'e');

    for my $w ($inner, $flag_label, $text_label, $arrow_label) {
        $w->g_bind('<Button-1>', sub { $self->_toggle_popup });
        $w->g_bind('<Enter>',    sub { $self->_main_hover_on  });
        $w->g_bind('<Leave>',    sub { $self->_main_hover_off });
    }

    $inner->g_bind('<Return>', sub { $self->_toggle_popup });
    $inner->g_bind('<space>',  sub { $self->_toggle_popup });
    $inner->g_bind('<Down>',   sub { $self->_toggle_popup });

    $self->_refresh_main_display;

    return $self;
}

sub g_grid  { shift->{frame}->g_grid(@_)  }
sub g_pack  { shift->{frame}->g_pack(@_)  }
sub g_place { shift->{frame}->g_place(@_) }

sub widget {
    return shift->{frame};
}

sub configure {
    my ($self, %args) = @_;

    if (exists $args{-state}) {
        my $state = $args{-state};
        $state = 'normal' if $state eq 'readonly';

        $self->{state} = $state;

        my $cursor = $self->{state} eq 'disabled' ? 'arrow' : 'hand2';

        for my $w (
            $self->{inner},
            $self->{flag_label},
            $self->{text_label},
            $self->{arrow_label},
        ) {
            next unless defined $w;
            eval { $w->configure(-cursor => $cursor); };
        }

        if ($self->{state} eq 'disabled') {
            eval { $self->{text_label}->configure(-foreground => 'gray50'); };
        }
        else {
            eval { $self->{text_label}->configure(-foreground => 'black'); };
        }

        delete $args{-state};
    }

    if (%args) {
        $self->{frame}->configure(%args);
    }

    return 1;
}

sub cget {
    my ($self, $opt) = @_;

    if ($opt eq '-state') {
        return $self->{state} || 'normal';
    }

    return $self->{frame}->cget($opt);
}

sub set_servers {
    my ($self, $servers) = @_;
    $self->{servers} = $servers || [];
    $self->_refresh_main_display;
}

sub _toggle_popup {
    my ($self) = @_;

    return if ($self->{state} || 'normal') eq 'disabled';

    if (defined $self->{popup} && Tkx::winfo_exists($self->{popup})) {
        $self->_close_popup;
    } else {
        $self->_open_popup;
    }
}

sub _main_hover_on {
    my ($self) = @_;
    return if ($self->{state} || 'normal') eq 'disabled';
    $self->{inner}->configure(-relief => 'solid', -borderwidth => 1);
}

sub _main_hover_off {
    my ($self) = @_;
    return if ($self->{state} || 'normal') eq 'disabled';
    $self->{inner}->configure(-relief => 'solid', -borderwidth => 1);
}

sub _refresh_main_display {
    my ($self) = @_;

    my $name = ${ $self->{textvariable} };
    my $img;

    if ($name eq $self->{default_text}) {
        $img = $self->_load_image('..\res\flags\global.png');
    } else {
        my ($server) = grep { $_->{name} eq $name } @{ $self->{servers} };
        if ($server && $server->{flagAsset}) {
            $img = $self->_load_image('..\res\\' . $server->{flagAsset});
        } else {
            $img = $self->_blank_image;
        }
    }

    $self->{flag_label}->configure(-image => $img);
}

sub _open_popup {
    my ($self) = @_;
    return if ($self->{state} || 'normal') eq 'disabled';

    my $popup = $self->{parent}->new_toplevel();
    $self->{popup} = $popup;

	$popup->g_wm_withdraw();
    $popup->g_wm_overrideredirect(1);

    my @items = (
        {
            name      => $self->{default_text},
            flagAsset => 'flags/global.png',
            is_random => 1,
        },
        @{ $self->{servers} }
    );

    my $screen_w = $popup->g_winfo_screenwidth();
    my $screen_h = $popup->g_winfo_screenheight();

    my $current_name = ${ $self->{textvariable} };
    my $selected_ix  = 0;

    for my $i (0 .. $#items) {
        $selected_ix = $i if $items[$i]{name} eq $current_name;
    }
    $self->{current_ix} = $selected_ix;

    my $max_col_width_chars = 0;
    for my $item (@items) {
        my $len = length($item->{name} || '');
        $max_col_width_chars = $len if $len > $max_col_width_chars;
    }
    $max_col_width_chars += 2;

    my $outer;
    my @trial_cols = (4, 3, 2);
    my $chosen_cols = 2;

    COL_TRY:
    for my $try_cols (@trial_cols) {
        # clear previous trial contents
        if (defined $outer && Tkx::winfo_exists($outer)) {
            $outer->g_destroy;
        }

        $outer = $popup->new_frame(
            -relief      => 'solid',
            -borderwidth => 1,
            -padx        => 8,
            -pady        => 8,
        );
        $outer->g_grid(-row => 0, -column => 0, -sticky => 'nsew');

        $self->{item_widgets} = [];

        for my $i (0 .. $#items) {
            my $item = $items[$i];
            my $row  = int($i / $try_cols);
            my $col  = $i % $try_cols;

            my $cell = $outer->new_frame(
                -relief      => 'flat',
                -borderwidth => 1,
                -cursor      => 'hand2',
                -padx        => 6,
                -pady        => 4,
            );

            my $flagAsset = '..\\res\\' . ($item->{flagAsset} || '');
            $flagAsset =~ s/\//\\/g;

            my $img = $item->{flagAsset}
                ? $self->_load_image($flagAsset)
                : $self->_blank_image;

            my $img_label = $cell->new_label(
                -image               => $img,
                -borderwidth         => 0,
                -highlightthickness  => 0,
                -cursor              => 'hand2',
            );

            my $txt_label = $cell->new_label(
                -text                => $item->{name},
                -anchor              => 'w',
                -justify             => 'left',
                -width               => $max_col_width_chars,
                -borderwidth         => 0,
                -highlightthickness  => 0,
                -cursor              => 'hand2',
                -padx                => 6,
            );

            $cell->g_grid(
                -row    => $row,
                -column => $col,
                -sticky => 'w',
                -padx   => 3,
                -pady   => 3,
            );

            $img_label->g_grid(-row => 0, -column => 0, -sticky => 'w');
            $txt_label->g_grid(-row => 0, -column => 1, -sticky => 'w');

            for my $w ($cell, $img_label, $txt_label) {
                $w->g_bind('<Enter>',    sub { $self->_item_hover_on($i) });
                $w->g_bind('<Leave>',    sub { $self->_item_hover_off($i) });
                $w->g_bind('<Button-1>', sub { $self->_choose_item(\@items, $i) });
            }

            push @{ $self->{item_widgets} }, $cell;
        }

        Tkx::update("idletasks");

        my $req_w = $popup->g_winfo_reqwidth();
        my $req_h = $popup->g_winfo_reqheight();

        # allow a large centered picker, but keep some margins
        my $fits_w = $req_w <= int($screen_w * 0.92);
        my $fits_h = $req_h <= int($screen_h * 0.85);

        if ($fits_w && $fits_h) {
            $chosen_cols = $try_cols;
            last COL_TRY;
        }
    }

    $self->{cols} = $chosen_cols;
    $self->_focus_item($self->{current_ix});

    $popup->g_bind('<Escape>',   sub { $self->_close_popup });
    $popup->g_bind('<Return>',   sub { $self->_choose_item(\@items, $self->{current_ix}) });
    $popup->g_bind('<KP_Enter>', sub { $self->_choose_item(\@items, $self->{current_ix}) });

    $popup->g_bind('<Left>',  sub { $self->_move_focus(-1,  0, scalar @items) });
    $popup->g_bind('<Right>', sub { $self->_move_focus( 1,  0, scalar @items) });
    $popup->g_bind('<Up>',    sub { $self->_move_focus( 0, -1, scalar @items) });
    $popup->g_bind('<Down>',  sub { $self->_move_focus( 0,  1, scalar @items) });

    Tkx::update("idletasks");

    my $req_w = $popup->g_winfo_reqwidth();
    my $req_h = $popup->g_winfo_reqheight();

    my $x = int(($screen_w - $req_w) / 2);
    my $y = int(($screen_h - $req_h) / 2);

    $x = 0 if $x < 0;
    $y = 0 if $y < 0;

    $popup->g_wm_geometry("+$x+$y");
    Tkx::update("idletasks");
    $popup->g_wm_deiconify();
    $popup->g_raise();

    $popup->g_grab_set();
    $popup->g_focus();

    $popup->g_bind('<FocusOut>', sub {
        Tkx::after(75, sub {
            return unless defined $self->{popup};
            return unless eval { Tkx::winfo_exists($self->{popup}) };

            my $focus = eval { Tkx::focus() };
            return unless defined $focus && length $focus;

            my $focus_top = eval { Tkx::winfo('toplevel', $focus) };
            my $popup_top = eval { Tkx::winfo('toplevel', $self->{popup}) };

            return if defined $focus_top
                   && defined $popup_top
                   && $focus_top eq $popup_top;

            $self->_close_popup;
        });
    });
}

sub _close_popup {
    my ($self) = @_;

    if (defined $self->{popup} && Tkx::winfo_exists($self->{popup})) {
        eval { $self->{popup}->g_grab_release(); };
        $self->{popup}->g_destroy;
    }

    $self->{popup} = undef;
}

sub _choose_item {
    my ($self, $items, $ix) = @_;
    ${ $self->{textvariable} } = $items->[$ix]{name};
    $self->_refresh_main_display;
    $self->_close_popup;
}

sub _item_hover_on {
    my ($self, $ix) = @_;
    $self->_focus_item($ix);
}

sub _item_hover_off {
    my ($self, $ix) = @_;
    # no-op for now; leave current highlight in place
}

sub _focus_item {
    my ($self, $ix) = @_;
    $self->{current_ix} = $ix;

    for my $i (0 .. $#{ $self->{item_widgets} }) {
        my $w = $self->{item_widgets}[$i];
        if ($i == $ix) {
            $w->configure(-relief => 'solid', -borderwidth => 1);
        } else {
            $w->configure(-relief => 'flat', -borderwidth => 1);
        }
    }
}

sub _move_focus {
    my ($self, $dx, $dy, $count) = @_;

    my $ix   = $self->{current_ix};
    my $cols = $self->{cols};

    my $row = int($ix / $cols);
    my $col = $ix % $cols;

    $col += $dx;
    $row += $dy;

    $col = 0 if $col < 0;
    $row = 0 if $row < 0;

    my $new_ix = $row * $cols + $col;
    $new_ix = $count - 1 if $new_ix >= $count;

    $self->_focus_item($new_ix);
}

sub _load_image {
    my ($self, $path) = @_;

    return $self->_blank_image if !defined $path || $path eq '';

    my $full = $path;

    if (!File::Spec->file_name_is_absolute($full)) {
        my $base = dirname(Win32::AbsPath::Fix("$0"));
        $full = File::Spec->catfile($base, $path);
    }

    return $self->_blank_image if !-e $full;

    if (!$self->{images}{$full}) {
        $self->{images}{$full} = Tkx::image_create_photo(-file => $full);
    }

    return $self->{images}{$full};
}

sub _blank_image {
    my ($self) = @_;
    if (!$self->{images}{__blank__}) {
        $self->{images}{__blank__} = Tkx::image_create_photo(-width => 16, -height => 11);
    }
    return $self->{images}{__blank__};
}

sub set_default_text {
    my ($self, $text) = @_;
    $self->{default_text} = $text if defined $text;
}

1;