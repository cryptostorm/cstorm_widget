package OptionsWindow;

use strict;
use warnings;
use Exporter qw(import);
use Tkx;

our @EXPORT_OK = qw(build_options_window);

sub build_options_window {
    my (%args) = @_;

    my $state   = $args{state}   or die "build_options_window: missing state";
    my $ui      = $args{ui}      or die "build_options_window: missing ui";
    my $L       = $args{L}       or die "build_options_window: missing L";
    my $lang    = $args{lang}    or die "build_options_window: missing lang";
    my $servers   = $args{servers}   || [];
    my $VERSION   = $args{version}   // '';
    my $callbacks = $args{callbacks} || {};

	my $refresh_ui_from_state     = $callbacks->{refresh_ui_from_state};
    my $backtomain                = $callbacks->{backtomain};
    my $reset_dns_to_dhcp_btn_cmd = $callbacks->{reset_dns_to_dhcp_btn_cmd};
    my $do_error                  = $callbacks->{do_error} || sub { };
    my $is_valid_ip               = $callbacks->{is_valid_ip} || \&_local_is_valid_ip;
	my $is_xray_sni = $callbacks->{is_xray_sni} or die "missing is_xray_sni callback";


 $ui->{opt_main}{world_img} = $ui->{opt_main}{frame}->new_ttk__label(
    -anchor => "nw", 
	-justify => "center", 
	-image => 'opticon', 
	-compound => 'top', 
	-text => "Widget v$VERSION\n" .
	         "OpenVPN: $state->{app}->{ovpn_ver}\n" .
			 "OpenSSL: $state->{app}->{ossl_ver}");
$ui->{opt_main}{back_btn} = $ui->{opt_main}{frame}->new_ttk__button(-text => $L->{$lang}{TXT_BACK}, -command => $backtomain);
$ui->{opt_main}->{ow}->g_bind("<Escape>", sub { $ui->{opt_main}{back_btn}->invoke(); });
Tkx::update('idletasks');

# Create opt_main tabs(notebook)/frames
$ui->{opt_main}->{tabs} = $ui->{opt_main}->{ow}->new_ttk__notebook(-height => 0, -width => 0);
$ui->{opt_main}->{tab_frame}->{1} = $ui->{opt_main}->{tabs}->new_ttk__frame();
$ui->{opt_main}->{tab_frame}->{2} = $ui->{opt_main}->{tabs}->new_ttk__frame();
$ui->{opt_main}->{tab_frame}->{3} = $ui->{opt_main}->{tabs}->new_ttk__frame();
$ui->{opt_main}->{tab_frame}->{4} = $ui->{opt_main}->{tabs}->new_ttk__frame();
$ui->{opt_main}->{tabs}->add($ui->{opt_main}->{tab_frame}->{1}, -text => $L->{$lang}{TXT_STARTUP});
$ui->{opt_main}->{tabs}->add($ui->{opt_main}->{tab_frame}->{2}, -text => $L->{$lang}{TXT_CONNECTING});
$ui->{opt_main}->{tabs}->add($ui->{opt_main}->{tab_frame}->{3}, -text => $L->{$lang}{TXT_SECURITY});
$ui->{opt_main}->{tabs}->add($ui->{opt_main}->{tab_frame}->{4}, -text => $L->{$lang}{TXT_ADVANCED});

$ui->{opt_startup}->{splash_check} = $ui->{opt_main}->{tab_frame}->{1}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_NO_SPLASH}, -variable => \$state->{startup}->{no_splash}, -onvalue => "on", -offvalue => "off");
$ui->{opt_startup}->{autocon_check} = $ui->{opt_main}->{tab_frame}->{1}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_CONNECT}, -variable => \$state->{startup}->{autoconnect}, -onvalue => "on", -offvalue => "off");
$ui->{opt_startup}->{autorun_check} = $ui->{opt_main}->{tab_frame}->{1}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_START}, -variable => \$state->{startup}->{autorun}, -onvalue => "on", -offvalue => "off");

# Blank lines for padding
$ui->{opt_main}->{tab_frame}->{1}->new_ttk__label(-text => "                           \n                           \n")->g_grid(-column => 0, -row => 0, -sticky => "nw");
$ui->{opt_startup}->{splash_check}->g_grid(-column => 0, -row => 1, -sticky => "w");
$ui->{opt_startup}->{autocon_check}->g_grid(-column => 0, -row => 2, -sticky => "w");
$ui->{opt_startup}->{autorun_check}->g_grid(-column => 0, -row => 3, -sticky => "w");

$ui->{opt_connecting}->{port_lbl} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PORT});
$ui->{opt_connecting}->{port_lbl}->g_pack(qw/-anchor n/);
$ui->{opt_connecting}->{port_entry} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__entry(-textvariable => \$state->{connect}->{port}, -width => 6, -state => "normal");
$ui->{opt_connecting}->{port_entry}->g_pack();
$ui->{opt_connecting}->{port_entry}->g_bind('<FocusOut>', sub {
    $refresh_ui_from_state->($state, $ui) if $refresh_ui_from_state;
});
$ui->{opt_connecting}->{proto_lbl} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PROTOCOL});
$ui->{opt_connecting}->{proto_lbl}->g_pack();

$ui->{opt_connecting}->{proto_combo} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__combobox(
    -textvariable => \$state->{connect}->{proto},
    -values => ["UDP", "TCP"],
    -width => 4,
    -state => (($state->{transport}->{ssh_enabled} eq "on") || 
               ($state->{transport}->{https_enabled} eq "on") || 
               ($state->{transport}->{socks_enabled} eq "on")) ? "disabled" : "readonly"
);
$ui->{opt_connecting}->{proto_combo}->g_pack();

$ui->{opt_connecting}->{timeout_lbl} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__label(-text => $L->{$lang}{TXT_TIMEOUT});
$ui->{opt_connecting}->{timeout_lbl}->g_pack();
my @timeouts = (60, 120, 180, 240);
$ui->{opt_connecting}->{timeout_combo} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__combobox(-textvariable => \$state->{connect}->{timeout}, -values => \@timeouts, -width => 4, -state => "readonly");
$ui->{opt_connecting}->{timeout_combo}->g_pack();
$ui->{opt_connecting}->{random_port_check} = $ui->{opt_main}->{tab_frame}->{2}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_RANDOM_PORT}, -variable => \$state->{connect}->{random_port}, -onvalue => "on", -offvalue => "off", -command => sub { port_random(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); }, -state => "normal");
$ui->{opt_connecting}->{random_port_check}->g_pack(qw/-anchor n/);
 
 

$ui->{opt_advanced}->{top_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => $L->{$lang}{TXT_ADVANCED_OPTIONS} . "\n");
# Most of these align based on the width of the text, so hardcoding English here (except for errors).
$ui->{opt_advanced}->{mssfix_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "--mssfix:  ");
$ui->{opt_advanced}->{mssfix_combo} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__combobox(-textvariable => \$state->{connect}->{mssfix}, -values => ['disabled','1300','1400','1500','1600'], -width => 14, -state => "readonly");


my @adapters = ('TAP');
$state->{connect}->{adapter} = $adapters[0];
$ui->{opt_advanced}->{adapter_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Adapter");
$ui->{opt_advanced}->{adapter_combo} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__combobox(-textvariable => \$state->{connect}->{adapter}, -values => \@adapters, -width => 14, -state => "disabled");
my @bind_ips = $state->{connect}->{bind_ip} eq "Any address" ? ($state->{connect}->{bind_ip}) : ($state->{connect}->{bind_ip}, "Any address");
foreach (`ipconfig /all|findstr "IPv. add"|findstr /v Link`) {
 if (/.*:\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/) {
  if ($1 !~ /^169\.254\./) {
   push(@bind_ips,"$1") unless "$1" eq $bind_ips[0];
  }
 }
 if (/.*:\s([a-f0-9:]+)\(Pre/) {
  push(@bind_ips,"$1") unless "$1" eq $bind_ips[0];
 }
}
$state->{connect}->{bind_ip} = $bind_ips[0];
$ui->{opt_advanced}->{bind_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Bind to IP:  ");
$ui->{opt_advanced}->{bind_combo} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__combobox(-textvariable => \$state->{connect}->{bind_ip}, -values => \@bind_ips, -width => 14, -state => "readonly");

$ui->{opt_advanced}->{socks_ip_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "IP", -state => (($state->{transport}->{socks_enabled} eq "on") ? "normal" : "disabled"));
$ui->{opt_advanced}->{socks_ip_entry} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__entry(-textvariable => \$state->{transport}->{socks_ip}, -width => 14, -state => (($state->{transport}->{socks_enabled} eq "on") ? "normal" : "disabled"), -validate => "focusout", -validatecommand => sub { 
 unless ($is_valid_ip->($state->{transport}->{socks_ip})) {
  $do_error->($L->{$lang}{ERR_INVALID_SOCKS_IP} . "\n");
  return 1;
 }
});
$ui->{opt_advanced}->{socks_port_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Port", -state => (($state->{transport}->{socks_enabled} eq "on") ? "normal" : "disabled"));
$ui->{opt_advanced}->{socks_port_entry} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__entry(-textvariable => \$state->{transport}->{socks_port}, -width => 6, -state => (($state->{transport}->{socks_enabled} eq "on") ? "normal" : "disabled"));
$ui->{opt_advanced}->{socks_user_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Username", -state => (($state->{transport}->{socks_enabled} eq "on") && ($state->{transport}->{socks_noauth} eq "off")) ? "normal" : "disabled");
$ui->{opt_advanced}->{socks_user_entry} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__entry(-text => "", -textvariable => \$state->{transport}->{socks_user}, -state => (($state->{transport}->{socks_enabled} eq "on") && ($state->{transport}->{socks_noauth} eq "off")) ? "normal" : "disabled");
$ui->{opt_advanced}->{socks_pass_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Password", -state => (($state->{transport}->{socks_enabled} eq "on") && ($state->{transport}->{socks_noauth} eq "off")) ? "normal" : "disabled");
$ui->{opt_advanced}->{socks_pass_entry} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__entry(-text => "", -textvariable => \$state->{transport}->{socks_pass}, -state => (($state->{transport}->{socks_enabled} eq "on") && ($state->{transport}->{socks_noauth} eq "off")) ? "normal" : "disabled", -show => '*');
$ui->{opt_advanced}->{socks_noauth_check} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__checkbutton(-state => (($state->{transport}->{socks_enabled} eq "on") ? "normal" : "disabled"), -text => "No username/password needed", -variable => \$state->{transport}->{socks_noauth}, -onvalue => "on", -offvalue => "off", -command => sub { socks_noauth_check_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); }); 
$ui->{opt_advanced}->{socks_check} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__checkbutton(-text => "Use SOCKS proxy", -variable => \$state->{transport}->{socks_enabled}, -onvalue => "on", -offvalue => "off", -state => ((($state->{transport}->{ssh_enabled} eq "on") || ($state->{transport}->{https_enabled} eq "on")) ? "disabled" : "normal"), -command => sub { socks_check_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); });
$ui->{opt_advanced}->{ssh_check} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__checkbutton(-text => "Use SSH tunneling", -variable => \$state->{transport}->{ssh_enabled}, -onvalue => "on", -offvalue => "off", -state => ((($state->{transport}->{https_enabled} eq "on") || ($state->{transport}->{socks_enabled} eq "on")) ? "disabled" : "normal"), -command => sub { ssh_check_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); });
$ui->{opt_advanced}->{https_check} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__checkbutton(-text => "Use HTTPS tunneling", -variable => \$state->{transport}->{https_enabled}, -onvalue => "on", -offvalue => "off", -state => ((($state->{transport}->{ssh_enabled} eq "on") || ($state->{transport}->{socks_enabled} eq "on")) ? "disabled" : "normal"), -command => sub { https_check_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); });

$ui->{opt_advanced}->{stunnel_radio} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__radiobutton(
    -text     => "stunnel",
    -variable => \$state->{transport}->{https_mode},
    -value    => "stunnel",
    -state    => ($state->{transport}->{https_enabled} eq "on") ? "normal" : "disabled",
    -command  => sub { stunnel_radio_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); },
);

$ui->{opt_advanced}->{xray_radio} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__radiobutton(
    -text     => "Xray",
    -variable => \$state->{transport}->{https_mode},
    -value    => "xray",
    -state    => ($state->{transport}->{https_enabled} eq "on") ? "normal" : "disabled",
    -command  => sub { xray_radio_cmd(
        state   => $state,
        ui      => $ui,
        refresh => $refresh_ui_from_state); },
);

my @tunnel_names = grep { defined $_ && !ref($_) && length $_ }
                   map  { ref($_) eq 'HASH' ? ($_->{name} // '') : '' }
                   @$servers;

my %valid_tunnel_name = map { $_ => 1 } @tunnel_names;
my $selected_ssh_tunnel = $state->{transport}->{ssh_tunnel};
if (ref($selected_ssh_tunnel) eq 'HASH' && defined $selected_ssh_tunnel->{name}) {
    $selected_ssh_tunnel = $selected_ssh_tunnel->{name};
}
elsif (ref($selected_ssh_tunnel)) {
    $selected_ssh_tunnel = '';
}
$selected_ssh_tunnel = '' unless defined $selected_ssh_tunnel;
$selected_ssh_tunnel =~ s/^\s+|\s+$//g;
$selected_ssh_tunnel = '' if $selected_ssh_tunnel =~ /^HASH\(0x[0-9a-f]+\)$/i;

if (!length($selected_ssh_tunnel) || !$valid_tunnel_name{$selected_ssh_tunnel}) {
    $selected_ssh_tunnel = @tunnel_names ? $tunnel_names[0] : '';
}
$state->{transport}->{ssh_tunnel} = $selected_ssh_tunnel;

$ui->{opt_advanced}->{ssh_tunnel_combo} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__combobox(
    -textvariable => \$state->{transport}->{ssh_tunnel},
    -values       => \@tunnel_names,
    -width        => 23,
    -state        => ($state->{transport}->{ssh_enabled} eq "on") ? "readonly" : "disabled",
);

my @xray_snis = @{ $state->{transport}->{xray_snis_order} || [] };

$ui->{opt_advanced}->{sni_entry} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__entry(
    -textvariable    => \$state->{transport}->{sni_host},
    -width           => 23,
    -validate        => 'focusout',
    -validatecommand => sub {
        stunnel_sni_focusout_cmd(
            state       => $state,
            ui          => $ui,
            refresh     => $refresh_ui_from_state,
            parent      => $ui->{opt_main}->{ow},
            is_xray_sni => $is_xray_sni,
        );
    },
);


$ui->{opt_advanced}->{xray_sni_combo} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__combobox(
    -textvariable => \$state->{transport}->{sni_host},
    -values       => \@xray_snis,
    -width        => 23,
    -state        => 'readonly',
);

$ui->{opt_advanced}->{reset_dns_to_dhcp_btn} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__button(-text => "Reset DNS to DHCP", -command => $reset_dns_to_dhcp_btn_cmd);

$ui->{opt_advanced}->{tunnel_lbl} = $ui->{opt_main}->{tab_frame}->{4}->new_ttk__label(-text => "Tunnel host:", -state => "disabled");

$ui->{opt_advanced}->{top_lbl}->g_grid(-column => 0, -row => 0);
$ui->{opt_advanced}->{mssfix_lbl}->g_grid(-column => 0, -row => 1);
$ui->{opt_advanced}->{mssfix_combo}->g_grid(-column => 1, -row => 1);
$ui->{opt_advanced}->{reset_dns_to_dhcp_btn}->g_grid(-column => 2, -row => 1, -rowspan => 4, -columnspan => 2, -stick => "nswe");
$ui->{opt_advanced}->{adapter_lbl}->g_grid(-column => 0, -row => 2);
$ui->{opt_advanced}->{adapter_combo}->g_grid(-column => 1, -row => 2);
$ui->{opt_advanced}->{bind_lbl}->g_grid(-column => 0, -row => 3);
$ui->{opt_advanced}->{bind_combo}->g_grid(-column => 1, -row => 3);
$ui->{opt_advanced}->{socks_check}->g_grid(-column => 0, -row => 4);
$ui->{opt_advanced}->{socks_ip_lbl}->g_grid(-column => 0, -row => 5);
$ui->{opt_advanced}->{socks_ip_entry}->g_grid(-column => 1, -row => 5);
$ui->{opt_advanced}->{socks_port_lbl}->g_grid(-column => 2, -row => 5);
$ui->{opt_advanced}->{socks_port_entry}->g_grid(-column => 3, -row => 5);
$ui->{opt_advanced}->{socks_user_lbl}->g_grid(-column => 0, -row => 6);
$ui->{opt_advanced}->{socks_user_entry}->g_grid(-column => 1, -row => 6);
$ui->{opt_advanced}->{socks_pass_lbl}->g_grid(-column => 2, -row => 6);
$ui->{opt_advanced}->{socks_pass_entry}->g_grid(-column => 3, -row => 6);
$ui->{opt_advanced}->{socks_noauth_check}->g_grid(-column => 0, -row => 7, -columnspan => 2);
$ui->{opt_advanced}->{ssh_check}->g_grid(-column => 0, -row => 8);
$ui->{opt_advanced}->{https_check}->g_grid(-column => 1, -row => 8);
$ui->{opt_advanced}->{stunnel_radio}->g_grid(-column => 2, -row => 9, -sticky => "w");
$ui->{opt_advanced}->{xray_radio}->g_grid(-column => 3, -row => 9, -sticky => "w");
$ui->{opt_advanced}->{tunnel_lbl}->g_grid(-column => 0, -row => 9);
$ui->{opt_advanced}->{ssh_tunnel_combo}->g_grid(-column => 1, -row => 9);
$ui->{opt_advanced}->{sni_entry}->g_grid(-column => 1, -row => 9);

$ui->{opt_security}->{tls_cipher_lbl} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__label(-text => "TLS cipher:");
$ui->{opt_security}->{tls_cipher_combo} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__combobox(-textvariable => \$state->{connect}->{tls_cipher}, -values => ['secp521r1','Ed25519','Ed448','ML-DSA-87'], -width => 11, -state=> 'readonly', -validate => "focusout");
$ui->{opt_security}->{tls_cipher_combo}->g_bind('<<ComboboxSelected>>', sub { $refresh_ui_from_state->($state, $ui); } );
$ui->{opt_security}->{data_cipher_lbl} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__label(-text => "data cipher: ");
$ui->{opt_security}->{data_cipher_combo} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__combobox(-textvariable => \$state->{connect}->{data_cipher}, -values => ['AES-256-GCM','CHACHA20-POLY1305'], -width => 20, -state=> 'readonly');

# Empty label for padding
$ui->{opt_main}->{tab_frame}->{3}->new_ttk__label(-text => " ");

$ui->{opt_security}->{disable_ipv6_check} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DISABLE_IPV6}, -variable => \$state->{security}->{no_ipv6}, -onvalue => "on", -offvalue => "off");
$ui->{opt_security}->{dnsleak_check} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DNS_LEAK}, -variable => \$state->{security}->{dns_leak_protect}, -onvalue => "on", -offvalue => "off");
$ui->{opt_security}->{killswitch_check} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_KILLSWITCH_ENABLE}, -variable => \$state->{security}->{killswitch_enabled}, -onvalue => "on", -offvalue => "off");
$ui->{opt_security}->{ts_check} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_ADBLOCK}, -variable => \$state->{security}->{adblock_enabled}, -onvalue => "on", -offvalue => "off");
$ui->{opt_security}->{tunnelcrack_check} = $ui->{opt_main}->{tab_frame}->{3}->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_TUNNELCRACK}, -variable => \$state->{security}->{tunnelcrack_enabled}, -onvalue => "on", -offvalue => "off");

# Empty label for padding
$ui->{opt_main}->{tab_frame}->{3}->new_ttk__label(-text => "\n")->g_grid(-column => 0, -row => 0);

$ui->{opt_security}->{tls_cipher_lbl}->g_grid(-column => 0, -row => 1, -sticky => "e");
$ui->{opt_security}->{tls_cipher_combo}->g_grid(-column => 1, -row => 1, -sticky => "w");
$ui->{opt_security}->{data_cipher_lbl}->g_grid(-column => 2, -row => 1, -sticky => "e");
$ui->{opt_security}->{data_cipher_combo}->g_grid(-column => 3, -row => 1, -sticky => "w");

$ui->{opt_security}->{tls_cipher_combo}->configure(-validatecommand => sub { tls_cipher_combo_cmd(
            state   => $state,
            ui      => $ui,
            refresh => $refresh_ui_from_state); } );

# Empty label for padding
$ui->{opt_main}->{tab_frame}->{3}->new_ttk__label(-text => " ")->g_grid(-column => 0, -row => 2, -columnspan => 4);

$ui->{opt_security}->{disable_ipv6_check}->g_grid(-column => 0, -row => 3, -columnspan => 4, -sticky => "w");
$ui->{opt_security}->{dnsleak_check}->g_grid(-column => 0, -row => 4, -columnspan => 4, -sticky => "w");
$ui->{opt_security}->{killswitch_check}->g_grid(-column => 0, -row => 5, -columnspan => 4, -sticky => "w");
$ui->{opt_security}->{ts_check}->g_grid(-column => 0, -row => 6, -columnspan => 4, -sticky => "w");
$ui->{opt_security}->{tunnelcrack_check}->g_grid(-column => 0, -row => 7, -columnspan => 4, -sticky => "w");

$ui->{opt_main}{frame}->g_grid(-column => 0, -row => 0, -sticky => "nswe");
$ui->{opt_main}{world_img}->g_grid(-column => 0, -row => 0);
$ui->{opt_main}{back_btn}->g_grid(-column => 0, -row => 2, -sticky => "nswe");
$ui->{opt_main}{tabs}->g_grid(-column => 1, -row => 0, -sticky => "nswe");

}

sub port_random {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    $refresh->($state, $ui);
    return 1;
}

sub tls_cipher_combo_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    $refresh->($state, $ui);
    return 1;
}

sub socks_noauth_check_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    $refresh->($state, $ui);
    return 1;
}

sub socks_check_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    if (($state->{transport}->{socks_enabled} // 'off') eq 'on') {
        $state->{transport}->{ssh_enabled}   = 'off';
        $state->{transport}->{https_enabled} = 'off';
    }

    $refresh->($state, $ui);
    return 1;
}

sub ssh_check_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    if (($state->{transport}->{ssh_enabled} // 'off') eq 'on') {
        $state->{transport}->{socks_enabled} = 'off';
        $state->{transport}->{https_enabled} = 'off';
    }

    $refresh->($state, $ui);
    return 1;
}

sub https_check_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    if (($state->{transport}->{https_enabled} // 'off') eq 'on') {
        $state->{transport}->{ssh_enabled}   = 'off';
        $state->{transport}->{socks_enabled} = 'off';

        $state->{transport}->{https_mode} = 'stunnel'
            unless defined $state->{transport}->{https_mode}
                && $state->{transport}->{https_mode} =~ /^(stunnel|xray)$/;
    }

    $refresh->($state, $ui);
    return 1;
}

sub stunnel_radio_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    $state->{transport}->{https_mode} = 'stunnel';
    $refresh->($state, $ui);
    return 1;
}

sub xray_radio_cmd {
    my (%args) = @_;
    my $state   = $args{state}   or die "missing state";
    my $ui      = $args{ui}      or die "missing ui";
    my $refresh = $args{refresh} or die "missing refresh callback";

    $state->{transport}->{https_mode} = 'xray';
    $refresh->($state, $ui);
    return 1;
}

sub _local_is_valid_ip {
    my ($ip) = @_;
    return 0 unless defined $ip && length $ip;
    return 1 if $ip =~ /:/;
    return 1 if $ip =~ /^(?:\d{1,3}\.){3}\d{1,3}$/ && !grep { $_ > 255 } split(/\./, $ip);
    return 0;
}

sub stunnel_sni_focusout_cmd {
    my (%args) = @_;
    my $state       = $args{state}       or die "missing state";
    my $ui          = $args{ui}          or die "missing ui";
    my $refresh     = $args{refresh}     or die "missing refresh callback";
    my $parent      = $args{parent};
    my $is_xray_sni = $args{is_xray_sni} or die "missing is_xray_sni callback";
    my $default     = $args{default_stunnel_sni} // 'www.yahoo.com';

    my $host = $state->{transport}->{sni_host} // '';
    $host =~ s/^\s+//;
    $host =~ s/\s+$//;
    $state->{transport}->{sni_host} = $host;

    if (($state->{transport}->{https_enabled} // 'off') eq 'on'
        && ($state->{transport}->{https_mode} // 'stunnel') eq 'stunnel'
        && $is_xray_sni->($state, $host)) {

        Tkx::tk___messageBox(
            -parent  => $parent,
            -type    => 'ok',
            -icon    => 'error',
            -title   => 'cryptostorm.is client',
            -message => "That SNI is reserved for Xray. Choose another SNI or switch to Xray.",
        );

        $state->{transport}->{sni_host} = $default;
    }

    $refresh->($state, $ui);
    return 1;
}

1;
