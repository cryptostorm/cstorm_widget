our $VERSION;
BEGIN {
    $VERSION = "3.65";
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
my $bit = 64;
if (-d "\\Program Files\\Cryptostorm Client\\bin") {
 chdir("\\Program Files\\Cryptostorm Client\\bin\\");
 $bit = 32;
}
if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
 chdir("\\Program Files (x86)\\Cryptostorm Client\\bin\\");
}
use strict;
use warnings;
use threads;
use threads::shared;
use Tkx;
Tkx::encoding("system", "utf-8");
use Tkx::SplashScreen;
use Win32::GUI;
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa373247%28v=vs.85%29.aspx
use constant WM_POWERBROADCAST => 0x218;
use constant PBT_APMSUSPEND => 0x4;
use constant PBT_APMRESUMEAUTOMATIC => 0x12;
use constant PBT_APMRESUMECRITICAL => 0x6;
if (defined &Win32::SetChildShowWindow) {
 Win32::SetChildShowWindow(0);
}
use Digest::SHA qw(sha512_hex);
use File::Copy qw(copy);
use IO::Socket;
use IO::Socket::SSL;
use LWP::UserAgent;
use Socket;
use Socket6;
use Win32::AbsPath;
use Win32::File::VersionInfo;
use Win32::Process;
use Win32::Process::List;
use Win32::Event;
use Win32::Clipboard;
use Win32::Service;
# for updating the nodelist, so it doesn't require DNS
my @csnu_ips = (
    { ip => '2a00:c98:2030:a005:c0ff:eeee:eeee:eeee', family => AF_INET6 },
    { ip => '46.165.221.67', family => AF_INET },
);
my $wintunexe = Win32::GetFullPathName("cswintun.exe");
my $clip = Win32::Clipboard();
use Win32::TieRegistry qw(REG_DWORD REG_MULTI_SZ REG_SZ),(Delimiter => "/");
$Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'} = {};
my $regkey = $Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'};
use Win32::IPHelper;
our $self = Win32::AbsPath::Fix "$0";
our $BUILDVERSION;
our ($ovpnver, $osslver, $verstuff, $final_data, $counter, $doupgrade, $total_size, $fh, $dnsleak_var);
my $manport;
our ($fixdns_btn);
our @animation = qw( \ | / -- );
our @output;
our @resolved_ips;
our @addresses;
our @remote_random = ();
our $rt;
our $manpass;
our $update_err : shared;
our $logfile;
our $chosen_ip;
our $ipv6_ip_i_was_connected_to;
my $lang;
my $sel_lang;
my $localip;
my $localip6;
if (defined($ARGV[0]) && ($ARGV[0] eq "/LANG")) {
 if (defined($ARGV[1])) {
  $lang = $ARGV[1];
  $sel_lang = $ARGV[1];
 }
}
if (!$lang) {
 $lang = "English";
 $sel_lang = "English";
}
my $foo = GetFileVersionInfo ( "$self" );
if ($foo) {
 $BUILDVERSION = $foo->{FileVersion};
}
else {
 $BUILDVERSION = "3.64.0.0";
}
our $iwasconnected = 0;
my $masterpid;
my %stupidstrictrefs;
my @log_lines: shared;
my $stop: shared = 0;
my $done : shared = 0;
my $nodebuf : shared;
my $status : shared;
my $pid : shared;
my $o_version_buf : shared;
my $o_done3 : shared;
my $latest : shared;
my $amsg : shared;
our @recover;
my $authfile = '..\user\config.ini';
my $hashfile = '..\user\client.dat';
my $cacertfile = '..\user\ca.crt';
my $cclientfile = '..\user\client.crt';
my $clientkey  = '..\user\client.key';
my $nodelistfile = '..\user\nodelist.txt';
my $c = 0;
my $server = "";
my $widget_update_var;
our $VPNfh;
our $updatethread;
our $o_thread3;
my ( $ovpnline, $vpnexe, $osslexe, $dnscexe, $h);
my ($frame1, $frame2, $frame3, $frame4, $saveoption, $password, $userlbl, $passlbl, $connect, $cancel, $pass,
    $save, $progress, $pbar, $pbarval, $statuslbl, $statusvar, $token_textbox, $token, $worldimage, $logbox, $logbox_index, 
	$scroll, $errorimage, $server_textbox, $disp_server, $tripimage, $server_host, $update, $menu, $send, $options);
my ($autocon, $autocon_var, $autorun, $autorun_var, $o_frame1, $o_worldimage, $back, $o_tabs, $o_innerframe1,
    $o_innerframe2, $o_innerframe3, $o_innerframe4, $derp);
my $kcxt=0;
my $autosplash_var = "";
my $dnscrypt_var = "on";
my $killswitch_var = "off";
my $ts_var = "on";
our ($TrayIcon,$TrayWinHidden,$TrayNotify,$TrayMenu);
my $showtiponce = 0;
my ($x, $y, $width, $height);
our (@servers, @disp_servers);
my $upgrade = 0;
my $balloon_msg;
my $idle = 0;
my $update_var = "on";
my $randomize_it = "off";
my $tokillornot;
our @msgs;
our $thread;
my @tmparray;
my $tmpline = "";
my $vpn_args = "";
$SIG{'TERM'} = 'TERM_handler';
$SIG{'ABRT'} = 'TERM_handler';
$SIG{'INT'} = 'TERM_handler';
$SIG{'KILL'} = 'TERM_handler';
$SIG{'HUP'} = 'TERM_handler';
if (-e $ENV{'TEMP'} . '\client.dat') {
 copy($ENV{'TEMP'} . '\client.dat',$hashfile);
 unlink($ENV{'TEMP'} . '\client.dat');
}
if (-e $ENV{'TEMP'} . '\config.ini') {
 copy($ENV{'TEMP'} . '\config.ini',$authfile);
 unlink($ENV{'TEMP'} . '\config.ini');
}
my $noipv6_var = "off";
my $tmp_noipv6_var;
my $tmp_dnscrypt_var;
my $tmp_killswitch_var;
our $port_var = "443";
my $proto_var = "UDP";
my @protos = ('UDP', 'TCP');
my @tlses = ('secp521r1','Ed25519','Ed448','ML-DSA-87');
my $tls_sel = 'secp521r1';
my $cipher_sel = 'AES-256-GCM';
my $selected_adv_opt2 = "1400";
my $selected_adv_opt3 = "adaptive";
my $selected_adv_opt4 = "Any address";
my $adv_socks_opt = "off";
my $adv_ssh_opt = "off";
my $adv_https_opt = "off";
my $selected_tunnel_opt;
my $local_tunnel_port;
my $tunnel_check_counter = 0;
my $adv_socks_ip = "127.0.0.1";
my $adv_socks_port = 9150;
my $adv_socks_noauth_opt = "on";
my $adv_socks_user_var = "";
my $adv_socks_pass_var = "";
my $timeout_var = 60;
if (-e "$authfile") {
 open(CREDS,"$authfile");
 while (<CREDS>) {
  if ((/^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
      (/^([a-f0-9]{128})$/)) {
   $token = $1;
  }
  if (/^timeout=([0-9]+)$/) {
   $timeout_var = $1;
  }
  if (/^noipv6=(.*)$/) {
   $noipv6_var = $1;
  }
  if (/^dnsleak=(.*)$/) {
   $dnsleak_var = $1;
  }
  if (/^port=(.*)$/) {
   $port_var = $1;
  }
  if (/^proto=(.*)$/) {
   $proto_var = $1;
  }
  if (/^node=(.*)$/) {
   $disp_server = $1;
  }
  if (/^autocon=(.*)$/) {
   $autocon_var = $1;
  }
  if (/^autosplash=(.*)$/) {
   $autosplash_var = $1;
  }
  if (/^autorun=(.*)$/) {
   $autorun_var = $1;
  }
  if (/^checkforupdate=(.*)$/) {
   $update_var = $1;
  }
  if (/^dnscrypt=(.*)$/) {
   $dnscrypt_var = $1;
  }
  if (/^killswitch=(.*)$/) {
   $killswitch_var = $1;
  }
  if (/^ts=(.*)$/) {
   $ts_var = $1;
  }
  if (/^tls_sel=(.*)$/) {
   $tls_sel = $1;
  }
  if (/^widget_update_var=(.*)$/) {
   $widget_update_var = $1;
  }
  if (/^randomport=(.*)$/) {
   $randomize_it = $1;
  }
  if ((/^lang=(.*)$/) && (defined $ARGV[0] && $ARGV[0] ne "/LANG")) {
   $lang = $1;
   $sel_lang = $1;
  }
  if (/^mssfix=(.*)$/) {
   $selected_adv_opt2 = $1;
  }
  if (/^route-method=(.*)$/) {
   $selected_adv_opt3 = $1;
  }
  if (/^bind=(.*)$/) {
   $selected_adv_opt4 = $1;
  }
  if (/^socks=on$/) {
   $adv_socks_opt = "on";
  }
  if (/^socks_ip=(.*)$/) {
   $adv_socks_ip = $1;
  }
  if (/^socks_port=(.*)$/) {
   $adv_socks_port = $1;
  }
  if (/^socks_noauth=(.*)$/) {
   if ($1 eq "off") {
    $adv_socks_noauth_opt = "off";
    $adv_socks_user_var = $regkey->{'SOCKS_USER'};
    $adv_socks_pass_var = $regkey->{'SOCKS_PASS'};
   }
  }
  if (/^tunnel_ssh=(.*)$/) {
   $adv_ssh_opt = $1;
  }
  if (/^tunnel_https=(.*)$/) {
   $adv_https_opt = $1;
  }
  if (/^tunnel_host=(.*)$/) {
   $selected_tunnel_opt = $1;
  }
 }
}
use utf8;
use Encode;
binmode(STDOUT, ":utf8");
sub load_lang_compat {
 my $file = shift;
 open my $fh, "<:encoding(UTF-8)", $file or die $!;
 my %lang;
 my $key;
 while (<$fh>) {
  chomp;
  next if /^\s*$/ || /^\s*#/;
  if (/^\S+/ && !/=/) {
   ($key) = split;
  } elsif (/^\s*(\w+)\s*=\s*(.+)$/ && defined $key) {
   my ($langcode, $val) = ($1, $2);
   $lang{$langcode}{$key} = $val;
  }
 }
 close $fh;
 return \%lang;
}
my $L = load_lang_compat('..\user\lang.txt');
my @langs;
my $earlymw = Tkx::widget->new(".");
$earlymw->g_wm_withdraw();
unless (defined $L->{$lang}{ERR_AUTH_FAIL}) {
 &do_error("Invalid language \"$lang\", reverting to English");
 $lang = "English";
}
my @missing;
foreach my $msg_key (sort keys %{$L->{'English'}}) {
 foreach my $lang_name (keys %$L) {
  push @langs, $lang_name unless grep { $_ eq $lang_name } @langs;
 }
 unless (defined $L->{$lang}{$msg_key}) {
  push @missing, $msg_key;
 }
}
if (@missing) {
 my $missed = join(", ", @missing);
 &do_error("Some entries are missing for '$lang': $missed");
}
Tkx::update();
$disp_server = $L->{$lang}{TXT_DEFAULT_SERVER} unless defined($disp_server);
our $hiddenornot : shared = "Hide";
Tkx::package_require("style");
Tkx::package_require('tooltip');
Tkx::style__use("as", -priority => 70);
Tkx::font_create("logo_font", -family => "Helvetica", -size => 10, -weight => "bold");
Tkx::font_create("token_font", -family => "Arial", -size => 10);
Tkx::image_create_photo("mainicon", -file => "..\\res\\greyworld.png");
Tkx::image_create_photo("mainicon2", -file => "..\\res\\world2.png");
Tkx::image_create_photo("opticon", -file => "..\\res\\world3.png");
Tkx::image_create_photo("opticon2", -file => "..\\res\\world4.png");
Tkx::image_create_photo("erroricon", -file => "..\\res\\gears.png");
Tkx::image_create_photo("b1", -file => "..\\res\\b1.png");
Tkx::image_create_photo("b2", -file => "..\\res\\b2.png");
Tkx::image_create_photo("b3", -file => "..\\res\\b3.png");
Tkx::image_create_photo("b4", -file => "..\\res\\b4.png");
Tkx::image_create_photo("b5", -file => "..\\res\\b5.png");
Tkx::image_create_photo("b6", -file => "..\\res\\b6.png");
Tkx::image_create_photo("g1", -file => "..\\res\\g1.png");
Tkx::image_create_photo("g2", -file => "..\\res\\g2.png");
Tkx::image_create_photo("g3", -file => "..\\res\\g3.png");
Tkx::image_create_photo("g4", -file => "..\\res\\g4.png");
Tkx::image_create_photo("g5", -file => "..\\res\\g5.png");
Tkx::image_create_photo("g6", -file => "..\\res\\g6.png");
Tkx::image_create_photo("r1", -file => "..\\res\\r1.png");
Tkx::image_create_photo("r2", -file => "..\\res\\r2.png");
Tkx::image_create_photo("r3", -file => "..\\res\\r3.png");
Tkx::image_create_photo("r4", -file => "..\\res\\r4.png");
Tkx::image_create_photo("r5", -file => "..\\res\\r5.png");
Tkx::image_create_photo("r6", -file => "..\\res\\r6.png");
Tkx::namespace_import("::tooltip::tooltip");
my $mw = Tkx::widget->new(".");
$mw->g_wm_withdraw();
if (Win32::IsAdminUser() != 1) {
 &do_error($L->{$lang}{ERR_NEED_ADMIN});
 exit;
}
my ($STRING, $MAJOR, $MINOR, $BUILD, $ID) = Win32::GetOSVersion();
if ($MAJOR < 6) {
 &do_error($L->{$lang}{ERR_OLD_WIN});
 &do_exit;
}
sub TERM_handler {
 if (defined($mw)) {
  $mw->g_wm_attributes('-topmost', 1);
  $mw->g_wm_attributes('-topmost', 0);
  $mw->g_wm_deiconify();
  $mw->g_raise();
  $mw->g_focus();
 }
 $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno",
                                     -message => $L->{$lang}{QUESTION_ANOTHERPROG1} . "\n" .
									             $L->{$lang}{QUESTION_ANOTHERPROG2} . "\n" .
									             $L->{$lang}{QUESTION_ANOTHERPROG3} . "\n",
                                     -icon => "question", -title => "cryptostorm.is client");
 if ($tokillornot eq "yes") {
  if ($token) {
   copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
   copy($authfile,$ENV{'TEMP'} . "\\config.ini");
  }
  &do_exit;
 }
}
my $cw = $mw->new_toplevel;
$cw->g_wm_withdraw();
Tkx::tk(appname => "cryptostorm.is client");
Tkx::wm_iconphoto($mw, "mainicon");
$vpnexe = "csvpn.exe";
$osslexe = "ossl.exe";
$dnscexe = "cs-dnsc-p.exe";
my $pi = Win32::Process::List->new();
$masterpid = $$;
my %procs = $pi->GetProcesses();
my $proccount = 0;
foreach my $pids ( keys %procs ) {
 next if $pids == $masterpid;
 if ($procs{$pids} =~ /csvpn/) {
  system(1,"TASKKILL /F /T /PID $pids");
 }
 if ($procs{$pids} =~ /^client.exe$/) {
  $proccount++;
  if ($proccount == 2) {
   $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
                                       -message => $L->{$lang}{QUESTION_ONLYONE1} . "\n" .
									               $L->{$lang}{QUESTION_ONLYONE2} . "\n",
                                       -icon => "question", -title => "cryptostorm.is client");
   if ($tokillornot eq "yes") {
    system(1,"TASKKILL /F /T /PID $pids");
   }
   if ($tokillornot eq "no") {
    system(1,"TASKKILL /F /T /PID $masterpid");
   }
  }
 }
}

if (-e "..\\user\\mydns.txt") {
 open my $handle, '<', "..\\user\\mydns.txt";
 chomp(@recover = <$handle>);
 close $handle;
 unlink("..\\user\\mydns.txt");
 &restore_dns;
}

&get_current_dns;
$verstuff = `$vpnexe --version 2>&1`;
if ($verstuff =~ /OpenVPN ([0-9\.]+)/) {
 $ovpnver = $1;
}
if ($verstuff =~ /OpenSSL ([0-9\.a-z]+)/) {
 $osslver = $1;
}

if ($autosplash_var ne "on") {
 my $sr = $mw->new_tkx_SplashScreen(
 -image      => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
 -width      => '480',
 -height     => '272',
 -show       => 1,
 -topmost    => 1,
 );
 Tkx::after(500 => sub {
  $sr->g_destroy();
  $mw->g_wm_deiconify();
  $mw->g_raise();
  $mw->g_focus();
 });
}
$mw->g_wm_protocol('WM_DELETE_WINDOW', sub {
 if (&isoncs > 0) {
  &hidewin;
 }
 else {
  &do_exit;
 }
});
$mw->g_wm_resizable(0,0);
Tkx::wm_title($mw, "cryptostorm widget v$VERSION");
$pbarval = 0;

$statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
Tkx::wm_attributes($mw, -toolwindow => 0, -topmost => 0);

$cw->g_wm_protocol('WM_DELETE_WINDOW', sub {
 &backtomain;
});
$cw->g_wm_resizable(0,0);
Tkx::wm_attributes($cw, -toolwindow => 0, -topmost => 0);
Tkx::wm_title($cw, $L->{$lang}{TXT_OPTIONS});
Tkx::wm_iconphoto($cw, "mainicon");
$o_frame1 = $cw->new_ttk__frame(-relief => "flat");
$o_worldimage = $o_frame1->new_ttk__label(-anchor => "nw", -justify => "center", -image => 'opticon', -compound => 'top', -text => "Widget v$VERSION\nBuild: $BUILDVERSION\nOpenVPN: $ovpnver\nOpenSSL: $osslver");
$back = $o_frame1->new_ttk__button(-text => $L->{$lang}{TXT_BACK}, -command => \&backtomain);
$cw->g_bind("<Escape>", sub { $back->invoke(); });
Tkx::update('idletasks');

$o_tabs = $cw->new_ttk__notebook(-height => 0, -width => 0);
$o_innerframe1 = $o_tabs->new_ttk__frame();
$o_innerframe2 = $o_tabs->new_ttk__frame();
$o_innerframe3 = $o_tabs->new_ttk__frame();
$o_innerframe4 = $o_tabs->new_ttk__frame();

my $powerw = Win32::GUI::Window->new();
$powerw->Hook(WM_POWERBROADCAST, \&power_event);
$powerw->Hide();

my $lbl_blank = $o_innerframe1->new_ttk__label(-text => "                           \n                           \n");
my $lbl_lang;
my $lang_update;
if ($#langs > 0) {
 $lbl_lang = $o_innerframe1->new_ttk__label(-text => "\n" . $L->{$lang}{TXT_LANGUAGE} . ":\n");
 $lang_update = $o_innerframe1->new_ttk__combobox(-textvariable => \$sel_lang, -values => \@langs, -state=>"readonly");
 $lang_update->g_bind("<<ComboboxSelected>>", sub {
  Tkx::tk___messageBox(-icon => "info", -message => "Restart the widget to switch the language to $sel_lang");
 });
}
my $chk_splash = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_NO_SPLASH}, -variable => \$autosplash_var, -onvalue => "on", -offvalue => "off");
my $chk_autocon = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_CONNECT}, -variable => \$autocon_var, -onvalue => "on", -offvalue => "off");
my $chk_autorun = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_START}, -variable => \$autorun_var, -onvalue => "on", -offvalue => "off");

$lbl_blank->g_grid(-column => 0, -row => 0, -sticky => "nw");
$chk_splash->g_grid(-column => 0, -row => 1, -sticky => "w");
$chk_autocon->g_grid(-column => 0, -row => 2, -sticky => "w");
$chk_autorun->g_grid(-column => 0, -row => 3, -sticky => "w");
if ($#langs > 0) {
 $lbl_lang->g_grid(-column => 0, -row => 6, -sticky => "w");
 $lang_update->g_grid(-column => 0, -row => 6, -sticky => "e");
}
my $port_textbox_state;
my $random_port_check_state;
sub port_random {
 if (($randomize_it eq "on") && ($tls_sel eq 'secp521r1')) {
  $port_var = int(rand(29998) + 1);
  if (($port_var == 5061) || ($port_var == 5062) || ($port_var == 5063) || ($port_var == 8443)) {
   $port_var = $port_var + int(rand(1000 - 5));
  }
 }
 if (($randomize_it eq "off") && ($tls_sel eq 'secp521r1')) {
  $port_var = 443;
 }
 if ($tls_sel =~ /(Ed25519|Ed448|ML-DSA-87)/) {
  if ($1 eq "Ed25519") { $port_var = 5061; }
  if ($1 eq "Ed448") { $port_var = 5062; }
  if ($1 eq "ML-DSA-87") { $port_var = 5063; }
  $port_textbox_state = "disabled";
  $random_port_check_state = "disabled";
 }
 else {
  $port_textbox_state = "normal";
  $random_port_check_state = "normal";
 }
}
&port_random;
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PORT})->g_pack();
my $port_textbox = $o_innerframe2->new_ttk__entry(-textvariable => \$port_var, -width => 6, -state => $port_textbox_state)->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PROTOCOL})->g_pack();
my $proto_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=> (($adv_ssh_opt eq "on") || ($adv_https_opt eq "on") || ($adv_socks_opt eq "on")) ? "disabled" : "readonly")->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_TIMEOUT})->g_pack();
my @timeouts = (60, 120, 180, 240);
my $timeout_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$timeout_var, -values => \@timeouts, -width => 4, -state=>"readonly")->g_pack();
# .t.n.f2.c3
$o_innerframe2->new_ttk__checkbutton(-text => $L->{$lang}{TXT_RANDOM_PORT}, -variable => \$randomize_it, -onvalue => "on", -offvalue => "off", -command => sub {
 &port_random;
 }, -state => $random_port_check_state)->g_pack(qw/-anchor n/);
my $lbl_top = $o_innerframe4->new_ttk__label(-text => $L->{$lang}{TXT_ADVANCED_OPTIONS} . "\n");
my @adv_opts2 = ('disabled','1300','1400','1500','1600');
my $adv_label2 = $o_innerframe4->new_ttk__label(-text => "--mssfix:  ");
my $adv_combo2 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt2, -values => \@adv_opts2, -width => 14, -state => "readonly");
my @adv_opts3 = ('adaptive','ipapi','exe');
$selected_adv_opt3 = $adv_opts3[0];
my $adv_label3 = $o_innerframe4->new_ttk__label(-text => "--route-method:  ");
my $adv_combo3 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt3, -values => \@adv_opts3, -width => 14, -state => "readonly");
my @adv_opts4 = $selected_adv_opt4 eq "Any address" ? ($selected_adv_opt4) : ($selected_adv_opt4, "Any address");
foreach (`ipconfig /all|findstr "IPv. add"|findstr /v Link`) {
 if (/.*:\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/) {
  if ($1 !~ /^169\.254\./) {
   push(@adv_opts4,"$1") unless "$1" eq $adv_opts4[0];
  }
 }
 if (/.*:\s([a-f0-9:]+)\(Pre/) {
  push(@adv_opts4,"$1") unless "$1" eq $adv_opts4[0];
 }
}
$selected_adv_opt4 = $adv_opts4[0];
my $adv_label4 = $o_innerframe4->new_ttk__label(-text => "Bind to IP:  ");
my $adv_combo4 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt4, -values => \@adv_opts4, -width => 14, -state => "readonly");

sub is_valid_ip {
 my $ip = shift;
 # Try IPv4
 return 1 if $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ &&
             !grep { $_ > 255 } ($1, $2, $3, $4);
 # Try IPv6 (colon-separated, at least one colon required)
 return 1 if $ip =~ /:/ && Socket::inet_pton(AF_INET6, $ip);
 return 0;
}

# Most of these align based on the width of the text, so hardcoding English here (except for errors).
my $adv_socks_ip_lbl = $o_innerframe4->new_ttk__label(-text => "IP", -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"));
$adv_socks_ip = "127.0.0.1";
my $adv_socks_ip_txt = $o_innerframe4->new_ttk__entry(-textvariable => \$adv_socks_ip, -width => 14, -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"), -validate => "focusout", -validatecommand => sub { 
 unless (is_valid_ip($adv_socks_ip)) {
  &do_error($L->{$lang}{ERR_INVALID_SOCKS_IP} . "\n");
  return 1;
 }
});
my $adv_socks_port_lbl = $o_innerframe4->new_ttk__label(-text => "Port", -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"));
my $adv_socks_port_txt = $o_innerframe4->new_ttk__entry(-textvariable => \$adv_socks_port, -width => 6, -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"));
my $adv_socks_user_lbl = $o_innerframe4->new_ttk__label(-text => "Username", -state => (($adv_socks_opt eq "on") && ($adv_socks_noauth_opt eq "off")) ? "normal" : "disabled");
my $adv_socks_user_txt = $o_innerframe4->new_ttk__entry(-text => "", -textvariable => \$adv_socks_user_var, -state => (($adv_socks_opt eq "on") && ($adv_socks_noauth_opt eq "off")) ? "normal" : "disabled");
my $adv_socks_pass_lbl = $o_innerframe4->new_ttk__label(-text => "Password", -state => (($adv_socks_opt eq "on") && ($adv_socks_noauth_opt eq "off")) ? "normal" : "disabled");
my $adv_socks_pass_txt = $o_innerframe4->new_ttk__entry(-text => "", -textvariable => \$adv_socks_pass_var, -state => (($adv_socks_opt eq "on") && ($adv_socks_noauth_opt eq "off")) ? "normal" : "disabled", -show => '*');
my $adv_socks_noauth_check = $o_innerframe4->new_ttk__checkbutton(-state => (($adv_socks_opt eq "on") ? "normal" : "disabled"), -text => "No username/password needed", -variable => \$adv_socks_noauth_opt, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($adv_socks_noauth_opt eq "on") {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
 }
 if ($adv_socks_noauth_opt eq "off") {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
 }
});
my $adv_socks_check = $o_innerframe4->new_ttk__checkbutton(-text => "Use SOCKS proxy", -variable => \$adv_socks_opt, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($adv_socks_opt eq "on") {
  $adv_https_opt = "off";
  $adv_ssh_opt = "off";
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  $proto_var = 'TCP';
  @protos = ('TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e2_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  if ($adv_socks_noauth_opt ne "on") {
   %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
   &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
   %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
   &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
   %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
   &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
   %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
   &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  }
 }
 if ($adv_socks_opt eq "off") {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  $proto_var = 'UDP';
  @protos = ('UDP','TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"readonly");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e2_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
 }
}, -state => ((($adv_ssh_opt eq "on") || ($adv_https_opt eq "on")) ? "disabled" : "normal"));
my $adv_ssh_check = $o_innerframe4->new_ttk__checkbutton(-text => "Use SSH tunneling", -variable => \$adv_ssh_opt, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($adv_ssh_opt eq "on") {
  $adv_https_opt = "off";
  $adv_socks_opt = "off";
  $proto_var = 'TCP';
  @protos = ('TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e2_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "readonly");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
 }
 if ($adv_ssh_opt eq "off") {
  $proto_var = 'UDP';
  @protos = ('UDP','TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"readonly");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");  
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
 }
}, -state => ((($adv_https_opt eq "on") || ($adv_socks_opt eq "on")) ? "disabled" : "normal"));
my $adv_https_check = $o_innerframe4->new_ttk__checkbutton(-text => "Use HTTPS tunneling", -variable => \$adv_https_opt, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($adv_https_opt eq "on") {
  $adv_ssh_opt = "off";
  $adv_socks_opt = "off";
  $proto_var = 'TCP';
  @protos = ('TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e2_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l7_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c4_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  # remove the combobox
  %stupidstrictrefs = ( Tkx => \&{"Tkx::grid_remove"} );
  &{ $stupidstrictrefs{'Tkx'} }(".t.n.f4.c8");
  # add the entry box
  %stupidstrictrefs = ( Tkx => \&{"Tkx::grid"} );
  &{ $stupidstrictrefs{'Tkx'} }(".t.n.f4.e5", -column => 1, -row => 9);
  # change the label to 'SNI host:'
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => 'normal', -text => "SNI host:");
 }
 if ($adv_https_opt eq "off") {
  $proto_var = 'UDP';
  @protos = ('UDP','TCP');
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"readonly");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");  
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c6_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c5_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
  # remove the entry box
  %stupidstrictrefs = ( Tkx => \&{"Tkx::grid_remove"} );
  &{ $stupidstrictrefs{'Tkx'} }(".t.n.f4.e5");
  # add the combo box
  %stupidstrictrefs = ( Tkx => \&{"Tkx::grid"} );
  &{ $stupidstrictrefs{'Tkx'} }(".t.n.f4.c8", -column => 1, -row => 9);
  # reset combo state to default 'disabled'
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => 'disabled', -text => "Tunnel host:");
 }
}, -state => ((($adv_ssh_opt eq "on") || ($adv_socks_opt eq "on")) ? "disabled" : "normal"));
my @tunnel_nodes;
open(NODELIST, "$nodelistfile") || &do_error($L->{$lang}{ERR_OPEN} . " $nodelistfile");
for (<NODELIST>) {
 my $tmp = $_;
 chomp($tmp);
 if (($disp_server !~ /$tmp/) && ($disp_server !~ /^\n+$/)) {
  if ($tmp =~ /windows/) {
   /^(.*):(.*):(.*):(.*)$/;
   push(@tunnel_nodes,"$4");
  }
 }
}
close(NODELIST);
$selected_tunnel_opt = $tunnel_nodes[0] unless $selected_tunnel_opt;
my $adv_tunnel_combo = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_tunnel_opt, -values => \@tunnel_nodes, -width => 23, -state => ($adv_ssh_opt eq "on") ? "readonly" : "disabled");
my $sni_input_val = "www.speedtest.net";
my $sni_input = $o_innerframe4->new_ttk__entry (-textvariable => \$sni_input_val, -width => 23);
$lbl_top->g_grid(-column => 0, -row => 0);    # .t.n.f4.l
$adv_label2->g_grid(-column => 0, -row => 1); # .t.n.f4.l2
$adv_combo2->g_grid(-column => 1, -row => 1); # .t.n.f4.c
$adv_label3->g_grid(-column => 0, -row => 2); # .t.n.f4.l3
$adv_combo3->g_grid(-column => 1, -row => 2); # .t.n.f4.c2
$adv_label4->g_grid(-column => 0, -row => 3); # .t.n.f4.l4
$adv_combo4->g_grid(-column => 1, -row => 3); # .t.n.f4.c3
$adv_socks_check->g_grid(-column => 0, -row => 4); # .t.n.f4.c5
$adv_socks_ip_lbl->g_grid(-column => 0, -row => 5); # .t.n.f4.l5
$adv_socks_ip_txt->g_grid(-column => 1, -row => 5); # .t.n.f4.e
$adv_socks_port_lbl->g_grid(-column => 2, -row => 5); # .t.n.f4.l6
$adv_socks_port_txt->g_grid(-column => 3, -row => 5); # .t.n.f4.e2
$adv_socks_user_lbl->g_grid(-column => 0, -row => 6); # .t.n.f4.l7
$adv_socks_user_txt->g_grid(-column => 1, -row => 6); # .t.n.f4.e3
$adv_socks_pass_lbl->g_grid(-column => 2, -row => 6); # .t.n.f4.l8
$adv_socks_pass_txt->g_grid(-column => 3, -row => 6); # .t.n.f4.e4
$adv_socks_noauth_check->g_grid(-column => 0, -row => 7, -columnspan => 2); # .t.n.f4.c4

$fixdns_btn = $o_innerframe4->new_ttk__button(-text => "Reset DNS to DHCP", -command => \&fix_dns )->g_grid(-column => 2, -row => 1, -rowspan => 4, -columnspan => 2, -stick => "nswe");

my $adv_tunnel_lbl = $o_innerframe4->new_ttk__label(-text => "Tunnel host:", -state => "disabled");
$adv_ssh_check->g_grid(-column => 0, -row => 8); # .t.n.f4.c6
$adv_https_check->g_grid(-column => 1, -row => 8); # .t.n.f4.c7
$adv_tunnel_lbl->g_grid(-column => 0, -row => 9); # .t.n.f4.l9
$adv_tunnel_combo->g_grid(-column => 1, -row => 9); # .t.n.f4.c8
$sni_input->g_grid(-column => 1, -row => 9); # should be t.n.f.e5, create+remove it, may be readded later
if ($adv_https_opt eq "off") {
 Tkx::grid_remove(".t.n.f4.e5");
 %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
 &{ $stupidstrictrefs{'Tkx'} }(-state => 'disabled', -text => "Tunnel host:");
}
if ($adv_https_opt eq "on") {
 Tkx::grid_remove(".t.n.f4.c8");
 %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
 &{ $stupidstrictrefs{'Tkx'} }(-state => 'normal', -text => "SNI host:");
}

$o_tabs->add($o_innerframe1, -text => $L->{$lang}{TXT_STARTUP});
$o_tabs->add($o_innerframe2, -text => $L->{$lang}{TXT_CONNECTING});
$o_tabs->add($o_innerframe3, -text => $L->{$lang}{TXT_SECURITY});
$o_tabs->add($o_innerframe4, -text => $L->{$lang}{TXT_ADVANCED});

sub sel_tls {
 if ($tls_sel eq 'Ed25519') {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
  $port_var = 5061;
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
 }
 if ($tls_sel eq 'Ed448') {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
  $port_var = 5062;
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
 }
 if ($tls_sel eq 'ML-DSA-87') {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
  $port_var = 5063;
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"disabled");
 }
 if ($tls_sel eq 'secp521r1') {
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.e_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"normal");
  &port_random;
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f2.c3_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state=>"normal");
 }
 return 0;
}
my $i3_blank_lbl = $o_innerframe3->new_ttk__label(-text => "\n");
my $tls_lbl = $o_innerframe3->new_ttk__label(-text => "TLS cipher:");
# .t.n.f3.c
my $tls_sel_opt = $o_innerframe3->new_ttk__combobox(-textvariable => \$tls_sel, -values => \@tlses, -width => 11,
                                 -state=> 'readonly', -validate => "focusout", -validatecommand => sub {
 &sel_tls;
});
my $cipher_lbl = $o_innerframe3->new_ttk__label(-text => "data cipher: ");
my $cipher_sel_opt = $o_innerframe3->new_ttk__combobox(-textvariable => \$cipher_sel, -values => ['AES-256-GCM','CHACHA20-POLY1305'], -width => 20, -state=> 'readonly');
my $seperator_lbl = $o_innerframe3->new_ttk__label(-text => " ");
my $ipv6_disable_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DISABLE_IPV6}, -variable => \$noipv6_var, -onvalue => "on", -offvalue => "off");
my $dnsleak_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DNS_LEAK}, -variable => \$dnsleak_var, -onvalue => "on", -offvalue => "off");
my $dnscrypt_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DNSCRYPT_ENABLE}, -variable => \$dnscrypt_var, -onvalue => "on", -offvalue => "off", -state => "normal");
my $killswitch_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_KILLSWITCH_ENABLE}, -variable => \$killswitch_var, -onvalue => "on", -offvalue => "off");
my $adblock_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_ADBLOCK}, -variable => \$ts_var, -onvalue => "on", -offvalue => "off");

$i3_blank_lbl->g_grid(-column => 0, -row => 0);
$tls_lbl->g_grid(-column => 0, -row => 1, -sticky => "e");
$tls_sel_opt->g_grid(-column => 1, -row => 1, -sticky => "w");
$cipher_lbl->g_grid(-column => 2, -row => 1, -sticky => "e");
$cipher_sel_opt->g_grid(-column => 3, -row => 1, -sticky => "w");
$seperator_lbl->g_grid(-column => 0, -row => 2, -columnspan => 4);
$ipv6_disable_opt->g_grid(-column => 0, -row => 3, -columnspan => 4, -sticky => "w");
$dnsleak_opt->g_grid(-column => 0, -row => 4, -columnspan => 4, -sticky => "w");
$dnscrypt_opt->g_grid(-column => 0, -row => 5, -columnspan => 4, -sticky => "w");
$killswitch_opt->g_grid(-column => 0, -row => 6, -columnspan => 4, -sticky => "w");
$adblock_opt->g_grid(-column => 0, -row => 7, -columnspan => 4, -sticky => "w");

$o_frame1->g_grid(-column => 0, -row => 0, -sticky => "nswe");
$o_worldimage->g_grid(-column => 0, -row => 0);
$back->g_grid(-column => 0, -row => 2, -sticky => "nswe");
$o_tabs->g_grid(-column => 1, -row => 0, -sticky => "nswe");

Tkx::update('idletasks');

$frame1 = $mw->new_ttk__frame(-relief => "flat");
$worldimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'mainicon', -compound => 'top', -text => "\n\nToken:", -font => "logo_font");
$errorimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'erroricon', -compound => 'top', -text => "\n\nToken:", -font => "logo_font");
$userlbl = $frame1->new_tk__text;
$userlbl->tag(qw/configure link1 -foreground blue -underline 1/);
$userlbl->tag(qw/configure link2 -foreground blue -underline 1/);
$userlbl->tag(qw/configure link3 -foreground blue -underline 1/);
$userlbl->tag_bind("link1", "<Button-1>", sub { system 1, "start https://cryptostorm.is/#section5"; $userlbl->tag(qw/configure link1 -foreground purple -underline 1/);});
$userlbl->tag_bind("link1", "<Double-1>", sub { });
$userlbl->tag_bind("link1", "<Enter>", sub { $userlbl->configure(-cursor => 'hand2'); });
$userlbl->tag_bind("link1", "<Leave>", sub { $userlbl->configure(-cursor => 'arrow'); });
$userlbl->tag_bind("link3", "<Button-1>", sub { system 1, "start https://cryptostorm.nu/"; $userlbl->tag(qw/configure link3 -foreground purple -underline 1/); });
$userlbl->tag_bind("link3", "<Double-1>", sub { });
$userlbl->tag_bind("link3", "<Enter>", sub { $userlbl->configure(-cursor => 'hand2'); });
$userlbl->tag_bind("link3", "<Leave>", sub { $userlbl->configure(-cursor => 'arrow'); });
$userlbl->insert("1.0", "\n" . $L->{$lang}{TXT_MAINWINDOW1} . "\n" . $L->{$lang}{TXT_MAINWINDOW2} . " ");
$userlbl->insert('insert', $L->{$lang}{TXT_HERE}, 'link1');
$userlbl->insert('insert', "\n \n");
$userlbl->insert('insert', $L->{$lang}{TXT_MAINWINDOW5} . " ");
$userlbl->insert('insert', $L->{$lang}{TXT_HERE}, 'link3');
$userlbl->insert('insert', ".\n");
$userlbl->configure(-width => 55, -height => 10, -borderwidth => 0, -state=> 'disabled', -font => "TkTextFont", -cursor => 'arrow', -wrap => 'none', -background => 'SystemButtonFace');
$frame2 = $mw->new_ttk__frame(-relief => "flat");
$token_textbox = $frame2->new_ttk__entry(-textvariable => \$token, -width => 27, -font => "token_font", -state => "normal");
$server_textbox = $frame2->new_ttk__combobox(-textvariable => \$disp_server, -width => 29, -state => "readonly");
@disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER});
open(NODELIST, "$nodelistfile") || &do_error($L->{$lang}{ERR_OPEN} . " $nodelistfile");
my @nodes = <NODELIST>;
close(NODELIST);
for (@nodes) {
 my $tmp = $_;
 chomp($tmp);
 if (($disp_server !~ /$tmp/) && ($disp_server !~ /^\n+$/)) {
  if ($tmp =~ /windows/) {
   /^(.*):(.*):(.*):(.*)$/;
   my $country = $1;
   if ($disp_server !~ /$country/) {
    push(@disp_servers,"$country");
   }
   push(@servers,"$tmp");
  }
 }
}
if (!grep /$disp_server/, @nodes) {
 $disp_server = $L->{$lang}{TXT_DEFAULT_SERVER};
}
if ($disp_server ne $L->{$lang}{TXT_DEFAULT_SERVER}) {
 unshift(@disp_servers, "$disp_server");
}
$server_textbox->configure(-values => \@disp_servers);
Tkx::tooltip($token_textbox, $L->{$lang}{TXT_TOOLTIP_TOKEN});
$frame3 = $mw->new_ttk__frame(-relief => "flat");
$connect = $frame3->new_ttk__button(-text => "\n" . $L->{$lang}{TXT_CONNECT} . "\n", -command => \&connectt);
$options = $frame3->new_ttk__button(-text => $L->{$lang}{TXT_OPTIONS}, -command => \&do_options);
$cancel = $mw->new_ttk__button(-text => $L->{$lang}{TXT_EXIT}, -command => \&do_exit);
$save = $frame2->new_ttk__checkbutton(-text => $L->{$lang}{TXT_SAVE}, -variable => \$saveoption, -onvalue => "on", -offvalue => "off");
$update = $frame2->new_ttk__button(-text => $L->{$lang}{TXT_UPDATE}, -command => sub {
 $statusvar = $L->{$lang}{TXT_UPDATE_NODELIST} . "...";
 $update->configure(-state => "disabled");
 $options->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $connect->configure(-state => "disabled");
 Tkx::update();
 &blue_derp;
 $done = 0;
 $update_err = 0;
 $nodebuf = "";
 $updatethread = threads->new( \&update_node_list );
 &blue_derp;
 my $max_wait_ms = 5000;
 my $elapsed = 0;
 while (!$done && $elapsed < $max_wait_ms) {
  Tkx::update();
  select(undef, undef, undef, 0.05);
  $elapsed += 50;
  Tkx::update();
  if (defined $nodebuf and length $nodebuf) {
   &blue_derp;
   if ($status eq "text/plain") {
    &blue_derp;
    my $tmpnodebuf = $nodebuf;
    $nodebuf = '';
    @disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER});
    my @data=split(/\n/, $tmpnodebuf);
    open(NODELIST,">$nodelistfile") || &do_error($L->{$lang}{ERR_WRITE} . " $nodelistfile");
    foreach my $sline (uniq(@data)) {
     if ($sline =~ /windows/) {
      print NODELIST "$sline\n";
      $sline =~ /^(.*):(.*):(.*):(.*)$/;
      push(@disp_servers,"$1");
      push(@servers,"$sline");
     }
    }
    close(NODELIST);
    &green_derp;
    $server_textbox->configure(-values => \@disp_servers, -state => "readonly");
    $statusvar = $L->{$lang}{TXT_UPDATE_NODELIST_DONE};
	Tkx::update();
    $done = 1;
    $updatethread->kill('KILL');
   }
   else {
    &red_derp;
    $statusvar = $L->{$lang}{ERR_UPDATE_NODELIST};
	Tkx::update();
    $done = 1;
    $updatethread->kill('KILL');
   }
   $update->configure(-state => "normal");
   $options->configure(-state => "normal");
   $connect->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   Tkx::update();
  }
  last if $done;
 }
 if (!$done) {
  $update_err = "ERROR: Node list update timed out.";
  &do_error("$update_err");
  $statusvar = $L->{$lang}{ERR_UPDATE_NODELIST};
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $connect->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  Tkx::update();
 }
 $done = 1;
 $updatethread->kill('KILL');
 Tkx::update();
});
if ($token) {
 $saveoption = "on";
}
$server_textbox->g_bind("<<ComboboxSelected>>", sub {
 $server_textbox->configure(-state => "readonly");
 Tkx::tooltip($token_textbox, $L->{$lang}{TXT_TOOLTIP_TOKEN});
 $token_textbox->configure(-state => "normal", -textvariable => \$token);
 $save->configure(-state => "normal");
 $saveoption = "on";
});
$progress = $mw->new_ttk__frame(-padding => "3 0 0 0", -relief => "flat");
my $pbarlen = 0;
$pbar = $progress->new_ttk__progressbar(-orient => "horizontal", -length => $pbarlen, -mode => "determinate", -variable => \$pbarval)->g_grid (-column => 0, -row => 0, -sticky => "we");
$statuslbl = $mw->new_ttk__label(-textvariable => \$statusvar, -padding => "0 0 0 0", -relief => "sunken", -width => 5);
$frame4 = $mw->new_ttk__frame(-relief => "flat");
$logbox = $frame4->new_tk__text(-width => 40, -height => 14, -undo => 1, -state => "disabled", -bg => "black", -fg => "lightgrey");
$logbox->tag_configure("goodline", -background => "green", -font => "helvetica 14 bold", -relief => "raised");
$logbox->tag_configure("badline",  -background => "red", -font => "helvetica 14 bold", -relief => "raised");
$logbox->tag_configure("warnline", -foreground => "black", -font => "helvetica 14 bold", -background => "yellow", -relief => "raised");
$scroll = $frame4->new_ttk__scrollbar(-command => [$logbox, "yview"], -orient => "vertical");
$logbox->configure(-yscrollcommand => [$scroll, "set"]);
Tkx::bind($mw,"<Button-3>", [ sub {
 my($x,$y) = @_;
 my $current_window = Tkx::winfo('containing',$x,$y);
 my $pop_menu = $logbox->new_menu;
 my $popup_menu = $pop_menu->new_menu(-tearoff => 0,);
 $popup_menu->add_command(-label => $L->{$lang}{TXT_COPY},-underline => 1, -command => [ sub {
  Tkx::clipboard("clear");
  Tkx::clipboard("append",$logbox->get('1.0','end-1c'));
 }]);
 $popup_menu->g_tk___popup($x,$y)
}
,Tkx::Ev('%X','%Y') ] );
$frame4->g_grid_columnconfigure(0, -weight => 1);
$frame4->g_grid_rowconfigure(0, -weight => 1);
$mw->g_bind("<Return>", sub { $connect->invoke(); });
$frame1->g_grid(-column => 0, -row => 0);
$worldimage->g_grid(-column => 0, -row => 0);
$userlbl->g_grid(-column => 1, -row => 0);
$frame2->g_grid(-column => 0, -row => 0, -sticky => "s");
$token_textbox->g_grid(-column => 0, -row => 3);
$save->g_grid(-column => 4, -row => 3, -sticky => "w");
$server_textbox->g_grid(-column => 0, -row => 2, -sticky => "nw");
$update->g_grid(-column => 4, -row => 2, -sticky => "w");
$frame3->g_grid(-column => 0, -row => 0, -sticky => "se");
$progress->g_grid(-column => 0, -row => 2, -sticky => "we");
$statuslbl->g_grid(-column => 0, -row => 1, -sticky => "w");
$options->g_grid(-column => 1, -row => 1, -sticky => "e");
$connect->g_grid(-column => 1, -row => 2, -sticky => "nswe");
$cancel->g_grid(-column => 0, -row => 1, -sticky => "e");
$password = "93b66e7059176bbfa418061c5cba87dd";
Tkx::update('idletasks');
$width  = Tkx::winfo('reqwidth',  $mw);
$height = Tkx::winfo('reqheight', $mw);
my $fullheight = $height * 2;
%stupidstrictrefs = (
 Tkx_pbar => \&{"Tkx::.f4.p_configure"},
 Tkx_sbar => \&{"Tkx::.l_configure"},
 Tkx_notb => \&{"Tkx::.t.n_configure"},
 Tkx_logb => \&{"Tkx::.f5.t_configure"}
);
&{ $stupidstrictrefs{'Tkx_pbar'} }(-length => $width);
&{ $stupidstrictrefs{'Tkx_sbar'} }(-width => ($width / 60));
&{ $stupidstrictrefs{'Tkx_notb'} }(-width => $width, -height => $height);
$x = int((Tkx::winfo('screenwidth',  $mw)  - $width  ) / 2);
$y = int((Tkx::winfo('screenheight', $mw)  - $height ) / 2);
$mw->g_wm_geometry("+$x+$y");
Tkx::update('idletasks');

Tkx::bind($token_textbox,"<3>", [ sub {
 my($x,$y) = @_;
 my $current_window = Tkx::winfo('containing',$x,$y);
 my $pop_menu = $token_textbox->new_menu;
 my $popup_menu = $pop_menu->new_menu(-tearoff => 0,);
 $popup_menu->add_command(-label => $L->{$lang}{TXT_COPY}, -state => ((($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
                                                                       ($token =~ /^([a-f0-9]{128})$/)) ? "normal" : "disabled"), -underline => 1, -command => [ sub {
  Tkx::clipboard("clear");
  Tkx::clipboard("append",$token);
 }]);
 my $clipboard = $clip->Get();
 $popup_menu->add_command(-label => $L->{$lang}{TXT_PASTE}, -state => ((($clipboard =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) || ($clipboard =~ /^([a-f0-9]{128})$/)) ? "normal" : "disabled"), -underline => 1, -command => [ sub {
  $token = $clipboard;
 }]);
 $popup_menu->g_tk___popup($x,$y)
}
,Tkx::Ev('%X','%Y') ] );

if (($killswitch_var eq "on") && ($adv_socks_opt eq "on")) {
 Tkx::tk___messageBox(-icon => "info", -message => $L->{$lang}{TXT_SOCKS_NO_KILLSWITCH});
 $killswitch_var = "off";
}
if ((-e "..\\user\\all.wfw") || ($killswitch_var eq "on") && ($autorun_var ne "on")) {
 $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow DHCP"`;
 if ($rt =~ /cryptostorm/) {
  $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno",
                                      -message => $L->{$lang}{QUESTION_KILLSWITCH1} . "\n" .
									              $L->{$lang}{QUESTION_KILLSWITCH2},
                                      -icon => "question", -title => "cryptostorm.is client");
  if ($tokillornot eq "yes") {
   &killswitch_off;
   $killswitch_var = "off";
  }
 }
 else {
  unlink("..\\user\\all.wfw");
  &killswitch_on;
 }
}
if ($dnscrypt_var eq "on") {
 &dnscrypt(1);
}
$statusvar = $L->{$lang}{TXT_WINTUN_STARTING} . "...";
Tkx::update();
Win32::Process::Create(my $process,$wintunexe,"$wintunexe background",0,Win32::Process::DETACHED_PROCESS(),".") or 
 &do_error($L->{$lang}{TXT_FAILED_TO_START} . " $wintunexe: $^E\n");
$statusvar = $L->{$lang}{TXT_WINTUN_RESTORING_DEFAULTS};
Tkx::update();
&restore_wintun(0);
$statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
Tkx::update();
if ($autocon_var eq "on") {
 $mw->g_wm_deiconify();
 $mw->g_raise();
 $mw->g_focus();
 &connectt;
}
if ($upgrade) {
 sleep 3;
 my $upgrade_or_not;
 $upgrade_or_not = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
                                        -message => $L->{$lang}{QUESTION_NEWVER1} . "\n" .
										            $L->{$lang}{QUESTION_NEWVER2} . "\n",
                                        -icon => "question", -title => "cryptostorm.is client");
 if ($upgrade_or_not eq "yes") {
  if ($token) {
   copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
   copy($authfile,$ENV{'TEMP'} . "\\config.ini");
  }
  system("start https://cryptostorm.is/cryptostorm_setup.exe");
  exit;
 }
}
if (defined($amsg)) {
 Tkx::tk___messageBox(-parent => $mw, -type =>    "ok",
                                       -message => "$amsg",
                                       -icon => "info", -title => "cryptostorm.is client");

}
$statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
$TrayIcon  = new Win32::GUI::Icon("..\\res\\world1.ico");
$TrayWinHidden = Win32::GUI::Window->new(
                 -name => 'TrayWindow',
                 -text => 'TrayWindow',
                 -width => 1,
                 -height => 1,
                 -visible => 0,
                 );
$TrayNotify = $TrayWinHidden->AddNotifyIcon(
                -onRightClick => \&TrackTrayMenu,
                -onClick => \&showwin,
				-name => "Open",
               -icon => $TrayIcon,
               -tip => "cryptostorm.is client",
               -balloon_icon => "info");
Tkx::update();
Tkx::MainLoop();
exit;

sub hidewin {
 if (($mw->g_wm_state eq "normal") || ($mw->g_wm_state eq "iconic")) {
  $idle = 1;
  $hiddenornot = "Show";
  $mw->g_wm_deiconify();
  $mw->g_wm_withdraw();
  &do_menu(1);
 }
}

sub showwin {
 if (($mw->g_wm_state eq "iconic") || ($mw->g_wm_state eq "normal")) {
  $mw->g_wm_deiconify();
  $mw->g_focus();
 }
 if ($mw->g_wm_state eq "withdrawn") {
  $hiddenornot = "Hide";
  $idle = 0;
  if (defined($mw)) {
   $mw->g_wm_deiconify();
   $mw->g_raise();
   $mw->g_focus();
   &do_menu(0);
  }
  &logbox_loop;
 }
}
	
sub do_menu {
 my $balloon = (($_[0]) && (!$showtiponce)) ? 1 : 0;
 Win32::GUI::NotifyIcon::Change($TrayNotify,
                -balloon => $balloon,
                -balloon_tip => $balloon_msg,
				-tip => "Cryptostorm Client",
				-balloon_timeout => 10,
                );
 if ($hiddenornot eq "Show") {
  $TrayMenu = Win32::GUI::Menu->new(
              "Options" => "Options",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&showwin},
              ">-" => {-name => "LS"},
              ">" . "Exit" => {-name => "Exit",-onClick => \&do_exit }
               ) or &do_error($L->{$lang}{ERR_MENU});
 }
 if ($hiddenornot eq "Hide") {
  $TrayMenu = Win32::GUI::Menu->new(
              "Options" => "Options",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&hidewin, -default => 0},
              ">-" => {-name => "LS"},
              ">" . "Exit" => {-name => "Exit", -onClick => \&do_exit }
			  ) or &do_error($L->{$lang}{ERR_MENU});
 }
 if ($balloon) {
  $showtiponce = 1;
 }
}

sub TrackTrayMenu {
 if (defined($TrayNotify) && defined($TrayMenu)) {
  $TrayNotify->Win32::GUI::TrackPopupMenu($TrayMenu->{"Options"});
 }
 return 0;
}

sub savelogin {
 open(CREDS,">$authfile");
 if ($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) {
  print CREDS sha512_hex("$token") . "\n";
 }
 if ($token =~ /^([a-f0-9]{128})$/) {
  print CREDS "$token\n";
 }
 print CREDS "$password\n";
 if ($disp_server ne $L->{$lang}{TXT_DEFAULT_SERVER}) {
  print CREDS "node=$disp_server\n";
 }
 if ($autocon_var =~ /(on|off)/) {
  print CREDS "autocon=$1\n";
 }
 if ($autosplash_var =~ /(on|off)/) {
  print CREDS "autosplash=$1\n";
 }
 if ($autorun_var =~ /(on|off)/) {
  print CREDS "autorun=$1\n";
 }
 if ($dnscrypt_var =~ /(on|off)/) {
  print CREDS "dnscrypt=$1\n";
 }
 if ($killswitch_var =~ /(.*)/) {
  print CREDS "killswitch=$1\n";
 }
 if ($ts_var =~ /(.*)/) {
  print CREDS "ts=$1\n";
 }
 if ($tls_sel =~ /(.*)/) {
  print CREDS "tls_sel=$1\n";
 }
 if ($update_var =~ /(on|off)/) {
  print CREDS "checkforupdate=$1\n";
 }
 if ($dnsleak_var =~ /(on|off)/) {
  print CREDS "dnsleak=$1\n";
 }
 if ($timeout_var =~ /([0-9]+)/) {
  print CREDS "timeout=$1\n";
 }
 if ($noipv6_var =~ /(on|off)/) {
  print CREDS "noipv6=$1\n";
 }
 if ($port_var =~ /([0-9]+)/) {
  print CREDS "port=$1\n";
 }
 if ($randomize_it =~ /(on|off)/) {
  print CREDS "randomport=$1\n";
 }
 if ($sel_lang =~ /(.*)/) {
  print CREDS "lang=$1\n";
 }
 if ($proto_var =~ /(UDP|TCP)/) {
  print CREDS "proto=$1\n";
 }
 print CREDS "mssfix=$selected_adv_opt2\n";
 if ($selected_adv_opt3 ne "adaptive") {
  print CREDS "route-method=$selected_adv_opt3\n";
 }
 if ($selected_adv_opt4 ne "Any address") {
  print CREDS "bind=$selected_adv_opt4\n";
 }
 if ($adv_socks_opt eq "on") {
  print CREDS "socks=on\n";
 }
 if ($adv_socks_ip) {
  print CREDS "socks_ip=$adv_socks_ip\n";
 }
 if ($adv_socks_port) {
  print CREDS "socks_port=$adv_socks_port\n";
 }
 if ($adv_socks_noauth_opt eq "off") {
  print CREDS "socks_noauth=off\n";
  if ($adv_socks_user_var) {
   $regkey->{'SOCKS_USER'} = $adv_socks_user_var;
  }
  if ($adv_socks_pass_var) {
   $regkey->{'SOCKS_PASS'} = $adv_socks_pass_var;
  }
 }
 if ($adv_socks_noauth_opt eq "on") {
  if ($regkey->{'SOCKS_USER'}) {
   delete $regkey->{'SOCKS_USER'};
  }
  if ($regkey->{'SOCKS_PASS'}) {
   delete $regkey->{'SOCKS_PASS'};
  }
  delete $Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'};
 }
 if ($adv_ssh_opt eq "on") {
  print CREDS "tunnel_ssh=on\n";
  print CREDS "tunnel_host=$selected_tunnel_opt\n";
 }
 if ($adv_https_opt eq "on") {
  print CREDS "tunnel_https=on\n";
 }
 close(CREDS);
}

sub step_pbar {
 &blue_derp unless $statusvar eq $L->{$lang}{TXT_CONNECTED};
 Tkx::update();
 return if $stop;
 if (!$pbarval) {
  for ($c=0;$c<=10;$c++) {
   $pbarval = $c;
   select(undef, undef, undef, 0.04);
   Tkx::update();
  }
 }
 else {
  my $b = $pbarval + 10;
  my $a = $pbarval;
  for ($c=$a;$c<=$b;$c++) {
   $pbarval = $c;
   select(undef, undef, undef, 0.04);
   Tkx::update();
  }
 }
}

sub recon {
 $logbox->insert_end("$_[0]", "warnline");
 $logbox->see('end');
 $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
 $pbarval = 0;
 $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
 $connect->configure(-state => "normal");
 $options->configure(-state => "normal");
 $update->configure(-state => "normal");
 $server_textbox->configure(-state => "readonly");
 $stop = 1;
 $o_done3 = 1;
 $showtiponce = 0;
 &shutdown_openvpn();
 alarm 0;
 select(undef,undef,undef,0.05);
 &connectt;
}

sub connectt {
 if ($adv_ssh_opt eq "on") {
  if ($disp_server ne "Global random") {
   my ($index) = grep { $servers[$_] =~ /$disp_server/} (0 .. @servers-1);
   my $tmpnode = $servers[$index];
   $tmpnode =~ s/.*://;
   if ($tmpnode eq $selected_tunnel_opt) {
    &do_error($L->{$lang}{ERR_TUNNEL_DIFFERENT_HOST} . " ($disp_server)");
    return;
   }
  }
 }
 $stop = 0;
 $idle = 0;
 $SIG{ALRM} = sub { &recon($L->{$lang}{TXT_CONNECT_TIMEOUT});return; };
 alarm $timeout_var;
 if (!$token) {
  $worldimage->configure(-image => "mainicon");
  &do_error($L->{$lang}{ERR_NO_TOKEN});
  alarm 0;
  return;
 }
 $connect->configure(-state => "disabled");
 $options->configure(-state => "disabled");
 $update->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $statusvar = $L->{$lang}{TXT_CHECKING_TOKEN};
 $token =~ s/[^a-zA-Z0-9\-\+\/]//g;
 if (($token !~ /^[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}$/) &&
     ($token !~ /^[a-f0-9]{128}$/) &&
     ($token !~ /^AAAAC3NzaC1lZDI1NTE5AAAAI/)) {
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  $pbarval = 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  $worldimage->configure(-image => "mainicon");
  if ($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}){2,}/) {
   &do_error($L->{$lang}{ERR_TOO_MANY_TOKENS1} . "\n" . $L->{$lang}{ERR_TOO_MANY_TOKENS2});
   alarm 0;
   return;
  }
  &do_error($L->{$lang}{ERR_INVALID_TOKEN1} . "\n" . $L->{$lang}{ERR_INVALID_TOKEN2});
  alarm 0;
  return;
 }
 if (($autocon_var eq "on") && ($saveoption eq "off") || (!$saveoption)) {
  $autocon_var = "off";
 }
 Tkx::update();
 $frame4->g_grid(-column => 0, -row => 3, -sticky => "nswe");
 $logbox->g_grid(-column => 0, -row => 4, -sticky => "nwes");
 $scroll->g_grid(-column => 1, -row => 4, -sticky => "ns");
 Tkx::update('idletasks');
 my $x = int((Tkx::winfo('screenwidth',  $mw) / 2) - (Tkx::winfo('reqwidth',  $mw) / 2));
 my $y = int((Tkx::winfo('screenheight', $mw) / 2) - (Tkx::winfo('reqheight', $mw) / 2));
 $mw->g_wm_geometry(Tkx::winfo('reqwidth',  $mw) . "x" . Tkx::winfo('reqheight', $mw) . "+" . $x . "+" . $y);
 Tkx::update();
 $statusvar = $L->{$lang}{TXT_LOGGING_IN} . "...";
 Tkx::update();
 open(TMP,">..\\user\\$hashfile") || &do_error($L->{$lang}{ERR_WRITE} . " .\\user\\");
 if (length($token)) {
  if ($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) {
   print TMP sha512_hex("$token") . "\n";
  }
  if (($token =~ /^([a-f0-9]{128})$/) || ($token =~ /^AAAAC3NzaC1lZDI1NTE5AAAAI/)) {
   print TMP "$token\n";
  }
 }
 else {
  print TMP sha512_hex("$token") . "\n";
 }
 print TMP "$password\n";
 close(TMP);
 Tkx::update();
 $logbox->configure(-state => "normal");
 Tkx::update();
 $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_DISCONNECTED} . '$',"insert");
 if (defined($logbox_index)) {
  if ($logbox_index =~ /[0-9\.]+/) {
   $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
  }
 }
 $logbox->see('end');
 Tkx::update();
 if ($randomize_it eq "on") {
  $port_var = int(rand(29998) + 1);
  if (($port_var == 5061) || ($port_var == 5062) || ($port_var == 5063) || ($port_var == 8443)) {
   $port_var = $port_var + int(rand(1000 - 5));
  }
 }
 undef @tmparray;
 undef $tmpline;
 undef $vpn_args;
 Tkx::update();
 &confgen;
 Tkx::update();
 my $chosen_node = $vpn_args;
 $chosen_node =~ s/.*remote ([a-zA-Z0-9\-\.]+) .*/$1/;
 Tkx::update();
 my $dnsret;
 if ($adv_https_opt eq "on") {
  @resolved_ips = ('127.0.0.1');
 }
 $statusvar = $L->{$lang}{TXT_CONNECTING} . "...";
 Tkx::update();
 @remote_random = ();
 $stop = 0;
 system(1,"netsh interface ipv6 set privacy state=disabled");
 $pid = open $VPNfh, "-|", "$vpnexe $vpn_args";
 $VPNfh->autoflush(1);
 $thread = threads->new(\&tail_openvpn_log);
 step_pbar();
 Tkx::update();
 @msgs = ('cryptostorm',
          'PUSH_REQUEST',
          'device .* opened',
          'Route addition via .* succeeded',
          'TLS: Initial packet from');
 $localip = '';
 $localip6 = '';
 $ipv6_ip_i_was_connected_to = '';
 &logbox_loop;
 alarm 0;
}

sub logbox_loop {
 while (!$idle) {
  select(undef,undef,undef,0.05);
  Tkx::update();
  &watch_logbox;
 }
}

sub watch_logbox {
 select(undef,undef,undef,0.01);
 while (@log_lines) {
  my $ovpnline = shift @log_lines;
  $logbox->insert('end', $ovpnline);
  $logbox->see('end');
  Tkx::update() unless $idle;
  for (@msgs) {
   if ($ovpnline =~ /$_/) {
    &step_pbar();
   }
  }
  $logbox->see('end');
  if ($ovpnline =~ /\b(10\.(?:66|67|70|71)\.\d{1,3}\.(?:25[0-5]|2[0-4]\d|1\d\d|\d\d|[2-9]))\b/) {
   $localip = $1;
  }
  if ($ovpnline =~ /(fd00:10:60:[a-f0-9]{1,4}:[a-f0-9]{1,4}:[a-f0-9]{1,4}:[a-f0-9]{1,4}:[a-f0-9]{1,4})/i) {
   $localip6 = $1;
  }
  if ($ovpnline =~ /GDG6: remote_host_ipv6=([a-f0-9:]+)/) {
   $ipv6_ip_i_was_connected_to = $1;
  }
  if ($ovpnline =~ /received, process restarting/) {
   $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_CONNECTED} . '$',"insert");
   if (defined($logbox_index)) {
    if ($logbox_index =~ /[0-9\.]+/) {
     $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
    }
   }
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
  }
  if ($ovpnline =~ /Failed to open/) {
   $logbox->insert_end("\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error($ovpnline);
   &shutdown_openvpn();
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Options error:/) {
   $logbox->insert_end("\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error($ovpnline);
   &shutdown_openvpn();
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Exiting due to fatal error/) {
   # ignoring, closes things down faster on disconnect
   $logbox_index = $logbox->search(-regexp, 'Assertion failed at win32\.c.*socket_defined',"insert");
   if (defined($logbox_index)) {
    if ($logbox_index =~ /[0-9\.]+/) {
     $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
	 $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+2)));
	 $logbox->see('end');
    }
   }
   else {
    $logbox->insert_end("\n", "badline");
    $logbox->see('end');
	my @lines = split /\n/, $ovpnline;
    $ovpnline = @lines[($#lines - 1 )];
    &do_error($ovpnline);
    &shutdown_openvpn();
   }
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /AUTH: Received control message: AUTH_FAILED/) {
   $logbox->insert_end($L->{$lang}{ERR_AUTH_FAIL} . "\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error($L->{$lang}{ERR_AUTH_FAIL});
   &shutdown_openvpn();
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Cannot resolve host address: (.*)/) {
   $logbox->insert_end($L->{$lang}{ERR_RESOLVE} . " $1\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error($L->{$lang}{ERR_RESOLVE} . " $1");
   if ((&isoncs > 0) && ($dnscrypt_var eq "on")) {
    $worldimage->configure(-image => "mainicon");
    $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
    Tkx::update();
    &dnscrypt(0);
   }
   &shutdown_openvpn();
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Initialization Sequence Completed/) {
   delete $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Network/NewNetworkWindowOff/"};
   if ($killswitch_var eq "on") {
    if ($dnscrypt_var eq "off") {
     # Disable temporary pre-connect DNS rule
     toggle_fw_rule("cryptostorm - Allow pre-connect DNS", "no");
    }
    # Enable DNS leak protection rule
    toggle_fw_rule("cryptostorm - Allow internal VPN DNS", "yes");
    if ($localip) {
	 # Enable inbound/outbound rules for internal IPv4
     toggle_fw_rule("cryptostorm - Allow internal IPv4 in", "yes localip=$localip remoteip=any");
	 toggle_fw_rule("cryptostorm - Allow internal IPv4 out", "yes localip=any remoteip=$localip");
     # Allow traffic to the gateway
     my $gw4 = $localip;
     $gw4 =~ s/\.\d+$/.1/;
     toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway in", "yes localip=any remoteip=$gw4");
	 toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "yes localip=$gw4 remoteip=any");
    }
    if ($localip6) {
     # Enable inbound/outbound rules for internal IPv6
     toggle_fw_rule("cryptostorm - Allow internal IPv6 in", "yes localip=$localip6 remoteip=any");
	 toggle_fw_rule("cryptostorm - Allow internal IPv6 out", "yes localip=any remoteip=$localip6");
     # Allow traffic to the IPv6 gateway
     my $gw6 = 'fe80::1';
     toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway in", "yes localip=any remoteip=$gw6");
	 toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "yes localip=$gw6");
    }
	if ($MAJOR >= 10) {
	 # Without this, traffic doesn't flow for the first 20-40 seconds on the initial connect,
	 # but only on Windows 10 and 11 for some reason.
	 system(1,"ipconfig /renew");
	}
   }
   if ($ovpnline =~ /Initialization Sequence Completed With Errors/) {
    $logbox->insert_end($L->{$lang}{ERR_CONNECT_GENERIC} . "\n", "badline");
    $logbox->see('end');
    $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
    $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
    $connect->configure(-state => "normal");
    $options->configure(-state => "normal");
    $update->configure(-state => "normal");
    $server_textbox->configure(-state => "readonly");
    $worldimage->configure(-image => "mainicon");
    Tkx::update();
    &do_error($L->{$lang}{ERR_CONNECT_GENERIC});
    &shutdown_openvpn();
    alarm 0;
    close($VPNfh);
    $stop = 1;
    return -1;
   }
   else {
    step_pbar();
    if ($saveoption eq "on") {
     &savelogin;
    }
    $worldimage->configure(-image => "g3");
    $logbox->insert_end($L->{$lang}{TXT_CONNECTED} . "\n", "goodline");
    system(1,"netsh interface ipv6 set privacy state=enabled");
    $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_DISCONNECTED} . '$',"insert");
    if (defined($logbox_index)) {
     if ($logbox_index =~ /[0-9\.]+/) {
      $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
     }
    }
    $logbox->see('end');
    $statusvar = $L->{$lang}{TXT_CONNECTED};
    Tkx::update();
	# No $L->{$lang} for $balloon_msg because Win32::GUI::NotifyIcon can't do Unicode
    $balloon_msg = "Connected to cryptostorm.";
    $cancel->configure(-text => $L->{$lang}{TXT_DISCONNECT});	
    Tkx::update();
    alarm 0;
    if ($dnscrypt_var eq "on") {
     &dnscrypt(0);
     Tkx::update();
    }
    $statusvar = $L->{$lang}{TXT_UPDATE_CHECKING} . "...";
    Tkx::update();
    &check_version_thread(1);	
    if ($VERSION < $o_version_buf) {
     $upgrade = 1;
    }
    if ($upgrade) {
     my $upgrade_or_not;
     $upgrade_or_not = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
                                            -message => $L->{$lang}{QUESTION_NEWVER1} . "\n" .
	                                                    $L->{$lang}{QUESTION_NEWVER2} . "\n",
                                            -icon => "question", -title => "cryptostorm.is client");
     if ($upgrade_or_not eq "yes") {
      if ($token) {
       copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
       copy($authfile,$ENV{'TEMP'} . "\\config.ini");
      }
	  $statusvar = $L->{$lang}{TXT_DOWNLOADING_LATEST} . "...";
	  Tkx::update();		
      &grabnverify("../cryptostorm_setup.exe");
      copy("tmp\\cryptostorm_setup.exe","..\\");
      unlink "tmp\\cryptostorm_setup.exe" if (-e "tmp\\cryptostorm_setup.exe");
      unlink "tmp\\cryptostorm_setup.exe.hash" if (-e "tmp\\cryptostorm_setup.exe.hash");
      rmdir("tmp") unless &isEmpty("tmp") > 0;
      $statusvar = $L->{$lang}{TXT_DONE};
      Tkx::update();
      $doupgrade = 1;
      Tkx::tk___messageBox(-parent => $mw, -type =>    "ok",
                           -message => $L->{$lang}{TXT_UPGRADING1} . "\n" .
                                       $L->{$lang}{TXT_UPGRADING2},
                           -icon => "info", -title => "cryptostorm.is client");
     }
    }
    if (defined($amsg)) {
     Tkx::tk___messageBox(-parent => $mw, -type =>    "ok",
                                          -message => "$amsg",
                                          -icon => "info", -title => "cryptostorm.is client");

    }
    $statusvar = $L->{$lang}{TXT_CONNECTED};
    Tkx::update();
    if (!$doupgrade) {
     &hidewin;
    }
    Tkx::update();
   }
  }
 }
}

sub tail_openvpn_log {
 my $logfile = "..\\bin\\openvpn.log";
 my $lastpos = 0;
 while (!$stop) {
  if (open my $logfh, '<', $logfile) {
   seek($logfh, $lastpos, 0);
   while (my $line = <$logfh>) {
    last if $stop;
    $lastpos = tell($logfh);
    $line =~ s/^[0-9\.]+ [0-9a-f]+ //;
    next if ($line =~ /UDPv[46]\s+(READ|WRITE)/);
    next if ($line =~ /TUN\s+(READ|WRITE)/);
    next if ($line =~ /windows-driver/);
    next if ($line =~ /edirect-gateway and redirect-private/);
    next if ($line =~ /PID_ERR replay/);
    next if ($line =~ /CreateFile failed/);
    next if ($line =~ /sending exit notification to peer/);
    next if ($line =~ /\-\-mute/);
    next if ($line =~ /mode = /);
    next if ($line =~ /config =/);
    next if ($line =~ /Current Parameter Settings/);
    next if ($line =~ /MTU parms/);
    next if ($line =~ /MANAGEMENT/);
    next if ($line =~ /msg_channel=/);
    # If passed all filters, queue for logbox
    push @log_lines, $line;
   }
   close $logfh;
  }
  select undef, undef, undef, 0.1;
 }
}

sub remove_ipv6_routes {
 system(1,"route delete 128.0.0.0 MASK 128.0.0.0 & route delete 2000::/3 & route delete ::/3 & route delete 2000::/4 & route delete 3000::/4 & route delete fc00::/7");
}

sub do_exit {
 my $idunno;
 if (defined($mw)) {
  $mw->g_wm_deiconify();
  $mw->g_raise();
  $mw->g_focus();
 }
 Tkx::update();
 my $oncs = &isoncs;
 if ($oncs > 0) {
  Tkx::update();
  $idunno = Tkx::tk___messageBox(-type =>    "yesno",
                                 -message => $L->{$lang}{QUESTION_DISCONNECT1} . "\n" .
	                                         $L->{$lang}{QUESTION_DISCONNECT2} . "\n" .
                                             $L->{$lang}{QUESTION_DISCONNECT3},
	                             -icon => "question", -title => "cryptostorm.is client");
  if ($idunno eq "no") {
   return;
  }
 }
 if ($oncs == 0 || $idunno eq "yes") {
  if (defined $idunno && $idunno eq "yes") {
   $idle = 1;
   $statusvar .= ".";
   Tkx::update();
   &remove_ipv6_routes;
   $statusvar .= ".";
   Tkx::update();
   &restore_wintun(1);
  }
  $statusvar .= ".";
  Tkx::update();
  $pbarval = 0;
  # User clicked the Exit button
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_EXIT}) {
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   $statusvar .= ".";
   Tkx::update();
   &savelogin;
   $statusvar .= ".";
   Tkx::update();
   $cancel->configure(-state => "disabled");
   Tkx::update();
   if ($adv_ssh_opt eq "on") {
    system(1,"taskkill /IM cs-ssh-tun.exe /F");
   }
   if ($adv_https_opt eq "on") {
    system(1,"taskkill /IM cs-https-tun.exe /F");
   }
   if ($dnscrypt_var eq "on") {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . "...";
    Tkx::update();
    &dnscrypt(0, 1);  # 1 = also uninstall
    Tkx::update();
   }
   if (-e "..\\bin\\openvpn.log") {
    unlink("..\\bin\\openvpn.log");
   }
   if (-e "..\\user\\manpass.txt") {
    unlink("..\\user\\manpass.txt");
   }
   if (-e "..\\user\\mydns.txt") {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . "...";
    Tkx::update();
    &restore_dns;
    unlink "..\\user\\mydns.txt";
   }
   if ((-e "..\\user\\all.wfw") || ($killswitch_var eq "on")) {
    $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow CS programs"`;
    if ($rt =~ /cryptostorm/) {
     $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
                                         -message => $L->{$lang}{QUESTION_KILLSWITCH1} . "\n" .
										             $L->{$lang}{QUESTION_KILLSWITCH2},
                                         -icon => "question", -title => "cryptostorm.is client");
     if ($tokillornot eq "yes") {
	  Tkx::update();
      &killswitch_off;
	  $killswitch_var = "off";
	  &savelogin;
	  Tkx::update();
     }
    }
   }
   $statusvar = $L->{$lang}{TXT_WINTUN_CLEANUP};
   Tkx::update();
   system("cswintun.exe stop");
   $statusvar = $L->{$lang}{TXT_WINTUN_STOPPED};
   Tkx::update();
   if ($MAJOR >= 10) {
    # Windows 10 or newer
    system("cswintun.exe uninstall");
    $statusvar = $L->{$lang}{TXT_WINTUN_STOPPED_AND_UNINSTALLED};
	Tkx::update();
   }
   system(1,"ipconfig /registerdns");
   Tkx::update();
   $statusvar = $L->{$lang}{TXT_EXITING};
   Tkx::update();
   undef $TrayWinHidden if defined $TrayWinHidden;
   if ($killswitch_var eq "on") {
    system(1,"ipconfig /renew");
   }
   $statusvar .= ".";
   Tkx::update();
   if (defined $thread) {
    $stop = 1;
    for (1..10) {
     last if !$thread->is_running();
     select undef, undef, undef, 0.1;
    }
    undef $thread;
   }
   $statusvar .= ".";
   Tkx::update();
   $done = 1;
   $o_done3 = 1;
   if (-e "..\\user\\mydns.txt") {
    unlink("..\\user\\mydns.txt");
   }
   $statusvar .= ".";
   Tkx::update();
   if (-e "..\\user\\socks.dat") {
    unlink("..\\user\\socks.dat");
   }
   &shutdown_openvpn();
   $statusvar .= ".";
   Tkx::update();
   $o_thread3->join() if defined($o_thread3) && $o_thread3->is_joinable();
   $mw->g_destroy() if defined $mw;
   if ($doupgrade) {
    system(1,"start cryptostorm_setup.exe");
   }
   Tkx::exit(0);
  }
  Tkx::update();
  # User clicked the Disconnect button
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_DISCONNECT}) {
   $statusvar = $L->{$lang}{TXT_DISCONNECTING};
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $cancel->configure(-state => "disabled");
   $connect->configure(-state => "disabled");
   $update->configure(-state => "disabled");
   $options->configure(-state => "disabled");
   Tkx::update();
   # Remove the green "Connected" text
   $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_CONNECTED} . '$',"insert");
   if (defined($logbox_index)) {
    if ($logbox_index =~ /[0-9\.]+/) {
     $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
    }
   }
   # Then put the red "Disconnected" text in the logbox
   $logbox->insert_end($L->{$lang}{TXT_DISCONNECTED} . "\n", "badline");
   $logbox->see('end');
   Tkx::update();
   if ($noipv6_var eq "off") {
    $statusvar .= ".";
	Tkx::update();
	&remove_ipv6_routes;
	$statusvar .= ".";
	Tkx::update();
    if ($ipv6_ip_i_was_connected_to) {
	 system(1, "route delete ${ipv6_ip_i_was_connected_to}/128");
	 $statusvar .= ".";
	 Tkx::update();
    }
   }
   if ($killswitch_var eq "on") {
    $localip6 = "";
	$localip = "";
    if ($dnscrypt_var eq "off") {
	 # Re-enable temporary pre-connect DNS for reconnections
     toggle_fw_rule("cryptostorm - Allow pre-connect DNS", "yes");
	 $statusvar .= ".";
	 Tkx::update();
	}
	# Disable internal DNS VPN rule
    toggle_fw_rule("cryptostorm - Allow internal VPN DNS", "no");
	# Disable internal IPv4/6 rules
	toggle_fw_rule("cryptostorm - Allow internal IPv4 in", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv4 out", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv6 in", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv6 out", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway in", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway in", "no");
	toggle_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "no");
	$statusvar .= ".";
	Tkx::update();
   }
   &savelogin;
   if ($adv_ssh_opt eq "on") {
    system(1,"taskkill /IM cs-ssh-tun.exe /F");
   }
   if ($adv_https_opt eq "on") {
    system(1,"taskkill /IM cs-https-tun.exe /F");
   }
   if (-e "..\\user\\socks.dat") {
    unlink("..\\user\\socks.dat");
   }
   Tkx::update();
   $worldimage->configure(-image => "mainicon");
   if (defined $thread) {
    $stop = 1;
    for (1..20) {
     last if !$thread->is_running();
     select undef, undef, undef, 0.1;
    }
    undef $thread;
   }
   $o_done3 = 1;
   $pbarval = 0;
   $showtiponce = 0;
   &shutdown_openvpn();
   if ($dnscrypt_var eq "on") {
    $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
    Tkx::update();
    &dnscrypt(1);
	$statusvar .= ".";
	Tkx::update();
   }
   system(1,"ipconfig /renew");
   $cancel->configure(-state => "normal");
   $update->configure(-state => "normal");
   $options->configure(-state => "normal");
   $connect->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   $statusvar = $L->{$lang}{TXT_DISCONNECTED};
   $pbarval = 0;
   Tkx::update();
  }
 }
}

sub shutdown_openvpn {
 return unless $manport && $manpass;
 my $sock = IO::Socket::INET->new(PeerHost => '127.0.0.1',
                                  PeerPort => $manport,
                                  Proto    => 'tcp',
                                  Timeout  => 1);
 if ($sock) {
  print $sock "$manpass\r\n";
  my $authorized = 0;
  while (my $line = <$sock>) {
   if ($line =~ /INFO:OpenVPN Management Interface Version/) {
    $authorized = 1;
    last;
   }
  }
  if ($authorized) {
   print $sock "signal SIGTERM\r\n";
   while (my $line = <$sock>) {
    last if $line =~ /SUCCESS: signal SIGTERM thrown/;
   }
   # Wait for OpenVPN to close the connection
   eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm(0.3);
    <$sock>; # This should hit EOF if OpenVPN exits
    alarm(0);
   };
   print $sock "exit\r\n" unless $@ =~ /timeout/;
  }
  close($sock);
 }
 # fallback to taskkill
 if (&isoncs()) {
  system(1, "TASKKILL /F /T /IM $vpnexe");
 }
}

sub restore_wintun {
 my $disconnecting = $_[0];
 my $tmpstatusvar = $statusvar;
 $statusvar = $L->{$lang}{TXT_WINTUN_RESTORING_DEFAULTS};
 Tkx::update();
 for (`netsh interface ipv6 show addresses interface="cryptostorm VPN" | findstr fd00:10:60:`) { 
  if (/Address (fd00:10:60:[a-f0-9:]+) Parameters/) {
   my $ip_to_del = $1;
   if ($MAJOR > 6 || ($MAJOR == 6 && $MINOR >= 2)) {
    # Use PowerShell cmdlet Remove-NetIPAddress for Windows 8 and above
    system(qq(powershell -Command "Get-NetIPAddress -IPAddress $ip_to_del | Remove-NetIPAddress -Confirm:\$false"));
	$statusvar .= ".";
	Tkx::update();
   }
   else {
    # Use netsh for < Windows 8
    system(qq(netsh interface ipv6 delete address "cryptostorm VPN" "$ip_to_del"));
	$statusvar .= ".";
	Tkx::update();
   }
  }
 }
 system(qq(netsh interface ipv6 set dnsservers name="cryptostorm VPN" source=dhcp));
 $statusvar .= ".";
 Tkx::update();
 system(qq(netsh interface ip set address name="cryptostorm VPN" source=dhcp));
 $statusvar .= ".";
 Tkx::update();
 system(qq(netsh interface ipv4 set dnsservers name="cryptostorm VPN" source=dhcp));
 $statusvar = $tmpstatusvar;
 Tkx::update();
}

sub uniq {
 my %seen;
 grep !$seen{$_}++, @_;
}

sub update_node_list {
 my $socket;
 my $host = "cryptostorm.nu";
 my $port = 443;
 my $path = "/nodelist4.txt";
 foreach my $entry (@csnu_ips) {
  my ($ip, $family) = @$entry{qw(ip family)};
  next unless inet_pton($family, $ip);  # Skip unsupported families
  eval {
   local $SIG{ALRM} = sub { die "timeout\n" };
   alarm(7);  # Total timeout per attempt
   $socket = IO::Socket::SSL->new(
    PeerAddr        => $ip,
    PeerPort        => $port,
    SSL_hostname    => $host,
    SSL_verify_mode => SSL_VERIFY_PEER,
    Timeout         => 5,
    Domain          => $family,
   );
   alarm(0);
  };
  if ($@) {
   $socket = undef;
   next;
  }
  last if $socket;
 }
 unless ($socket) {
  $update_err = "ERROR: Couldn't connect to $host via any IP";
  return;
 }
 # Send HTTPS GET request manually
 print $socket "GET $path HTTP/1.1\r\n";
 print $socket "Host: $host\r\n";
 print $socket "User-Agent: Cryptostorm client\r\n";
 print $socket "Connection: close\r\n\r\n";
 my $headers = 1;
 my $body = '';
 my $timeout = 7;
 eval {
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm($timeout);
  while (my $line = <$socket>) {
   if ($headers && $line =~ /^Content-Type:\s*([a-z\/]+)/i) {
    $status = $1;
   }
   if ($line =~ /^\r?$/) {
    $headers = 0;
    next;
   }
   $body .= $line unless $headers;
  }
  alarm(0);
 };
 if ($@) {
  $update_err = "ERROR: Download from $host failed: $@";
  return;
 }
 close $socket;
 $nodebuf = $body;
}

sub do_options {
 if ($saveoption eq "off") {
  $autocon_var = "off";
 }
 $tmp_noipv6_var = $noipv6_var;
 $tmp_dnscrypt_var = $dnscrypt_var;
 $tmp_killswitch_var = $killswitch_var;
 $mw->g_wm_deiconify();
 $mw->g_wm_withdraw();
 my $width  ||= Tkx::winfo('reqwidth',  $cw);
 my $height ||= Tkx::winfo('reqheight', $cw);
 my $x = int((Tkx::winfo('screenwidth',  $cw) / 2) - ($width / 2));
 my $y = int((Tkx::winfo('screenheight', $cw) / 2) - ($height / 2));
 $cw->g_wm_geometry($width . "x" . $height . "+" . $x . "+" . $y);
 $cw->g_raise();
 $cw->g_wm_deiconify();
 $cw->g_focus();
 Tkx::update();
}

sub backtomain {
 if ($adv_socks_opt eq "on") {
  if ($adv_socks_port =~ /^([0-9]+)$/) {
   if (($1 < 1) || ($1 > 65535)) {
    &do_error($L->{$lang}{ERR_INVALID_SOCKS_PORT});
    return;
   }
  }
  else {
   &do_error($L->{$lang}{ERR_INVALID_SOCKS_PORT});
   return;
  }
 }
 if ($adv_ssh_opt eq "on") {
  if ($disp_server ne "Global random") {
   my ($index) = grep { $servers[$_] =~ /$disp_server/} (0 .. @servers-1);
   my $tmpnode = $servers[$index];
   $tmpnode =~ s/.*://;
   if ($tmpnode eq $selected_tunnel_opt) {
    &do_error($L->{$lang}{ERR_TUNNEL_DIFFERENT_HOST} . " ($disp_server)");
    return;
   }
  }
 }
 my $tmpvar = $statusvar;
 $port_var =~ s/[^0-9]//g;
 if ($port_var =~ /^([0-9]+)$/) {
  if (($1 < 1) || ($1 > 29999)) {
   &do_error($L->{$lang}{ERR_INVALID_PORT});
   return;
  }
  if ($1 == 8443) {
   &do_error($L->{$lang}{ERR_PORT_8443_RESERVED});
   return;
  }
 }
 else {
  &do_error($L->{$lang}{ERR_INVALID_PORT});
  return;
 }
 $cw->g_wm_deiconify();
 $cw->g_wm_withdraw();
 $mw->g_raise();
 $mw->g_wm_deiconify();
 $mw->g_focus();
 Tkx::update();
 if ($dnscrypt_var ne $tmp_dnscrypt_var) {
  if ($dnscrypt_var eq "on") {
   Tkx::update();
   &dnscrypt(1);
   Tkx::update();
  }
  if ($dnscrypt_var eq "off") {
   Tkx::update();
   &dnscrypt(0);
   Tkx::update();
  }
 }
 if ($autorun_var eq "on") {
  $Registry->{'HKEY_LOCAL_MACHINE/Software/Microsoft/Windows/CurrentVersion/Run/Cryptostorm client'}="$self";
 }
 if ($autorun_var eq "off") {
  delete $Registry->{"HKEY_LOCAL_MACHINE/Software/Microsoft/Windows/CurrentVersion/Run/Cryptostorm client"};
 }
 if (($autocon_var eq "on") && (!$saveoption) || ($saveoption eq "off")) {
  $saveoption = "on";
 }
 Tkx::update();
 if (($killswitch_var eq "on") && ($adv_socks_opt eq "on")) {
  Tkx::tk___messageBox(-icon => "info", -message => "The killswitch will be disabled since a SOCKS proxy is being used");
  $killswitch_var = "off";
 }
 &savelogin;
 Tkx::update();
 if ($killswitch_var ne $tmp_killswitch_var) {
  if ($killswitch_var eq "off") {
   Tkx::update();
   &killswitch_off;
   Tkx::update();
  }
  if ($killswitch_var eq "on") {
   my $winfirecheck = `net start|findstr "Windows.*Firewall"`;
   Tkx::update();
   if ($winfirecheck =~ /Windows.*Firewall/) {
    &killswitch_on;
    Tkx::update();
   }
   else {
    my $winfire = Tkx::tk___messageBox(-parent => $mw, -type => "yesno",
                                       -message => $L->{$lang}{QUESTION_WINFIRE1} . " " . $L->{$lang}{QUESTION_WINFIRE2},
                                       -icon => "question", -title => "cryptostorm.is client");
    if ($winfire eq "yes") {
     system("net start MpsSvc");
	 &killswitch_on;
    }
    if ($winfire eq "no") {
     $killswitch_var = "off";
     &killswitch_off;
    }
   }
  }
 }
 $statusvar = $tmpvar;
 Tkx::update();
}

sub check_version {
 $o_done3 = 0;
 if (defined($o_thread3)) {
  $o_thread3->join() if $o_thread3->is_joinable();
 }
 my $arg = $_[0] // undef;
 $o_thread3 = defined($arg) ? threads->new(\&check_version_thread, $arg) : threads->new(\&check_version_thread);
 $o_thread3->detach();
 while (!$o_done3) {
  Tkx::update();
  select(undef,undef,undef,0.001);
 }
}

sub check_version_thread {
 my $oncs = $_[0];
 my ($ua,$response);
 my @headers = ('User-Agent' => "Cryptostorm client");
 $ua = LWP::UserAgent->new(agent => "Cryptostorm client");
 $ua->timeout(3);
 $response = $ua->get("http://10.31.33.7/latest.txt", @headers);
 if ($response->is_success()) {
  if ($response->content() =~ /LATEST:([0-9\.]+)/) {
   $o_version_buf = $1;
  }
  if ($response->content() =~ /MSG:ON:(.*)/) {
   if ($response->content() !~ /31MSG:ON:(.*)/) {
    $amsg = $1;
   }
  }
  my $upgradeornot;
  if ((!$o_version_buf) && (!$amsg)) {
   $o_version_buf = -1;
  }
 }
 else {
  $o_version_buf = -1;
 }
}

sub callback {
 my ($data, $response, $protocol) = @_;
 print $fh $data;
 $final_data .= $data;
 $statusvar =~ s/ \[.*//;
 $statusvar = "$statusvar [" . progress_bar( length($final_data), $total_size ) . "]";
 Tkx::update();
 chop($statusvar); chop($statusvar);
 chop($statusvar); chop($statusvar);
}

sub grabnverify {
 $cancel->configure(-state => "disabled");
 $final_data = undef;
 my $file_to_grab;
 if ($_[0] =~ /\/(.*)$/) {
  $file_to_grab = $1;
 }
 if (!-d "tmp") { mkdir "tmp"; }
 my $ua = LWP::UserAgent->new(  );
 my $url = "http://10.31.33.7/" . $file_to_grab;
 my $response = $ua->head($url);
 my $remote_headers = $response->headers;
 $total_size = $remote_headers->content_length;
 $ua = LWP::UserAgent->new;
 binmode STDOUT,':raw';
 open $fh, '>', "tmp\\$file_to_grab" or &do_error("\n" . $L->{$lang}{ERR_CREATE} . " tmp\\$file_to_grab: $!\n");
 binmode $fh;
 $response = $ua->get($url, ':content_cb' => \&callback );
 if ($total_size == length($final_data)) {
  $statusvar = $L->{$lang}{TXT_DOWNLOADED} . " $file_to_grab";
  Tkx::update();
  close $fh;
 }
 else {
  &do_error($L->{$lang}{ERR_DOWNLOAD} . " http://10.31.33.7/$file_to_grab: " . $response->status_line . "\n");
  $cancel->configure(-state => "normal");
  return;
 }
 undef $ua;
 undef $response;
 undef $fh;
 undef $final_data;
 $ua = LWP::UserAgent->new;
 binmode STDOUT,':raw';
 open $fh, '>', "tmp\\$file_to_grab.hash" or &do_error("\n" . $L->{$lang}{ERR_CREATE} . " tmp\\$file_to_grab: $!\n");
 binmode $fh;
 $response = $ua->get($url . ".hash", ':content_cb' => \&callback );
 if ($response->is_success) {
  $statusvar = $L->{$lang}{TXT_DOWNLOADED} . " $file_to_grab";
  Tkx::update();
  close $fh;
 }
 else {
  &do_error($L->{$lang}{ERR_DOWNLOAD} . " http://10.31.33.7/$file_to_grab.hash: " . $response->status_line . "\n");
  $cancel->configure(-state => "normal");
  return;
 }
 my $yayornay = `$osslexe dgst -sha512 -verify widget.pub -signature tmp\\$file_to_grab.hash tmp\\$file_to_grab 2>&1`;
 if ($yayornay =~ /Verified OK/) {
  $statusvar = $L->{$lang}{TXT_DOWNLOAD_VERIFIED};
  Tkx::update();
 }
 else {
  $statusvar = $L->{$lang}{ERR_VERIFY} . " - $file_to_grab";
  Tkx::update();
  &do_error($L->{$lang}{ERR_VERIFY} . " - $file_to_grab: $yayornay\n$osslexe dgst -sha512 -verify widget.pub -signature tmp\\$file_to_grab.hash tmp\\$file_to_grab");
  unlink("tmp\\$file_to_grab");
 }
 $cancel->configure(-state => "normal");
}

sub dnscrypt {
 my ($mode, $uninstall) = @_;  # mode: 0 = stop, 1 = start
 $uninstall ||= 0;
 my $tmpstatusvar = $statusvar;
 if ($mode == 0) {
  $statusvar = $L->{$lang}{TXT_DNSCRYPT_STOPPING};
  Tkx::update();
  &dnscrypt_action('stop');
  if ($uninstall) {
   $statusvar = $L->{$lang}{TXT_DNSCRYPT_UNINSTALLING};
   Tkx::update();
   &dnscrypt_action('uninstall');
  }
  $statusvar = $L->{$lang}{TXT_DNS_RESTORE};
  Tkx::update();
  &restore_dns;
 }
 elsif ($mode == 1) {
  unless (&dnscrypt_installed()) {
   $statusvar = $L->{$lang}{TXT_DNSCRYPT_INSTALLING};
   Tkx::update();
   unless (&dnscrypt_action('install')) {
    return;
   }
  }
  $statusvar = $L->{$lang}{TXT_DNSCRYPT_STARTING};
  Tkx::update();
  unless (&dnscrypt_action('start')) {
   return;
  }
  $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT};
  Tkx::update();
  &set_dns_to_dnscrypt;
 }
 system(1, "ipconfig /registerdns");
 $statusvar = $tmpstatusvar;
 Tkx::update();
}

sub dnscrypt_action {
 my ($action) = @_;
 my $cmd = "\"$dnscexe\" -service $action";
 my $output = `$cmd 2>&1`;
 if (($action eq "stop") || ($action eq "uninstall")) {
  return 1;
 }
 if ($output =~ /\[FATAL\]/i) {
  if ($output !~ /already running/) {
   &do_error("dnscrypt '$action' failed:\n$output");
   $dnscrypt_var = "off";
   return 0;
  }
  else {
   return 1;
  }
 }
 if ($output =~ /\[NOTICE\]/i) {
  return 1;
 }
 # Default fallback if we can't determine outcome
 &do_error("dnscrypt '$action' returned unknown output:\n$output");
 $dnscrypt_var = "off";
 return 0;
}

sub dnscrypt_installed {
 my %services;
 Win32::Service::GetServices('', \%services);
 return grep { $_ =~ /dnscrypt/i } values %services;
}

sub power_event {
 my ($win, @args) = @_;
 if ($args[0] eq PBT_APMSUSPEND) {
  # suspending, so disconnect if connected
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_DISCONNECT}) {
   &restore_dns;
   $iwasconnected = 1;
   $stop = 1;
   $o_done3 = 1;
   $pbarval = 0;
   $showtiponce = 0;
   $statusvar = $L->{$lang}{TXT_DISCONNECTED};
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $update->configure(-state => "normal");
   $options->configure(-state => "normal");
   $connect->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   $logbox->insert_end("\n\n\n\n\n\n\n\n\n\n\n");
   $logbox->insert_end($L->{$lang}{TXT_SUSPENDING} . "...\n");
   $logbox->insert_end($L->{$lang}{TXT_DISCONNECTED} . "\n", "badline");
   $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_CONNECTED} . '$',"insert");
   if (defined($logbox_index)) {
    if ($logbox_index =~ /[0-9\.]+/) {
     $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
    }
   }
   $logbox->see('end');
   &shutdown_openvpn();
   $cancel->configure(-state => "normal");
  }
 }
 if (($args[0] eq PBT_APMRESUMEAUTOMATIC) || ($args[0] eq PBT_APMRESUMECRITICAL)) {
  # resuming from suspend, so reconnect if client was connected before suspend
  if ($iwasconnected) {
   $worldimage->configure(-image => "mainicon");
   if ($dnscrypt_var eq "on") {
    &dnscrypt(1);
   }
   $connect->invoke();
   $iwasconnected = 0;
  }
 }
}

sub restore_dns {
 my $tmpstatusvarblah = $statusvar;
 Tkx::update();
 for (@recover) {
  Tkx::update();
  if (/^(.*):DHCP:/) {
   if ($1 !~ /NameServer/) {
    $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$1/NameServer"} = "";
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE};
    Tkx::update();
   }
  }
  if (/^(.*):Static:(.*)$/) {
   if ($2 !~ /127\.0\.0\.1/) {
    if ($1 !~ /NameServer/) {
     $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$1/NameServer"} = "$2";
     $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . " ($2)";
     Tkx::update();
    }
   }
   else {
    if ($1 !~ /NameServer/) {
     $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$1/NameServer"} = "";
     $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . " (DHCP)";
     Tkx::update();
    }
   }
  }
 }
 Tkx::update();
 if (-e "..\\user\\mydns.txt") {
  unlink("..\\user\\mydns.txt");
 }
 $statusvar = $tmpstatusvarblah;
 Tkx::update();
}

sub is_dnscrypt_running {
 my $output = `sc query "dnscrypt-proxy"`;
 if ($output =~ /STATE\s*:\s*\d+\s+(RUNNING|START_PENDING)/i) {
  return 1;
 } else {
  return 0;
 }
}

sub set_dns_to_dnscrypt {
 my $tmpstatusvar = $statusvar;
 my $makesurednscryptisrunning = 0;
 if (&is_dnscrypt_running()) {
  my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};
  foreach (keys %$interfaces) {
   my $GUID = $_;
   next if $GUID =~ /NameServer/;
   $GUID =~ s/\/$//;
   my $key = "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer";
   $Registry->{$key} = "127.0.0.1";
   $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT};
   Tkx::update();
  }
 }
 $statusvar = $tmpstatusvar;
 Tkx::update();
}

sub get_current_dns {
 my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};

 foreach (keys %$interfaces) {
  Tkx::update();
  my $GUID = $_;
  next if $GUID =~ /NameServer/;

  $GUID =~ s/\/$//;
  my $key = "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer";
  my $intdns = $Registry->{$key};

  if (defined $intdns) {
   if ($intdns =~ /127\.0\.0\.1/) {
    if ($dnscrypt_var eq "off") {
     $Registry->{$key} = "";
     system(1, "ipconfig /registerdns");
     Tkx::update();
    }
    push(@recover, "$GUID:DHCP:\n");
   } else {
    push(@recover, "$GUID:Static:$intdns\n");
   }
  } else {
   push(@recover, "$GUID:DHCP:\n");
  }
 }

 if (@recover) {
  if (open my $fh, '>', "..\\user\\mydns.txt") {
   print $fh @recover;
   close $fh;
  }
 }
}

sub wait4thekill {
 Tkx::update();
 my $runthis = system 1, qq($_[0]);
 my $last_update = time;
 while (kill(0, $runthis) == 1) {
  Tkx::update();
  select(undef, undef, undef, 0.01);
  if (time - $last_update >= 0.5) {
   $statusvar .= "." if $statusvar =~ /\.\.$/;
   Tkx::update();
   $last_update = time;
  }
  Tkx::update();
 }
 Tkx::update();
}

sub blue_derp {
 $worldimage->configure(-image => "mainicon");
 $derp = 0;
 for ($derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "b$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for ($derp=6;$derp>=1;$derp--) {
  $worldimage->configure(-image => "b$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 $worldimage->configure(-image => "mainicon");
}

sub green_derp {
 $worldimage->configure(-image => "mainicon");
 for ($derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "g$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for ($derp=6;$derp>=1;$derp--) {
  $worldimage->configure(-image => "g$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 $worldimage->configure(-image => "mainicon");
}

sub red_derp {
 $worldimage->configure(-image => "mainicon");
 for ($derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "r$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for ($derp=6;$derp>=1;$derp--) {
  $worldimage->configure(-image => "r$derp");
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 $worldimage->configure(-image => "mainicon");
}

sub do_error {
 my $error = $_[0];
 $worldimage->g_grid_remove() unless !defined($worldimage);
 $errorimage->g_grid(-column => 0, -row => 0) unless !defined($errorimage);
 Tkx::tk___messageBox(-icon => "error", -message => "Error: $error");
 $errorimage->g_grid_remove() unless !defined($errorimage);
 $worldimage->g_grid(-column => 0, -row => 0) unless !defined($worldimage);
 $options->configure(-state => "normal") unless !defined($options);
 if (defined($autocon_var) && ($autocon_var eq "on")) {
  $statusvar = $L->{$lang}{ERR_AUTO_CONNECT};
  $autocon_var = "off";
  &savelogin;
 }
 return;
}

sub isEmpty {
 return undef unless -d $_[0];
 opendir my $dh, $_[0] or print $!;
 my $count = grep { ! /^\.{1,2}/ } readdir $dh;
 return $count;
}

sub local_port_is_free {
 my ($portnumber) = @_;
 my $proto = getprotobyname('tcp');
 my $iaddr = inet_aton('127.0.0.1');
 my $timeout = 5;
 my $freeport = 0;
 my $paddr = sockaddr_in($portnumber, $iaddr);
 Tkx::update();
 socket(SOCKET, PF_INET, SOCK_STREAM, $proto);
 Tkx::update();
 eval {
  local $SIG{ALRM} = sub { &do_error($L->{$lang}{TXT_TIMEOUT}); };
  alarm($timeout);
  Tkx::update();
  connect(SOCKET, $paddr) || error();
  Tkx::update();
 };
 if ($@) {
  eval {close SOCKET; };
  $freeport = $portnumber;
 }
 else {
  eval {close SOCKET; };
 }
 alarm(0);
 return $freeport;
}

sub get_next_free_local_port {
 my ($startport) = @_;
 my $freeport = 0;
 my $tryport = $startport;
 while(not $freeport = &local_port_is_free($tryport) ) {
  $tryport++;
  &do_error($L->{$lang}{ERR_NO_FREE_PORT}) if $tryport > ($startport + 100);
 }
 return $freeport;
}

sub progress_bar {
 my ($got, $total) = @_;
 sprintf "%.2f%%", 100*$got/+$total;
}

sub killswitch_on {
 $update->configure(-state => "disabled");
 $options->configure(-state => "disabled");
 $connect->configure(-state => "disabled");
 $cancel->configure(-state => "disabled");
 Tkx::update();

 my $tmpbar = $statusvar;
 # Backup current rules
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_EXPORTING_RULES};
 Tkx::update();
 if ( ! -f "..\\user\\all.wfw") {
  $rt = `netsh advfirewall export "..\\user\\all.wfw" 2>&1`;
  if ($rt !~ /Ok./i) {
   &do_error($L->{$lang}{ERR_KILLSWITCH_EXPORT} . ": $rt");
  }
 }
	
 # Clear existing rules
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_CLEARING_EXISTING_RULES};
 Tkx::update();
 &del_fw_rule("all");

 # Set all profiles to block everything in and out
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_BLOCKING_EVERYTHING};
 Tkx::update();
 $rt = `netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound`;
 $rt = `netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound`;
 $rt = `netsh advfirewall set publicprofile firewallpolicy blockinbound,blockoutbound`;    
 # Disable notifications
 $rt = `netsh advfirewall set allprofiles settings inboundusernotification disable`;

 # Allow DHCP
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_DHCP};
 Tkx::update();
 &add_fw_rule(
  "cryptostorm - Allow DHCP",
  "out",
  q{program="%SystemRoot%\\system32\\svchost.exe" localip=0.0.0.0 localport=68 remoteip=255.255.255.255 remoteport=67 protocol=UDP}
 );

 # Allow Local Network Access
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_ALLOWING_LAN};
 Tkx::update();
 &add_fw_rule("cryptostorm - Allow LAN", "in",  "remoteip=LocalSubnet");
 &add_fw_rule("cryptostorm - Allow LAN", "out", "remoteip=LocalSubnet");

 # Allow programs this client uses
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_PROGRAMS};
 Tkx::update();
 my @whitelisted_programs;
 if ($bit == 32) {
  @whitelisted_programs = (
   'C:\\Program Files\\Cryptostorm Client\\bin\\csvpn.exe',
   'C:\\Program Files\\Cryptostorm Client\\bin\\cs-dnsc-p.exe',
   'C:\\Program Files\\Cryptostorm Client\\bin\\cs-https-tun.exe',
   'C:\\Program Files\\Cryptostorm Client\\bin\\cs-ssh-tun.exe'
  );
 }
 else {
  @whitelisted_programs = (
   'C:\\Program Files (x86)\\Cryptostorm Client\\bin\\csvpn.exe',
   'C:\\Program Files (x86)\\Cryptostorm Client\\bin\\cs-dnsc-p.exe',
   'C:\\Program Files (x86)\\Cryptostorm Client\\bin\\cs-https-tun.exe',
   'C:\\Program Files (x86)\\Cryptostorm Client\\bin\\cs-ssh-tun.exe'
  );
 }

 foreach my $program (@whitelisted_programs) {
  &add_fw_rule("cryptostorm - Allow CS programs", "out", qq{program="$program" service=any});
  &add_fw_rule("cryptostorm - Allow CS programs", "in",  qq{program="$program" service=any});
 }

 $statusvar = $L->{$lang}{TXT_KILLSWITCH_ALLOWING_PRECONNECT_DNS};
 Tkx::update();
 &add_fw_rule("cryptostorm - Allow pre-connect DNS", "out", "protocol=UDP remoteport=53");
 &add_fw_rule("cryptostorm - Allow pre-connect DNS", "out", "protocol=TCP remoteport=53");

 # Resolve VPN endpoints
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_RESOLVING_ENDPOINTS};
 Tkx::update();
 &preresolve("balancer.cstorm.is");

 if ($#resolved_ips < 1) {
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  $pbarval = 0;
  $cancel->configure(-state => "normal", -text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  $worldimage->configure(-image => "mainicon");
  alarm 0;
  return;
 }

 # Allow VPN server IPs
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_VPN_IPS};
 Tkx::update();
 my @ip_batches;
 my $batch_size = 20;
 while (@resolved_ips) {
  my @batch = splice(@resolved_ips, 0, $batch_size);
  push @ip_batches, join(",", @batch);
 }

 foreach my $batch (@ip_batches) {
  add_fw_rule("cryptostorm - Allow VPN IPs", "out", "remoteip=$batch");
 }

 # Allow cryptostorm.is / .nu
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_WHITELISTING_STATIC_IPS};
 Tkx::update();
 my $csis_ipv4 = "46.165.221.100";
 my $csis_ipv6 = "2a00:c98:2030:a005:feed:df:c0ff:eeee";
 my $csnu_ipv4 = "46.165.221.67";
 my $csnu_ipv6 = "2a00:c98:2030:a005:c0ff:eeee:eeee:eeee";

 add_fw_rule("cryptostorm - Allow cryptostorm.is and .nu", "out", "remoteip=$csnu_ipv4,$csnu_ipv6,$csis_ipv4,$csis_ipv6");

 # Allow VPN server's internal DNS servers (disabled initially)
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_ADDING_VPN_DNS_RULES};
 Tkx::update();
 add_fw_rule("cryptostorm - Allow internal VPN DNS", "out", "remoteip=10.31.33.7,10.31.33.8,2001:db8::7,2001:db8::8 enable=no");
 
 # Allow internal VPN IPs (disabled initially, assigned later)
 $statusvar = $L->{$lang}{TXT_KILLSWITCH_ADDING_INTERNAL_VPN_IP_RULES};
 Tkx::update();
 add_fw_rule("cryptostorm - Allow internal IPv4 in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 out", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv6 in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv6 out", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 gateway in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv4 gateway out", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv6 gateway in", "out", "remoteip=any enable=no");
 add_fw_rule("cryptostorm - Allow internal IPv6 gateway out", "out", "remoteip=any enable=no");

 # Restore UI
 $statusvar = $tmpbar;
 $update->configure(-state => "normal");
 $options->configure(-state => "normal");
 $connect->configure(-state => "normal");
 $cancel->configure(-state => "normal");
 Tkx::update();
}

sub toggle_fw_rule {
 my ($rule_name,$toggle) = @_;
 $toggle = $toggle eq "on" ? "yes" : $toggle eq "off" ? "no" : $toggle;
 my $cmd = qq{netsh advfirewall firewall set rule name="$rule_name" new enable=$toggle 2>&1};
 my $status = system($cmd);
 if ($status != 0) {
  &do_error($L->{$lang}{ERR_KILLSWITCH_FW_TOGGLE} . ": $rule_name\nCommand: $cmd\nExit code: $status");
 }
}

sub add_fw_rule {
 my ($rule_name, $dir, $extra_args) = @_;
 my $cmd = qq{netsh advfirewall firewall add rule name="$rule_name" dir=$dir action=allow $extra_args 2>&1};
 my $rt = `$cmd`;
 if ($rt !~ /Ok./i) {
  &do_error($L->{$lang}{ERR_KILLSWITCH_FW_ADD} . ": $rule_name (dir=$dir)\nCommand: $cmd\nError: $rt");
 }
}

sub del_fw_rule {
 my ($rule_name) = @_;
 my $cmd = qq{netsh advfirewall firewall del rule name="$rule_name" 2>&1};
 my $rt = `$cmd`;
 if ($rt !~ /Ok./i) {
  &do_error($L->{$lang}{ERR_KILLSWITCH_FW_DEL} . ": $rule_name\nCommand: $cmd\nError: $rt");
 }
}

sub killswitch_off {
 my $tmpbar = $statusvar;
 $update->configure(-state => "disabled");
 $options->configure(-state => "disabled");
 $connect->configure(-state => "disabled");
 $cancel->configure(-state => "disabled");
 Tkx::update();
 if ((-e "..\\user\\all.wfw") || ($killswitch_var eq "on")) {
  $rt = `netsh advfirewall import "..\\user\\all.wfw"`;
  if ($rt =~ /Ok./) {
   $statusvar = $L->{$lang}{TXT_KILLSWITCH_IMPORTED_PREVIOUS_RULES};
   Tkx::update();
  }
  $rt = `netsh advfirewall firewall show rule name="cryptostorm - Allow DHCP"`;
  if ($rt =~ /cryptostorm/) {
   $statusvar = $L->{$lang}{TXT_KILLSWITCH_IS_ENABLED_DISABLING};
   Tkx::update();
   &del_fw_rule("cryptostorm - Allow cryptostorm.is and .nu");
   &del_fw_rule("cryptostorm - Allow CS programs");
   &del_fw_rule("cryptostorm - Allow DHCP");
   &del_fw_rule("cryptostorm - Allow internal IPv4 in");
   &del_fw_rule("cryptostorm - Allow internal IPv4 out");
   &del_fw_rule("cryptostorm - Allow internal IPv6 in");
   &del_fw_rule("cryptostorm - Allow internal IPv6 out");
   &del_fw_rule("cryptostorm - Allow internal IPv4 gateway in");
   &del_fw_rule("cryptostorm - Allow internal IPv4 gateway out");
   &del_fw_rule("cryptostorm - Allow internal IPv6 gateway in");
   &del_fw_rule("cryptostorm - Allow internal IPv6 gateway out");
   &del_fw_rule("cryptostorm - Allow internal VPN DNS");
   &del_fw_rule("cryptostorm - Allow LAN");
   &del_fw_rule("cryptostorm - Allow pre-connect DNS");
   &del_fw_rule("cryptostorm - Allow VPN IPs");
   $statusvar = $L->{$lang}{TXT_KILLSWITCH_RULES_DELETED};
   Tkx::update();
   $rt = `netsh advfirewall set allprofiles settings inboundusernotification enable`;
   $statusvar = $L->{$lang}{TXT_KILLSWITCH_FW_NOTIFICATIONS_ENABLED};
   Tkx::update();
   $rt = `netsh advfirewall set allprofiles firewallpolicy BlockInbound,BlockOutbound`;
   $statusvar = $L->{$lang}{TXT_KILLSWITCH_FW_PROFILE_POLICIES_RESTORED};
   Tkx::update();
  }
  unlink("..\\user\\all.wfw");
 }
 $statusvar = $tmpbar;
 $update->configure(-state => "normal");
 $options->configure(-state => "normal");
 $connect->configure(-state => "normal");
 $cancel->configure(-state => "normal");
 Tkx::update();
}

sub isoncs {
 return 0 unless defined $manport && defined $manpass;
 return 0 if ($cancel->cget(-text) eq $L->{$lang}{TXT_EXIT});
 my $sock = IO::Socket::INET->new(PeerHost => '127.0.0.1',
                                  PeerPort => $manport,
                                  Proto    => 'tcp',
                                  Timeout  => 2) or return 0;
 print $sock "$manpass\r\n";
 my $is_connected = 0;
 while (my $line = <$sock>) {
  if ($line =~ /INFO:OpenVPN Management Interface Version/) {
   print $sock "state\r\n";
   while (my $resp = <$sock>) {
    if ($resp =~ /CONNECTED,SUCCESS/) {
     $is_connected = 1;
     last;
    }
    last if $resp =~ /^END/;
   }
   last;
  }
 }
 eval {
  local $SIG{ALRM} = sub { die "timeout\n" };
  alarm(0.3);
  <$sock>; # This should hit EOF if OpenVPN exits
  alarm(0);
 };
 print $sock "exit\r\n" unless $@ =~ /timeout/;
 close($sock);
 return $is_connected;
}


sub genpass {
 # generate a random password for the management interface
 my @chars = ('a' .. 'z', '0' ..'9', 'A' .. 'Z');
 return join '' => map $chars[rand @chars], 0 .. int(rand(100))+20;
}

sub preresolve {
 my ($host) = @_;
 our @resolved_ips;

 my $max_tries = 3;
 my $attempt = 0;

 ATTEMPT:
 while ($attempt++ < $max_tries) {
  Tkx::update();
  @resolved_ips = ();

  my $pipe;
  if (open($pipe, "-|", "nslookup $host 2>&1")) {
   my $collect = 0;
   my $last_update = time;

   while (my $line = <$pipe>) {
    chomp $line;
    Tkx::update();
    if (time - $last_update >= 0.5) {
     $statusvar .= ".";
     Tkx::update();
     $last_update = time;
    }

    if ($line =~ /^\s*Addresses?:\s*/) {
     $collect = 1;
     if ($line =~ /:\s*([0-9a-fA-F:.]+)/) {
      push @resolved_ips, $1;
     }
     next;
    }

    next unless $collect;

    if ($line =~ /^\s*([0-9a-fA-F:.]+)\s*$/) {
     push @resolved_ips, $1;
    }

    Tkx::update();
   }
   close $pipe;
  }

  last ATTEMPT if @resolved_ips;

  $statusvar = "Error: failed to resolve $host, retrying";
  Tkx::update();

  my $wait_time = 2;
  my $start = time;
  my $dot_time = time;

  while (time - $start < $wait_time) {
   if (time - $dot_time >= 0.5) {
    $statusvar .= ".";
    Tkx::update();
    $dot_time = time;
   }
   select(undef, undef, undef, 0.05);  # 50ms sleep
  }
 }

 if (@resolved_ips < 1) {
  &do_error("nslookup failed to resolve $host");
 }
}

sub confgen {
 if ($disp_server ne $L->{$lang}{TXT_DEFAULT_SERVER}) {
  my @actual_server = grep(/$disp_server/,@servers);
  $server = $actual_server[0];
  $server = "" unless defined($actual_server[0]);
  $server =~ s/.*://;
 }
 if (!$server) {
  $server = $disp_server;
 }
 my @tmparray = grep(/$server/,@servers);
 if (defined($tmparray[0])) {
  my $tmpline = $tmparray[0];
  $tmpline =~ s/.*://;
  $tmpline =~ s/\.cstorm\.is//;
  @remote_random = ("$tmpline.cstorm.is", "$tmpline.cstorm.net", "$tmpline.cryptostorm.pw");
 }
 if (($disp_server eq $L->{$lang}{TXT_DEFAULT_SERVER}) || ($server eq $L->{$lang}{TXT_DEFAULT_SERVER})) {
  @remote_random = ("balancer.cstorm.is", "balancer.cstorm.net", "balancer.cryptostorm.pw");
 }
 if (($tls_sel ne "secp521r1") && ($adv_https_opt eq "on")) {
  $tls_sel = "secp521r1";
 }
 my $tlscrypt = "--tls-crypt ..\\user\\tc.key";
 if (-e "..\\user\tcv2.key") {
  $tlscrypt = "--tls-crypt-v2 ..\\user\\tcv2.key";
 }
 if ($tls_sel eq 'secp521r1') {
  $vpn_args = "$port_var --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_secp521r1.crt $tlscrypt";
 }
 if ($tls_sel eq 'Ed25519') {
  $vpn_args = "5061 --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_ed25519.crt $tlscrypt";
 }
 if ($tls_sel eq 'Ed448') {
  $vpn_args = "5062 --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_ed448.crt $tlscrypt";
 }
 if ($tls_sel eq 'ML-DSA-87') {
  $vpn_args = "5063 --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers AES-256-GCM --cipher AES-256-GCM --tls-version-min 1.2 --tls-ciphersuites TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_mldsa87.crt $tlscrypt";
 }
 if ($proto_var eq 'UDP') {
  if ($noipv6_var eq 'on') {
   $vpn_args .= " --proto udp4 --explicit-exit-notify 3 ";
  }
  else {
   $vpn_args .= " --proto udp --explicit-exit-notify 3 ";
  }
 }
 if ($proto_var eq 'TCP') {
  if ($noipv6_var eq 'on') {
   $vpn_args .= " --proto tcp4 ";
  }
  else {
   $vpn_args .= " --proto tcp ";
  }
 }
 if ($dnsleak_var eq "on") {
  $vpn_args .= " --block-outside-dns ";
 }
 if ($dnsleak_var eq "off") {
  $vpn_args .= " --pull-filter ignore \"block-outside-dns\" ";
 }
 if ($killswitch_var eq "on") {
  $vpn_args .= " --pull-filter ignore \"redirect-gateway def1\" ";
  $vpn_args .= " --redirect-gateway ";
 }
 if ($noipv6_var eq "on") {
  $vpn_args .= ' --block-ipv6 ';
 }
 if ($ts_var eq "on") {
  $vpn_args .= " --pull-filter ignore \"dhcp-option DNS 10.31.33.8\" ";
  $vpn_args .= " --pull-filter ignore \"dhcp-option DNS 2001:db8::8\" ";
  $vpn_args .= ' --dhcp-option DNS 10.31.33.7 ';
  if ($noipv6_var eq "off") {
   $vpn_args .= ' --dhcp-option DNS 2001:db8::7 ';
  }
 }
 $vpn_args .= ' --machine-readable-output ';
 $vpn_args .= ' --windows-driver wintun';
 $vpn_args .= ' --dev-node "cryptostorm VPN" ';
 if ($selected_adv_opt2 ne 'disabled') {
  $vpn_args .= " --mssfix $selected_adv_opt2 ";
 }
 if ($selected_adv_opt3 ne 'adaptive') {
  $vpn_args .= " --route-method $selected_adv_opt3 ";
 }
 if ($selected_adv_opt4 ne 'Any address') {
  $vpn_args .= " --local $selected_adv_opt4 ";
 }
 if ($adv_socks_opt eq "on") {
  if (($adv_socks_noauth_opt eq "on") || (($adv_socks_user_var eq "") && ($adv_socks_pass_var eq ""))) {
   $vpn_args .= " --socks-proxy $adv_socks_ip $adv_socks_port ";
  }
  else {
   open(SOCKS,">..\\user\\socks.dat");
   print SOCKS "$adv_socks_user_var\n";
   print SOCKS "$adv_socks_pass_var\n";
   close(SOCKS);
   $vpn_args .= " --socks-proxy $adv_socks_ip $adv_socks_port ..\\user\\socks.dat ";
  }
 }
 if ($adv_ssh_opt eq "on") {
  my $oldstatus = $statusvar;
  $statusvar = "Starting SSH tunnel...";
  Tkx::update();
  $local_tunnel_port = get_next_free_local_port(31337);
  system(1,"echo n|cs-ssh-tun -pw sshtunnel -N -D $local_tunnel_port -l sshtunnel $selected_tunnel_opt");
  if (is_tunnel_up($local_tunnel_port) < 0) {
   &do_error($L->{$lang}{ERR_TUNNEL});
   $adv_ssh_opt = "off";
   system(1,"taskkill /IM cs-ssh-tun.exe /F");
  }
  else {
   $vpn_args .= " --socks-proxy 127.0.0.1 $local_tunnel_port ";
  }
  $statusvar = $oldstatus;
  Tkx::update();
 }
 $manport = get_next_free_local_port(5000);
 $manpass = &genpass;
 open(MANPASS,">..\\user\\manpass.txt");
 print MANPASS "$manpass\n";
 close(MANPASS);
 $vpn_args .= " --management 127.0.0.1 $manport ..\\user\\manpass.txt ";
 my $random_node = $remote_random[rand @remote_random];
 if ($random_node !~ /balancer/) {
  my $cn_host = $random_node;
  $cn_host =~ s/\..*//;
  $vpn_args .= qq( --verify-x509-name "cryptostorm $cn_host server" name );
 }
 if ($adv_https_opt eq "on") {
  my $oldstatus = $statusvar;
  $statusvar = "Starting HTTPS tunnel...";
  Tkx::update();
  $local_tunnel_port = get_next_free_local_port(31337);
  open(STUNNEL,">stunnel.conf");
  print STUNNEL "[openvpn]\n" .
                "client = yes\n" .
                "accept = 127.0.0.1:$local_tunnel_port\n" .
                "connect = $random_node:443\n" .
                "sni = $sni_input_val";
  close(STUNNEL);
  my $confloc;
  if (-d "\\Program Files\\Cryptostorm Client\\bin") {
   $confloc = "\\Program Files\\Cryptostorm Client\\bin\\stunnel.conf";
  }
  if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
   $confloc = "\\Program Files (x86)\\Cryptostorm Client\\bin\\stunnel.conf";
  }
  system(1,qq(cs-https-tun.exe "$confloc"));
  if (is_tunnel_up($local_tunnel_port) < 0) {
   &do_error($L->{$lang}{ERR_TUNNEL});
   $adv_https_opt = "off";
   system(1,"taskkill /IM cs-https-tun.exe /F");
  }
  else {
   $vpn_args =~ s/^[0-9]+/--remote 127.0.0.1 $local_tunnel_port /;
  }
  $statusvar = $oldstatus;
  Tkx::update();
 }
 else {
  $vpn_args =~ s/^/--remote $random_node /;
 }
 $logfile = '..\\bin\\openvpn.log';
 unlink $logfile if -e $logfile;
 $vpn_args .= " --log $logfile";
}

sub fix_dns {
 %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.b_configure"} );
 &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
 $dnscrypt_var = "off";
 my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};
 foreach (keys %$interfaces) {
  my $GUID = $_;
  if ($GUID !~ /NameServer/) {
   $GUID =~ s/\/$//;
   $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer"} = "";
  }
 }
 system(1,"ipconfig /registerdns");
 Tkx::update();
 if (-e "..\\user\\mydns.txt") {
  unlink("..\\user\\mydns.txt");
 }
 @recover = ();
 &{ $stupidstrictrefs{'Tkx'} }(-state => "normal");
 Tkx::update();
 Tkx::tk___messageBox(-parent => $cw, -type =>    "ok",
                                       -message => "DNS for all network adapters has been set to DHCP\nand DNSCrypt has been disabled",
                                       -icon => "info", -title => "cryptostorm.is client");
}

sub is_tunnel_up {
 Tkx::update();
 if ($tunnel_check_counter == 100) {
  return -1;
 }
 my ($portnumber) = @_;
 my $proto = getprotobyname('tcp');
 my $iaddr = inet_aton('127.0.0.1');
 my $paddr = sockaddr_in($portnumber, $iaddr);
 socket(SOCKET, PF_INET, SOCK_STREAM, $proto);
 eval {
  connect(SOCKET, $paddr) || die "connect";
  close(SOCKET);
 };
 if ($@) {
  $tunnel_check_counter++;
  is_tunnel_up($portnumber);
 }
 else {
  $tunnel_check_counter = 0;
  return 1;
 }
}
