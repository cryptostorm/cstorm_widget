package LangPicker;

use strict;
use warnings;
use utf8;
use Tkx;
use File::Spec;
use File::Basename qw(dirname);

sub new {
    my ($class, %opt) = @_;

    my $self = bless {
        widget          => $opt{-widget},          # existing Tkx label widget
        parent          => $opt{-parent},          # parent for popup
        popup           => undef,
        item_widgets    => [],
        images          => {},
        current_ix      => 0,

        textvariable    => $opt{-textvariable},    # scalar ref for displayed lang name/code
        state_lang      => $opt{-state_lang},      # scalar ref, e.g. \$state->{app}->{lang}
        default_text    => defined $opt{-default_text} ? $opt{-default_text} : 'English',
        lang_ini        => $opt{-lang_ini} || 'lang.txt',
        res_dir         => $opt{-res_dir}  || '..\\res',
        on_change       => $opt{-on_change},       # optional coderef

        use_flags       => exists $opt{-use_flags} ? $opt{-use_flags} : 1,
        use_abbrev      => exists $opt{-use_abbrev} ? $opt{-use_abbrev} : 1,

        languages       => [],
        lang_map        => {},
    }, $class;

    die "LangPicker requires -widget\n" unless $self->{widget};
    die "LangPicker requires -parent\n" unless $self->{parent};
    die "LangPicker requires -textvariable\n" unless $self->{textvariable};

    $self->_load_languages_from_ini;

    if (!defined ${ $self->{textvariable} } || ${ $self->{textvariable} } eq '') {
        ${ $self->{textvariable} } = $self->{default_text};
    }

    if (defined $self->{state_lang}) {
        ${ $self->{state_lang} } = ${ $self->{textvariable} };
    }

    for my $w ($self->{widget}) {
        $w->g_bind('<Button-1>', sub { $self->_toggle_popup });
        $w->g_bind('<Enter>',    sub { $self->_hover_on  });
        $w->g_bind('<Leave>',    sub { $self->_hover_off });
    }

    $self->{widget}->g_bind('<Return>', sub { $self->_toggle_popup });
    $self->{widget}->g_bind('<space>',  sub { $self->_toggle_popup });
    $self->{widget}->g_bind('<Down>',   sub { $self->_toggle_popup });

    $self->_refresh_attached_widget;

    return $self;
}

sub refresh_languages {
    my ($self) = @_;
    $self->_load_languages_from_ini;
    $self->_refresh_attached_widget;
}

sub set_language {
    my ($self, $lang_name) = @_;
    return if !defined $lang_name || $lang_name eq '';

    ${ $self->{textvariable} } = $lang_name;

    if (defined $self->{state_lang}) {
        ${ $self->{state_lang} } = $lang_name;
    }

    $self->_refresh_attached_widget;

    if ($self->{on_change} && ref($self->{on_change}) eq 'CODE') {
        $self->{on_change}->($lang_name);
    }
}

sub _toggle_popup {
    my ($self) = @_;
    if (defined $self->{popup} && Tkx::winfo_exists($self->{popup})) {
        $self->_close_popup;
    } else {
        $self->_open_popup;
    }
}

sub _hover_on {
    my ($self) = @_;
    eval {
        $self->{widget}->configure(-relief => 'solid', -borderwidth => 1);
    };
}

sub _hover_off {
    my ($self) = @_;
    eval {
        $self->{widget}->configure(-relief => 'flat', -borderwidth => 1);
    };
}

sub _refresh_attached_widget {
    my ($self) = @_;

    my $name = ${ $self->{textvariable} };
    my $lang = $self->{lang_map}{$name};

    if (!$lang) {
        ($lang) = grep { $_->{name} eq $self->{default_text} } @{ $self->{languages} };
    }
    return if !$lang;

    my $text = $self->{use_abbrev} ? ($lang->{abbr} || $lang->{name}) : $lang->{name};

    my %cfg = (
        -text => $text,
    );

    if ($self->{use_flags}) {
        my $img = $lang->{flagAsset}
            ? $self->_load_image($lang->{flagAsset})
            : $self->_blank_image;

        $cfg{-image} = $img;
    }

    $self->{widget}->configure(%cfg);
}

sub _open_popup {
    my ($self) = @_;

    my $popup = $self->{parent}->new_toplevel();
    $self->{popup} = $popup;

    $popup->g_wm_withdraw();
    $popup->g_wm_overrideredirect(1);

    my @items = @{ $self->{languages} };
    return if !@items;

    my $screen_w = $popup->g_winfo_screenwidth();
    my $screen_h = $popup->g_winfo_screenheight();

    my $current_name = ${ $self->{textvariable} };
    my $selected_ix  = 0;

    for my $i (0 .. $#items) {
        $selected_ix = $i if $items[$i]{name} eq $current_name;
    }
    $self->{current_ix} = $selected_ix;

    my $max_width_chars = 0;
    for my $item (@items) {
        my $display = $item->{display} || $item->{name};
        my $len = length($display);
        $max_width_chars = $len if $len > $max_width_chars;
    }
    $max_width_chars += 2;

    my $outer = $popup->new_frame(
        -relief      => 'solid',
        -borderwidth => 1,
        -padx        => 8,
        -pady        => 8,
    );
    $outer->g_grid(-row => 0, -column => 0, -sticky => 'nsew');

    $self->{item_widgets} = [];

    for my $i (0 .. $#items) {
        my $item = $items[$i];

        my $cell = $outer->new_frame(
            -relief      => 'flat',
            -borderwidth => 1,
            -cursor      => 'hand2',
            -padx        => 6,
            -pady        => 4,
        );

        my $img = $item->{flagAsset}
            ? $self->_load_image($item->{flagAsset})
            : $self->_blank_image;

        my $img_label = $cell->new_label(
            -image               => $img,
            -borderwidth         => 0,
            -highlightthickness  => 0,
            -cursor              => 'hand2',
        );

        my $txt_label = $cell->new_label(
            -text                => $item->{display},
            -anchor              => 'w',
            -justify             => 'left',
            -width               => $max_width_chars,
            -borderwidth         => 0,
            -highlightthickness  => 0,
            -cursor              => 'hand2',
            -padx                => 6,
        );

        $cell->g_grid(
            -row    => $i,
            -column => 0,
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

    $self->_focus_item($self->{current_ix});

    $popup->g_bind('<Escape>',   sub { $self->_close_popup });
    $popup->g_bind('<Return>',   sub { $self->_choose_item(\@items, $self->{current_ix}) });
    $popup->g_bind('<KP_Enter>', sub { $self->_choose_item(\@items, $self->{current_ix}) });

    $popup->g_bind('<Up>',   sub { $self->_move_focus(-1, scalar @items) });
    $popup->g_bind('<Down>', sub { $self->_move_focus( 1, scalar @items) });

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

    $popup->g_bind('<ButtonPress-1>', [
        sub {
            my ($root_x, $root_y) = @_;

            return if $self->_point_inside_widget($self->{popup}, $root_x, $root_y);

            if ($self->_point_inside_widget($self->{parent}, $root_x, $root_y)) {
                $self->_close_popup;
            }
        },
        Tkx::Ev('%X'), Tkx::Ev('%Y')
    ]);

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

sub _point_inside_widget {
    my ($self, $widget, $root_x, $root_y) = @_;

    return 0 unless defined $widget && eval { Tkx::winfo_exists($widget) };

    my $x = eval { $widget->g_winfo_rootx() };
    my $y = eval { $widget->g_winfo_rooty() };
    my $w = eval { $widget->g_winfo_width() };
    my $h = eval { $widget->g_winfo_height() };

    return 0 unless defined $x && defined $y && defined $w && defined $h;

    return $root_x >= $x
        && $root_y >= $y
        && $root_x <  $x + $w
        && $root_y <  $y + $h;
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

    my $lang_name = $items->[$ix]{name};

    ${ $self->{textvariable} } = $lang_name;

    if (defined $self->{state_lang}) {
        ${ $self->{state_lang} } = $lang_name;
    }

    $self->_refresh_attached_widget;
    $self->_close_popup;

    if ($self->{on_change} && ref($self->{on_change}) eq 'CODE') {
        $self->{on_change}->($lang_name);
    }
}

sub _item_hover_on {
    my ($self, $ix) = @_;
    $self->_focus_item($ix);
}

sub _item_hover_off {
    my ($self, $ix) = @_;
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
    my ($self, $delta, $count) = @_;

    my $new_ix = $self->{current_ix} + $delta;
    $new_ix = 0 if $new_ix < 0;
    $new_ix = $count - 1 if $new_ix >= $count;

    $self->_focus_item($new_ix);
}

sub _load_languages_from_ini {
    my ($self) = @_;

    my $ini_path = $self->_resolve_path($self->{lang_ini});

    my %seen;
    my @order;

    if (open my $fh, '<:encoding(UTF-8)', $ini_path) {
        while (my $line = <$fh>) {
            chomp $line;

            next if $line =~ /^\s*;/;
            next if $line =~ /^\s*$/;

            if ($line =~ /^\s{2}([^=]+?)\s*=\s*(.*?)\s*$/) {
                my $lang_name = $1;
                $lang_name =~ s/^\s+//;
                $lang_name =~ s/\s+$//;

                next if $seen{$lang_name}++;
                push @order, $lang_name;
            }
        }
        close $fh;
    }

    @order = ('English') if !@order;

    my %native_name = (
        English  => 'English',
        Japanese => '日本語',
        Swedish  => 'Svenska',
        Italian  => 'Italiano',
        Russian  => 'Русский',
        Chinese  => '中文',
        Persian  => 'فارسی',
        Arabic   => 'العربية',
        German   => 'Deutsch',
        French   => 'Français',
        Dutch    => 'Nederlands',
        Finnish  => 'Suomi',
        Spanish  => 'Español',
    );

    my %abbr = (
        English  => 'EN',
        Japanese => 'JP',
        Swedish  => 'SV',
        Italian  => 'IT',
        Russian  => 'RU',
        Chinese  => 'ZH',
        Persian  => 'FA',
        Arabic   => 'AR',
        German   => 'DE',
        French   => 'FR',
        Dutch    => 'NL',
        Finnish  => 'FI',
        Spanish  => 'ES',
    );

    my %flag_asset = (
        English  => 'flags/us.png',
        Japanese => 'flags/jp.png',
        Swedish  => 'flags/se.png',
        Italian  => 'flags/it.png',
        Russian  => 'flags/ru.png',
        Chinese  => 'flags/cn.png',
        Persian  => 'flags/ir.png',
        Arabic   => 'flags/sa.png',
        German   => 'flags/de.png',
        French   => 'flags/fr.png',
        Dutch    => 'flags/nl.png',
        Finnish  => 'flags/fi.png',
        Spanish  => 'flags/es.png',
    );

    my @languages;
    my %lang_map;

    for my $name (@order) {
        my $native = $native_name{$name} || $name;
        my $display = ($native eq $name) ? $name : "$name / $native";

        my $flag_rel = $flag_asset{$name};
        my $flag_full = defined $flag_rel
            ? $self->_resolve_path(File::Spec->catfile($self->{res_dir}, $flag_rel))
            : undef;

        my $entry = {
            name      => $name,
            native    => $native,
            display   => $display,
            abbr      => ($abbr{$name} || uc(substr($name, 0, 2))),
            flagAsset => $flag_full,
        };

        push @languages, $entry;
        $lang_map{$name} = $entry;
    }

    @languages = sort {
           ($a->{name} eq 'English' ? 0 : 1)
        <=>
           ($b->{name} eq 'English' ? 0 : 1)
        ||
           lc($a->{name}) cmp lc($b->{name})
    } @languages;

    $self->{languages} = \@languages;
    $self->{lang_map}  = \%lang_map;
}

sub _resolve_path {
    my ($self, $path) = @_;

    return $path if File::Spec->file_name_is_absolute($path);

    my $base = dirname($0);
    return File::Spec->catfile($base, $path);
}

sub _load_image {
    my ($self, $path) = @_;

    return $self->_blank_image if !defined $path || $path eq '';
    return $self->_blank_image if !-e $path;

    if (!$self->{images}{$path}) {
        $self->{images}{$path} = Tkx::image_create_photo(-file => $path);
    }

    return $self->{images}{$path};
}

sub _blank_image {
    my ($self) = @_;
    if (!$self->{images}{__blank__}) {
        $self->{images}{__blank__} = Tkx::image_create_photo(-width => 16, -height => 11);
    }
    return $self->{images}{__blank__};
}

sub widget {
    my ($self) = @_;
    return $self->{widget};
}

1;
