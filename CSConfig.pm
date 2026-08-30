package CSConfig;

use strict;
use warnings;
use Exporter qw(import);
use File::Copy qw(copy);
use JSON::PP qw(encode_json decode_json);

our @EXPORT_OK = qw(
    restore_upgrade_files
    load_legacy_config_ini
    save_legacy_config_ini
    load_config_json
    save_config_json
    load_config
    save_config
);

sub restore_upgrade_files {
    my (%args) = @_;
    my $state = $args{state} or die "restore_upgrade_files: missing state";

    my $temp_client_dat = $ENV{TEMP} . '\\client.dat';
    my $temp_config_ini = $ENV{TEMP} . '\\config.ini';

    if (-e $temp_client_dat) {
        copy($temp_client_dat, $state->{app}->{auth_file});
        unlink($temp_client_dat);
    }

    if (-e $temp_config_ini) {
        copy($temp_config_ini, $state->{app}->{config_file});
        unlink($temp_config_ini);
    }

    return 1;
}

sub load_legacy_config_ini {
    my (%args) = @_;

    my $state             = $args{state}             or die "load_legacy_config_ini: missing state";
    my $servers           = $args{servers}           || [];
    my $regkey            = $args{regkey}            || {};
    my $argv              = $args{argv}              || [];
    my $token_plain_regex = $args{token_plain_regex} or die "load_legacy_config_ini: missing token_plain_regex";
    my $token_hash_regex  = $args{token_hash_regex}  or die "load_legacy_config_ini: missing token_hash_regex";

    my $file = $state->{app}->{config_file};
    return 0 unless defined $file && -e $file;

    open my $fh, '<', $file or die "Could not open $file: $!";

    while (<$fh>) {
        chomp;

        if ((/^($token_plain_regex)$/) || (/^($token_hash_regex)$/)) {
            $state->{connect}->{token} = $1;
        }
        elsif (/^timeout=([0-9]+)$/) {
            $state->{connect}->{timeout} = $1;
        }
        elsif (/^noipv6=(.*)$/) {
            $state->{security}->{no_ipv6} = $1;
        }
        elsif (/^dnsleak=(.*)$/) {
            $state->{security}->{dns_leak_protect} = $1;
        }
        elsif (/^port=(.*)$/) {
            $state->{connect}->{port} = $1;
        }
        elsif (/^proto=(.*)$/) {
            $state->{connect}->{proto} = $1;
        }
        elsif (/^node=(.*)$/) {
            my $saved = $1;
            for my $server (@$servers) {
                if ($saved eq $server->{name}) {
                    $state->{connect}->{server_display} = $saved;
                    last;
                }
            }
        }
        elsif (/^autocon=(.*)$/) {
            $state->{startup}->{autoconnect} = $1;
        }
        elsif (/^autosplash=(.*)$/) {
            $state->{startup}->{no_splash} = $1;
        }
        elsif (/^autorun=(.*)$/) {
            $state->{startup}->{autorun} = $1;
        }
        elsif (/^killswitch=(.*)$/) {
            $state->{security}->{killswitch_enabled} = $1;
        }
        elsif (/^ts=(.*)$/) {
            $state->{security}->{adblock_enabled} = $1;
        }
        elsif (/^tls_sel=(.*)$/) {
            $state->{connect}->{tls_cipher} = $1;
        }
        elsif (/^randomport=(.*)$/) {
            $state->{connect}->{random_port} = $1;
        }
        elsif ((/^lang=(.*)$/) && (!defined($argv->[0]) || $argv->[0] ne "/LANG")) {
            $state->{app}->{lang} = $1;
        }
        elsif (/^mssfix=(.*)$/) {
            $state->{connect}->{mssfix} = $1;
        }
        elsif (/^bind=(.*)$/) {
            $state->{connect}->{bind_ip} = $1;
        }
        elsif (/^socks=on$/) {
            $state->{transport}->{socks_enabled} = "on";
        }
        elsif (/^socks_ip=(.*)$/) {
            $state->{transport}->{socks_ip} = $1;
        }
        elsif (/^socks_port=(.*)$/) {
            $state->{transport}->{socks_port} = $1;
        }
        elsif (/^socks_noauth=(.*)$/) {
            if ($1 eq "off") {
                $state->{transport}->{socks_noauth} = "off";
                $state->{transport}->{socks_user} = $regkey->{SOCKS_USER};
                $state->{transport}->{socks_pass} = $regkey->{SOCKS_PASS};
            }
        }
        elsif (/^tunnel_ssh=(.*)$/) {
            $state->{transport}->{ssh_enabled} = $1;
        }
        elsif (/^tunnel_https=(.*)$/) {
            $state->{transport}->{https_enabled} = $1;
        }
        elsif (/^https_mode=(.*)$/) {
            $state->{transport}->{https_mode} = $1;
        }
        elsif (/^sni_host=(.*)$/) {
            $state->{transport}->{sni_host} = $1;
        }
        elsif (/^tunnel_host=(.*)$/) {
            my $saved = $1;
            for my $server (@$servers) {
                if ($saved eq $server->{name}) {
                    $state->{transport}->{ssh_tunnel} = $saved;
                    last;
                }
            }
        }
    }

    close $fh;
    return 1;
}

sub save_legacy_config_ini {
    my (%args) = @_;

    my $state             = $args{state}             or die "save_legacy_config_ini: missing state";
    my $regkey            = $args{regkey}            || {};
    my $registry_root_ref = $args{registry_root_ref};
    my $default_server    = $args{default_server}    // 'Global random';
    my $token_plain_regex = $args{token_plain_regex} or die "save_legacy_config_ini: missing token_plain_regex";
    my $token_hash_regex  = $args{token_hash_regex}  or die "save_legacy_config_ini: missing token_hash_regex";
    my $password          = $args{password}          // '';

    my $file = $state->{app}->{config_file};
    open my $fh, '>', $file or die "Could not write $file: $!";

    if (($state->{connect}->{token} =~ /^($token_plain_regex)$/) ||
        ($state->{connect}->{token} =~ /^($token_hash_regex)$/)) {
        print $fh $state->{connect}->{token} . "\n";
    }

    print $fh $password . "\n" if length $password;

    if (($state->{connect}->{server_display} // '') ne $default_server) {
        print $fh "node=$state->{connect}->{server_display}\n";
    }

    print $fh "autocon=$1\n"   if ($state->{startup}->{autoconnect}         // '') =~ /(on|off)/;
    print $fh "autosplash=$1\n"if ($state->{startup}->{no_splash}           // '') =~ /(on|off)/;
    print $fh "autorun=$1\n"   if ($state->{startup}->{autorun}             // '') =~ /(on|off)/;
    print $fh "lang=$1\n"      if ($state->{app}->{lang}                    // '') =~ /(.*)/;
    print $fh "killswitch=$1\n"if ($state->{security}->{killswitch_enabled} // '') =~ /(.*)/;
    print $fh "ts=$1\n"        if ($state->{security}->{adblock_enabled}    // '') =~ /(.*)/;
    print $fh "tls_sel=$1\n"   if ($state->{connect}->{tls_cipher}          // '') =~ /(.*)/;
    print $fh "dnsleak=$1\n"   if ($state->{security}->{dns_leak_protect}   // '') =~ /(on|off)/;
    print $fh "timeout=$1\n"   if ($state->{connect}->{timeout}             // '') =~ /([0-9]+)/;
    print $fh "noipv6=$1\n"    if ($state->{security}->{no_ipv6}            // '') =~ /(on|off)/;
    print $fh "port=$1\n"      if ($state->{connect}->{port}                // '') =~ /([0-9]+)/;
    print $fh "randomport=$1\n"if ($state->{connect}->{random_port}         // '') =~ /(on|off)/;
    print $fh "proto=$1\n"     if ($state->{connect}->{proto}               // '') =~ /(UDP|TCP)/;

    print $fh "mssfix=$state->{connect}->{mssfix}\n" if defined $state->{connect}->{mssfix};

    if (($state->{connect}->{bind_ip} // '') ne "Any address" && length($state->{connect}->{bind_ip} // '')) {
        print $fh "bind=$state->{connect}->{bind_ip}\n";
    }

    print $fh "socks=on\n" if ($state->{transport}->{socks_enabled} // '') eq "on";
    print $fh "socks_ip=$state->{transport}->{socks_ip}\n" if length($state->{transport}->{socks_ip} // '');
    print $fh "socks_port=$state->{transport}->{socks_port}\n" if length($state->{transport}->{socks_port} // '');

    if (($state->{transport}->{socks_noauth} // 'on') eq "off") {
        print $fh "socks_noauth=off\n";
        $regkey->{SOCKS_USER} = $state->{transport}->{socks_user} if length($state->{transport}->{socks_user} // '');
        $regkey->{SOCKS_PASS} = $state->{transport}->{socks_pass} if length($state->{transport}->{socks_pass} // '');
    } else {
        delete $regkey->{SOCKS_USER};
        delete $regkey->{SOCKS_PASS};
        delete $registry_root_ref->{'HKEY_CURRENT_USER/Software/Cryptostorm/'}
            if $registry_root_ref;
    }

    print $fh "tunnel_ssh=on\n" if ($state->{transport}->{ssh_enabled} // '') eq "on";
    print $fh "tunnel_host=$state->{transport}->{ssh_tunnel}\n" if length($state->{transport}->{ssh_tunnel} // '');
    print $fh "tunnel_https=on\n" if ($state->{transport}->{https_enabled} // '') eq "on";
    print $fh "https_mode=$state->{transport}->{https_mode}\n" if length($state->{transport}->{https_mode} // '');
    print $fh "sni_host=$state->{transport}->{sni_host}\n" if length($state->{transport}->{sni_host} // '');

    close $fh;
    return 1;
}

sub load_config_json {
    my (%args) = @_;
    my $state = $args{state} or die "load_config_json: missing state";
    my $file  = $args{file}  or die "load_config_json: missing file";
    my $argv  = $args{argv}  || [];
    my $has_lang_override = defined($argv->[0])
                          && $argv->[0] eq '/LANG'
                          && defined($argv->[1])
                          && length($argv->[1]);

    return 0 unless -e $file;

    open my $fh, '<', $file or die "Could not open $file: $!";
    local $/;
    my $json = <$fh>;
    close $fh;

    my $loaded = decode_json($json);

    for my $section (qw(app startup security transport connect runtime)) {
        next unless ref($loaded->{$section}) eq 'HASH';
        $state->{$section} ||= {};
        for my $k (keys %{ $loaded->{$section} }) {
            next if $has_lang_override && $section eq 'app' && $k eq 'lang';
            $state->{$section}{$k} = $loaded->{$section}{$k};
        }
    }

    return 1;
}

sub save_config_json {
    my (%args) = @_;
    my $state = $args{state} or die "save_config_json: missing state";
    my $file  = $args{file}  or die "save_config_json: missing file";

    my $to_save = {
        app => {
            lang => $state->{app}->{lang},
        },

        startup => {
            autoconnect => $state->{startup}->{autoconnect},
            no_splash   => $state->{startup}->{no_splash},
            autorun     => $state->{startup}->{autorun},
        },

        security => {
            no_ipv6            => $state->{security}->{no_ipv6},
            dns_leak_protect   => $state->{security}->{dns_leak_protect},
            killswitch_enabled => $state->{security}->{killswitch_enabled},
            adblock_enabled    => $state->{security}->{adblock_enabled},
        },

        transport => {
            socks_enabled   => $state->{transport}->{socks_enabled},
            socks_ip        => $state->{transport}->{socks_ip},
            socks_port      => $state->{transport}->{socks_port},
            socks_noauth    => $state->{transport}->{socks_noauth},
            ssh_enabled     => $state->{transport}->{ssh_enabled},
            ssh_tunnel      => $state->{transport}->{ssh_tunnel},
            https_enabled   => $state->{transport}->{https_enabled},
            https_mode      => $state->{transport}->{https_mode},
            sni_host        => $state->{transport}->{sni_host},
        },

        connect => {
            token          => $state->{connect}->{token},
            server_display => $state->{connect}->{server_display},
            timeout        => $state->{connect}->{timeout},
            port           => $state->{connect}->{port},
            proto          => $state->{connect}->{proto},
            tls_cipher     => $state->{connect}->{tls_cipher},
            random_port    => $state->{connect}->{random_port},
            mssfix         => $state->{connect}->{mssfix},
            adapter          => $state->{connect}->{adapter},
            tap_adapter_name => $state->{connect}->{tap_adapter_name},
            tap_adapter_guid    => $state->{connect}->{tap_adapter_guid},
            cryptostorm_tap_guid => $state->{connect}->{cryptostorm_tap_guid},
            bind_ip             => $state->{connect}->{bind_ip},
        },
    };

    open my $fh, '>', $file or die "Could not write $file: $!";
    print $fh JSON::PP->new->utf8->pretty->encode($to_save);
    close $fh;

    return 1;
}

sub load_config {
    my (%args) = @_;
    my $state       = $args{state}       or die "load_config: missing state";
    my $json_file   = $args{json_file}   or die "load_config: missing json_file";

    # prefer json
    if (-e $json_file) {
        return load_config_json(%args, file => $json_file);
    }

    # fallback to legacy import
    my $loaded = load_legacy_config_ini(%args);

    # write json once imported
    save_config_json(state => $state, file => $json_file) if $loaded;

    return $loaded;
}

sub save_config {
    my (%args) = @_;
    my $state     = $args{state}     or die "save_config: missing state";
    my $json_file = $args{json_file} or die "save_config: missing json_file";

    return save_config_json(state => $state, file => $json_file);
}

1;
