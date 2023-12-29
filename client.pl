#-d:Trace
#$Devel::Trace::TRACE = 1;
#BEGIN {
# my $trace_file = "\\Program Files (x86)\\Cryptostorm Client\\user\\mytrace.$$.txt";
# print STDERR "Saving trace to $trace_file\n";
# open my $fh, '>>', $trace_file;
# sub DB::DB {
#  my ($package, $file, $line ) = caller;
#  my $code = \@{"::_<$file"};
#  print $fh "[@{[time]}] $file $line $code->[$line]" if ($file =~ /client.pl/);
#  print "[@{[time]}] $file $line $code->[$line]" if ($file =~ /client/);
# }
#}
if (-d "\\Program Files\\Cryptostorm Client\\bin") {
 chdir("\\Program Files\\Cryptostorm Client\\bin\\");
}
if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
 chdir("\\Program Files (x86)\\Cryptostorm Client\\bin\\");
}
our $VERSION = "3.55";
use strict;
use warnings;
use threads;
use threads::shared;
use Data::Dumper;
use Time::Out qw(timeout);
use Tkx;
use Tkx::SplashScreen;
#$Tkx::TRACE=64;
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
use LWP::UserAgent;
use Socket;
use Win32::AbsPath;
use Win32::File::VersionInfo;
use Win32::Process;
use Win32::Process::List;
use Win32::Clipboard;
my $clip = Win32::Clipboard();
use Win32::TieRegistry qw(REG_DWORD REG_MULTI_SZ REG_SZ),(Delimiter => "/");
$Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'} = {};
my $regkey = $Registry->{'HKEY_CURRENT_USER/Software/Cryptostorm/'};
use Win32::IPHelper;
use Net::DNS;
use Net::DNS::Resolver::MSWin32;
our $self = Win32::AbsPath::Fix "$0";
our $BUILDVERSION;
our ($ovpnver, $osslver, $verstuff, $final_data, $counter, $doupgrade, $total_size, $fh, $dnsleak_var);
my $manport;
our ($fixdns_btn);
our @animation = qw( \ | / -- );
our @output;
our @resolved_ips;
our @addresses;
our @favs : shared;
our @remote_random = ();
our $rt;
our $manpass;
our $update_err : shared;
our $logfile;
my $lang;
my $sel_lang;
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
 $BUILDVERSION = "3.45.0.0";
}
our $iwasconnected = 0;
my $masterpid;
my %stupidstrictrefs;
my $buffer : shared;
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
my ( $ovpnline, $bit, $vpnexe, $osslexe, $dnscexe, $h);
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
my $dns_choice_opt = "off";
our $fav_combo;
our $fav_button;
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
if (-e "..\\user\\logo.jpg") {
 copy("..\\user\\logo.jpg",$authfile);
 unlink("..\\user\\logo.jpg");
}
if (-e $ENV{'TEMP'} . '\client.dat') {
 copy($ENV{'TEMP'} . '\client.dat',$hashfile);
 unlink($ENV{'TEMP'} . '\client.dat');
}
if (-e $ENV{'TEMP'} . '\logo.jpg') {
 copy($ENV{'TEMP'} . '\logo.jpg',$authfile);
 unlink($ENV{'TEMP'} . '\logo.jpg');
}
if (-e $ENV{'TEMP'} . '\config.ini') {
 copy($ENV{'TEMP'} . '\config.ini',$authfile);
 unlink($ENV{'TEMP'} . '\config.ini');
}
my $nostun_var = "on";
my $noipv6_var = "on";
my $tmp_noipv6_var;
my $tmp_nostun_var;
my $tmp_dnscrypt_var;
our $port_var = "443";
my $proto_var = "UDP";
my @protos = ('UDP', 'TCP');
my @tlses = ('secp521r1','Ed25519','Ed448');
my $tls_sel = 'secp521r1';
my $cipher_sel = 'AES-256-GCM';
my $selected_adv_opt2 = "1400";
my $selected_adv_opt3 = "adaptive";
my $selected_adv_opt4 = "0.0.0.0";
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
my $tapi_counter = 0;
my $timeout_var = 60;
my @tapicmd = ();
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
  if (/^nostun=(.*)$/) {
   $nostun_var = $1;
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
  if (/^dnschoice_opt=(.*)$/) {
   $dns_choice_opt = $1;
  }
  if ((/^lang=(.*)$/) && ($ARGV[0] ne "/LANG")) {
   $lang = $1;
   $sel_lang = $1;
  }
  if (/^favs=(.*)$/) {
   @favs = split(/,/,$1);
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
use Config::INI::Reader;
my $L = Config::INI::Reader->read_file('..\user\lang.ini');
my @langs;
if ($L->{$lang}{VALID} != 1) {
 my $mw = Tkx::widget->new(".");
 $mw->g_wm_withdraw();
 &do_error("Invalid language \"$lang\", reverting to English");
 $lang = "English";
}
foreach my $key (keys %$L) {
 if ($key ne "_") {
  push(@langs,$key);
 }
}
$widget_update_var = $L->{$lang}{TXT_UPDATE_WHEN1} unless defined($widget_update_var);
if (($widget_update_var eq $L->{'English'}{TXT_UPDATE_WHEN1}) && ($lang ne 'English')) {
 $widget_update_var = $L->{$lang}{TXT_UPDATE_WHEN1};
}
$disp_server = $L->{$lang}{TXT_DEFAULT_SERVER} unless defined($disp_server);
my $hiddenornot : shared = $L->{$lang}{TXT_HIDE};
#Tkx::package_require('img::png');
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
 &do_error($L->{$lang}{ERR_NEEDADMIN});
 exit;
}
my ($STRING, $MAJOR, $MINOR, $BUILD, $ID) = Win32::GetOSVersion();
if ($MAJOR < 6) {
 &do_error($L->{$lang}{ERR_OLDWIN});
 &do_exit;
}
my $tapexe;
#if ($MAJOR == 6) {
# $tapexe = "tap-windows-9.24.2-I601-Win7.exe";
#}
#if ($MAJOR == 10) {
# $tapexe = "tap-windows-9.24.2-I601-Win10.exe";
#}
$tapexe = "tap-windows-9.21.2.exe";
sub TERM_handler {
 $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
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
foreach my $pids ( keys %procs ) {
 next if $pids == $masterpid;
 if ($procs{$pids} =~ /csvpn/) {
  system(1,"TASKKILL /F /T /PID $pids");
 }
 if ($procs{$pids} =~ /^client.exe$/) {
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
$verstuff = `$osslexe version 2>&1`;
if ($verstuff =~ /OpenSSL ([0-9\.a-z]+)/) {
 $osslver = $1;
}

if ($autosplash_var ne "on") {
 my $sr = $mw->new_tkx_SplashScreen(
 -image      => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
# -width      => 'auto',
# -height     => 'auto',
 -width      => '480',
 -height     => '272',
 -show       => 1,
 -topmost    => 1,
 );
 #my $cv = $sr->canvas();
 #$cv->create_text(480, 272, -text => "...", -anchor => 'se', -fill => "green");
 Tkx::after(1000 => sub {
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
my $chk_splash = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_NOSPLASH}, -variable => \$autosplash_var, -onvalue => "on", -offvalue => "off");
my $chk_autocon = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_CONNECT}, -variable => \$autocon_var, -onvalue => "on", -offvalue => "off");
my $chk_autorun = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_START}, -variable => \$autorun_var, -onvalue => "on", -offvalue => "off");
my $chk_update = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_UPDATE}, -variable => \$update_var, -onvalue => "on", -offvalue => "off");
my @widget_update_values = ($L->{$lang}{TXT_UPDATE_WHEN2},$L->{$lang}{TXT_UPDATE_WHEN1});
$widget_update_var = $L->{$lang}{TXT_UPDATE_WHEN1};
my $widget_update = $o_innerframe1->new_ttk__combobox(-textvariable => \$widget_update_var, -values => \@widget_update_values, -state=>"readonly");

$lbl_blank->g_grid(-column => 0, -row => 0, -sticky => "nw");
$chk_splash->g_grid(-column => 0, -row => 1, -sticky => "w");
$chk_autocon->g_grid(-column => 0, -row => 2, -sticky => "w");
$chk_autorun->g_grid(-column => 0, -row => 3, -sticky => "w");
#$chk_update->g_grid(-column => 0, -row => 4, -sticky => "w");
#$widget_update->g_grid(-column => 1, -row => 4, -sticky => "w");
if ($#langs > 0) {
 $lbl_lang->g_grid(-column => 0, -row => 6, -sticky => "w");
 $lang_update->g_grid(-column => 0, -row => 6, -sticky => "e");
}

$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PORT})->g_pack();
my $port_textbox = $o_innerframe2->new_ttk__entry(-textvariable => \$port_var, -width => 6)->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PROTOCOL})->g_pack();
my $proto_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=> (($adv_ssh_opt eq "on") || ($adv_https_opt eq "on") || ($adv_socks_opt eq "on")) ? "disabled" : "readonly")->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_TIMEOUT})->g_pack();
my @timeouts = (60, 120, 180, 240);
my $timeout_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$timeout_var, -values => \@timeouts, -width => 4, -state=>"readonly")->g_pack();
$o_innerframe2->new_ttk__checkbutton(-text => $L->{$lang}{TXT_RANDOM_PORT}, -variable => \$randomize_it, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($randomize_it eq "on") {
  $port_var = int(rand(29998) + 1);
  if (($port_var == 5061) || ($port_var == 5062)) {
   $port_var = $port_var + int(rand(1000 - 5));
  }
 }
 if ($randomize_it eq "off") {
  $port_var = 443;
 }
 })->g_pack(qw/-anchor n/);
$o_innerframe2->new_ttk__checkbutton(-text => $L->{$lang}{TXT_LET_ME_CHOOSE_EXIT}, -variable => \$dns_choice_opt, -onvalue => "on", -offvalue => "off")->g_pack();
my $selected_fav;
if ($#favs > -1) {
 $selected_fav = $favs[0];
 $fav_combo = $o_innerframe2->new_ttk__combobox(-textvariable => \$selected_fav, -values => \@favs, -width => 15, -state => "readonly")->g_pack();
 $fav_button = $o_innerframe2->new_ttk__button(-text => $L->{$lang}{TXT_FORGET}, -command => sub {
    @favs = grep !/$selected_fav/, @favs;
    if ($#favs == -1) {
	 undef $fav_combo;
	 undef $fav_button;
	 Tkx::destroy(".t.n.f2.c5");
	 Tkx::destroy(".t.n.f2.b");
	}
	else {
	 $selected_fav = $favs[0];
	 %stupidstrictrefs = (
      Tkx => \&{"Tkx::.t.n.f2.c5_configure"}
     );
	 &{ $stupidstrictrefs{'Tkx'} }(-values => \@favs, -textvariable => \$selected_fav);	
	}
 })->g_pack();
}
my $lbl_top = $o_innerframe4->new_ttk__label(-text => "Advanced options\n");
my @adv_opts2 = ('disabled','1300','1400','1500','1600');
my $adv_label2 = $o_innerframe4->new_ttk__label(-text => "--mssfix:  ");
my $adv_combo2 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt2, -values => \@adv_opts2, -width => 14, -state => "readonly");
my @adv_opts3 = ('adaptive','ipapi','exe');
$selected_adv_opt3 = $adv_opts3[0];
my $adv_label3 = $o_innerframe4->new_ttk__label(-text => "--route-method:  ");
my $adv_combo3 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt3, -values => \@adv_opts3, -width => 14, -state => "readonly");
my @adv_opts4 = ('0.0.0.0');
foreach (`ipconfig /all|findstr "IPv4 add"`) {
 if (/.*:\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/) {
  if ($1 !~ /^169\.254\./) {
   push(@adv_opts4,"$1");
  }
 }
}
$selected_adv_opt4 = $adv_opts4[0];
my $adv_label4 = $o_innerframe4->new_ttk__label(-text => "Bind to IP:  ");
my $adv_combo4 = $o_innerframe4->new_ttk__combobox(-textvariable => \$selected_adv_opt4, -values => \@adv_opts4, -width => 14, -state => "readonly");

my $adv_socks_ip_lbl = $o_innerframe4->new_ttk__label(-text => "IP/Host", -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"));
$adv_socks_ip = "127.0.0.1";
my $adv_socks_ip_txt = $o_innerframe4->new_ttk__entry(-textvariable => \$adv_socks_ip, -width => 14, -state => (($adv_socks_opt eq "on") ? "normal" : "disabled"), -validate => "focusout", -validatecommand => sub { 
 if ($adv_socks_ip !~ /^[0-9a-zA-Z\-\.]+$/) {
  &do_error("Invalid IP/host specified for SOCKS proxy\n");
  return 1;
 }
 if ($adv_socks_ip =~ /^\-/) { 
  &do_error("SOCKS host name can't start with a dash.\n");
  return 1; 
 }
 if ($adv_socks_ip =~ /\-$/) { 
  &do_error("SOCKS host name can't end with a dash.\n");
  return 1; 
 }
 if ($adv_socks_ip =~ /^\./) { 
  &do_error("SOCKS host name can't start with a period.\n");
  return 1; 
 }
 if ($adv_socks_ip =~ /\.$/) { 
  &do_error("SOCKS host name can't end with a period.\n");
  return 1; 
 }
 if ($adv_socks_ip =~ /\.\./) { 
  &do_error("Period can't be next to a period in SOCKS host name.\n"); 
  return 1;
 }
 if ($adv_socks_ip =~ /\.\-/) { 
  &do_error("Dash can't be after a period in SOCKS host name.\n");
  return 1;  
 }
 if ($adv_socks_ip =~ /\-\./) { 
  &do_error("Dash can't be before a period in SOCKS host name.\n");
  return 1;
 }
 if ($adv_socks_ip eq "0.0.0.0") {
  return;
 }
 if ($adv_socks_ip =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
  if ((($1 <= 0) || ($1 > 255)) ||
      (($2 < 0) || ($2 > 255)) ||
	  (($3 < 0) || ($3 > 255)) ||
	  (($4 <= 0) || ($4 > 255))) {
   &do_error("Invalid IP specified for SOCKS\n");
   return 1;
  }
 }
 return 0;
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
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
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
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.c8_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
  %stupidstrictrefs = ( Tkx => \&{"Tkx::.t.n.f4.l9_configure"} );
  &{ $stupidstrictrefs{'Tkx'} }(-state => "disabled");
 }
}, -state => ((($adv_ssh_opt eq "on") || ($adv_socks_opt eq "on")) ? "disabled" : "normal"));
my @tunnel_nodes;
open(NODELIST, "$nodelistfile") || &do_error($L->{$lang}{ERR_CANT_OPEN} . " $nodelistfile");
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


$o_tabs->add($o_innerframe1, -text => $L->{$lang}{TXT_STARTUP});
$o_tabs->add($o_innerframe2, -text => $L->{$lang}{TXT_CONNECTING});
$o_tabs->add($o_innerframe3, -text => $L->{$lang}{TXT_SECURITY});
$o_tabs->add($o_innerframe4, -text => "Advanced");

if ($randomize_it eq "on") {
 $port_var = int(rand(29998) + 1);
 if (($port_var == 5061) || ($port_var == 5062)) {
  $port_var = $port_var + int(rand(1000 - 5));
 }
}
else {
 $port_var = 443;
}
my $i3_blank_lbl = $o_innerframe3->new_ttk__label(-text => "\n");
my $ecc_lbl = $o_innerframe3->new_ttk__label(-text => "TLS cipher");
my $tls_sel_opt = $o_innerframe3->new_ttk__combobox(-textvariable => \$tls_sel, -values => \@tlses, -width => 9, -state=> 'readonly');
my $cipher_lbl = $o_innerframe3->new_ttk__label(-text => "data cipher");
my $cipher_sel_opt = $o_innerframe3->new_ttk__combobox(-textvariable => \$cipher_sel, -values => ['AES-256-GCM','CHACHA20-POLY1305'], -width => 20, -state=> 'readonly');
my $ipv6_disable_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DISABLE_IPV6}, -variable => \$noipv6_var, -onvalue => "on", -offvalue => "off");
my $stun_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_STUN_LEAK}, -variable => \$nostun_var, -onvalue => "on", -offvalue => "off");
my $dnsleak_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DNS_LEAK}, -variable => \$dnsleak_var, -onvalue => "on", -offvalue => "off");
my $dnscrypt_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_DNSCRYPT}, -variable => \$dnscrypt_var, -onvalue => "on", -offvalue => "off", -state => (($dnscrypt_var eq "local") ? "disabled" : "normal"));
my $killswitch_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_KILLSWITCH}, -variable => \$killswitch_var, -onvalue => "on", -offvalue => "off");
my $adblock_opt = $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_ADBLOCK}, -variable => \$ts_var, -onvalue => "on", -offvalue => "off");

$i3_blank_lbl->g_grid(-column => 0, -row => 0, -sticky => "w");
$ecc_lbl->g_grid(-column => 0, -row => 1, -sticky => "w");
$tls_sel_opt->g_grid(-column => 0, -row => 1); #.t.n.f3.c
$cipher_lbl->g_grid(-column => 1, -row => 1, -sticky => "w");
$cipher_sel_opt->g_grid(-column => 2, -row => 1);
$ipv6_disable_opt->g_grid(-column => 0, -row => 2, -sticky => "w");
$stun_opt->g_grid(-column => 0, -row => 3, -sticky => "w");
$dnsleak_opt->g_grid(-column => 0, -row => 4, -sticky => "w");
$dnscrypt_opt->g_grid(-column => 0, -row => 5, -sticky => "w");
$killswitch_opt->g_grid(-column => 0, -row => 6, -sticky => "w");
$adblock_opt->g_grid(-column => 0, -row => 7, -sticky => "w");

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
$userlbl->configure(-width => 55, -height => 10, -borderwidth => 0, -state=> 'disabled', -font => "TkTextFont", -cursor => 'arrow', -wrap => 'none', -background => 'gray95');
$frame2 = $mw->new_ttk__frame(-relief => "flat");
$token_textbox = $frame2->new_ttk__entry(-textvariable => \$token, -width => 27, -font => "token_font", -state => "normal");
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
 $popup_menu->add_command(-label => $L->{$lang}{TXT_PASTE}, -state => ((($clipboard =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
                                                                        ($clipboard =~ /^([a-f0-9]{128})$/)) ? "normal" : "disabled"), -underline => 1, -command => [ sub {
  $token = $clipboard;
 }]);
 $popup_menu->g_tk___popup($x,$y)
}
,Tkx::Ev('%X','%Y') ] );
$server_textbox = $frame2->new_ttk__combobox(-textvariable => \$disp_server, -width => 29, -state => "readonly");
@disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER});
open(NODELIST, "$nodelistfile") || &do_error($L->{$lang}{ERR_CANT_OPEN} . " $nodelistfile");
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
 Tkx::update();
 &blue_derp;
 $done = 0;
 $update->configure(-state => "disabled");
 $options->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $connect->configure(-state => "disabled");
 system 1, "ipconfig /flushdns";
 &blue_derp;
 $update_err = 0;
 $nodebuf = "";
 $updatethread = threads->create( \&update_node_list );
 &blue_derp;
 $updatethread->detach();
 &blue_derp;
 while (!$done) {
  Tkx::update();
  select(undef,undef,undef,0.001);
  if (defined $nodebuf and length $nodebuf) {
   &blue_derp;
   if ($status eq "text/plain") {
    &blue_derp;
    my $tmpnodebuf = $nodebuf;
    $nodebuf = '';
    @disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER});
    my @data=split(/\n/, $tmpnodebuf);
    open(NODELIST,">$nodelistfile") || &do_error($L->{$lang}{ERR_CANT_WRITE_TO} . " $nodelistfile");
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
    $update->configure(-state => "normal");
	$options->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = $L->{$lang}{TXT_UPDATE_NODELIST_DONE};
	$done = 1;
	$updatethread->kill('KILL');
   }
   else {
    &red_derp;
    $server_textbox->configure(-state => "readonly");
	$options->configure(-state => "normal");
    $update->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = $L->{$lang}{ERR_UPDATE_NODELIST};
	$done = 1;
	$updatethread->kill('KILL');
   }
  }
  last if $done;
 }
 if ($update_err) {
  &do_error("$update_err");
  $statusvar = $L->{$lang}{ERR_UPDATE_NODELIST};
 }
 $server_textbox->configure(-state => "readonly");
 $options->configure(-state => "normal");
 $update->configure(-state => "normal");
 $connect->configure(-state => "normal");
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
Tkx::bind($logbox,"<3>", [ sub {
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

if ((-e "..\\user\\all.wfw") || ($killswitch_var eq "on")) {
 $rt = `netsh advfirewall firewall show rule name="cryptostorm"`;
 if ($rt =~ /cryptostorm/) {
  $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno",
                                      -message => $L->{$lang}{QUESTION_KILLSWITCH1} . "\n" .
									              $L->{$lang}{QUESTION_KILLSWITCH2},
                                      -icon => "question", -title => "cryptostorm.is client");
  if ($tokillornot eq "yes") {
   &killswitch_off;
   $killswitch_var = "off";
  }
 }
}
if (($killswitch_var eq "on") && ($adv_socks_opt eq "on")) {
 Tkx::tk___messageBox(-icon => "info", -message => "The killswitch will be disabled since a SOCKS proxy is being used");
 $killswitch_var = "off";
}
if ($dnscrypt_var eq "on") {
 &dnscrypt(1);
}
if (defined($update_var) && ($update_var eq "on") && ($widget_update_var eq $L->{$lang}{TXT_UPDATE_WHEN2})) {
 $statusvar = $L->{$lang}{TXT_UPDATE_CHECKING} . "...";
 Tkx::update();
 &check_version;
 if ($latest != -1) {
  if ($VERSION < $latest) {
   $upgrade = 1;
  }
 }
 $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
 Tkx::update();
}
if ($autosplash_var eq "on") {
 $mw->g_wm_deiconify();
 $mw->g_raise();
 $mw->g_focus();
}
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
  $hiddenornot = $L->{$lang}{TXT_SHOW};
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
  $hiddenornot = $L->{$lang}{TXT_HIDE};
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
 #$TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
 Win32::GUI::NotifyIcon::Change($TrayNotify,
                -balloon => $balloon,
                -balloon_tip => $balloon_msg,
				-tip => "Cryptostorm Client",
				-balloon_timeout => 10,
                );
 if ($hiddenornot eq $L->{$lang}{TXT_SHOW}) {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => $L->{$lang}{TXT_OPTIONS},
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&showwin},
              ">-" => {-name => "LS"},
              ">" . $L->{$lang}{TXT_EXIT} => {-name => "Exit",-onClick => \&exitnshow }
               ) or &do_error($L->{$lang}{ERR_MENU});
 }
 if ($hiddenornot eq $L->{$lang}{TXT_HIDE}) {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => $L->{$lang}{TXT_OPTIONS},
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&hidewin, -default => 0},
              ">-" => {-name => "LS"},
              ">" . $L->{$lang}{TXT_EXIT} => {-name => "Exit", -onClick => \&exitnshow }
			  ) or &do_error($L->{$lang}{ERR_MENU});
 }
 if ($balloon) {
  $showtiponce = 1;
 }
}

sub exitnshow {
 &do_exit;
 &showwin;
}

sub TrackTrayMenu {
 if (defined($TrayNotify) && defined($TrayMenu)) {
  $TrayNotify->Win32::GUI::TrackPopupMenu($TrayMenu->{Options});
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
 if ($dnscrypt_var =~ /(on|off|local)/) {
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
 if ($nostun_var =~ /(on|off)/) {
  print CREDS "nostun=$1\n";
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
 if ($dns_choice_opt =~ /(on|off)/) {
  print CREDS "dnschoice_opt=$1\n";
 }
 if ($#favs > -1) {
  my $fav_ips;
  for (@favs) {
   $fav_ips .= "$_,";
  }
  $fav_ips =~ s/,$//;
  print CREDS "favs=$fav_ips\n";
 }
 if ($proto_var =~ /(UDP|TCP)/) {
  print CREDS "proto=$1\n";
 }
 if ($widget_update_var) {
  print CREDS "widget_update_var=$widget_update_var\n";
 }
 print CREDS "mssfix=$selected_adv_opt2\n";
 if ($selected_adv_opt3 ne "adaptive") {
  print CREDS "route-method=$selected_adv_opt3\n";
 }
 if ($selected_adv_opt4 ne "0.0.0.0") {
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
 &kill_it;
 system(1,"TASKKILL /F /T /IM $vpnexe");
 #$TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
 #undef $TrayWinHidden if defined $TrayWinHidden;
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
    &do_error("Tunnel host needs to be different from selected VPN node ($disp_server)");
    return;
   }
  }
 }
 $stop = 0;
 $idle = 0;
 #$logbox->delete("1.0","end") if defined $logbox;
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
 step_pbar();
 if (($autocon_var eq "on") && ($saveoption eq "off") || (!$saveoption)) {
  $autocon_var = "off";
 }
 Tkx::update();
 $statusvar = $L->{$lang}{TXT_CHECKING_TAP} . "...";
 &step_pbar();
 my $tap_ret = &check_tapi();
 if ($tap_ret == -1) {
  alarm 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $options->configure(-state => "normal");
  $update->configure(-state => "normal");
  $pbarval = 0;
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  Tkx::update();
  return;
 }
 my $stoopid;
 $frame4->g_grid(-column => 0, -row => 3, -sticky => "nswe");
 $logbox->g_grid(-column => 0, -row => 4, -sticky => "nwes");
 $scroll->g_grid(-column => 1, -row => 4, -sticky => "ns");
 Tkx::update('idletasks');
 my $x = int((Tkx::winfo('screenwidth',  $mw) / 2) - (Tkx::winfo('reqwidth',  $mw) / 2));
 my $y = int((Tkx::winfo('screenheight', $mw) / 2) - (Tkx::winfo('reqheight', $mw) / 2));
 $mw->g_wm_geometry(Tkx::winfo('reqwidth',  $mw) . "x" . Tkx::winfo('reqheight', $mw) . "+" . $x . "+" . $y);
 Tkx::update();
 &step_pbar();
 $statusvar = $L->{$lang}{TXT_LOGGING_IN} . "...";
 Tkx::update();
 open(TMP,">..\\user\\$hashfile") || &do_error($L->{$lang}{ERR_CANT_WRITE_TO} . " .\\user\\");
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
 if ($randomize_it eq "on") {
  $port_var = int(rand(29998) + 1);
  if (($port_var == 5061) || ($port_var == 5062)) {
   $port_var = $port_var + int(rand(1000 - 5));
  }
 }
 undef @tmparray;
 undef $tmpline;
 undef $vpn_args;
 Tkx::update();
 &confgen;
 Tkx::update();
 my $chosen_ip;
 my $chosen_node = $vpn_args;
 $chosen_node =~ s/.*remote ([a-zA-Z0-9\-\.]+) .*/$1/;
 $statusvar = $L->{$lang}{TXT_RESOLVING} . " $chosen_node...";
 Tkx::update();
 @resolved_ips = ();
 my $dnsret = &preresolve($chosen_node);
 if ($dnsret eq "recon") {
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  $pbarval = 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  $worldimage->configure(-image => "mainicon");
  alarm 0;
  @resolved_ips = ();
  &recon($L->{$lang}{TXT_DNS_UPDATED} . "\n");
  return;
 }
 if ($#resolved_ips == -1) {
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  $pbarval = 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  $worldimage->configure(-image => "mainicon");
  alarm 0;
  @resolved_ips = ();
  return;
 }
 if (($adv_https_opt eq "on") || ($adv_ssh_opt eq "on")) {
  $dns_choice_opt = "off";
 }
 if (($#resolved_ips > 0) && ($dns_choice_opt eq "on")) {
  alarm 0;
  my $skipchoice = 0;
  my $chosen_ip;
  for (@resolved_ips) {
   my $tmpres = $_;
   for (@favs) {
	my $tmpfav = $_;
	if ($tmpres =~ /$_/) {
	 $skipchoice = 1;
	 $chosen_ip = $_;
	 $statusvar = $L->{$lang}{TXT_CONNECTING_TO} . " " . $L->{$lang}{TXT_PREV_SELECT} . " $chosen_ip...";
	 Tkx::update();
	}
   }
  }
  if (!$skipchoice) {
   $chosen_ip = &dnsw;
   if (!$chosen_ip) {
    $chosen_ip = $resolved_ips[0];
   }	
   $statusvar = $L->{$lang}{TXT_CONNECTING_TO} . " $chosen_ip...";
   Tkx::update();
  }
  $vpn_args =~ s/remote ([a-zA-Z0-9\.\-]+)/remote $chosen_ip/g;
  Tkx::update();
 }
 if (($#resolved_ips == 0) && ($dns_choice_opt eq "on")) {
  $statusvar = $L->{$lang}{TXT_SKIP_CHOICE};
  Tkx::update();
 }
 $statusvar = $L->{$lang}{TXT_CONNECTING} . "...";
 Tkx::update();
 @remote_random = ();
 @resolved_ips = ();
 $stop = 0;
 print "$vpnexe $vpn_args\n";
 $pid = open $VPNfh, "-|", "$vpnexe $vpn_args";
 $thread = threads->new( \&read_out, $VPNfh );
 $thread->detach();
 step_pbar();
 Tkx::update();
 @msgs = ('cryptostorm',
          'PUSH_REQUEST',
          'TAP-WIN32 device .* opened',
          'Route addition via IPAPI succeeded',
          'TLS: Initial packet from',
		  'tap');
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
 if (defined($buffer) && (length $buffer)) {
  $ovpnline   = $buffer;
  $buffer = '';
  $logbox->insert('end', $ovpnline);
  $logbox->see('end');
  Tkx::update() unless $idle;
  for (@msgs) {
   if ($ovpnline =~ /$_/) {
    &step_pbar();
   }
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
   system(1,"TASKKILL /F /T /IM $vpnexe");
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
   system(1,"TASKKILL /F /T /IM $vpnexe");
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Exiting due to fatal error/) {
   $logbox->insert_end("\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   my @lines = split /\n/, $ovpnline;
   $ovpnline = @lines[($#lines - 1 )];
   &do_error($ovpnline);
   system(1,"TASKKILL /F /T /IM $vpnexe");
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
   system(1,"TASKKILL /F /T /IM $vpnexe");
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Cannot resolve host address: (.*)/) {
   $logbox->insert_end($L->{$lang}{ERR_CANNOT_RESOLVE} . " $1\n", "badline");
   $logbox->see('end');
   $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
   $pbarval = 0;
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error("Cannot resolve $server");
   if ((&isoncs > 0) && ($dnscrypt_var eq "on")) {
	$worldimage->configure(-image => "mainicon");
    $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
    Tkx::update();
    &dnscrypt(0);
   }
   system(1,"TASKKILL /F /T /IM $vpnexe");
   alarm 0;
   close($VPNfh);
   $stop = 1;
   return -1;
  }
  if ($ovpnline =~ /Initialization Sequence Completed/) {
   delete $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Network/NewNetworkWindowOff/"};
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
    &do_error($L->{$lang}{ERR_CONNECT_TAP1} . " " . $L->{$lang}{ERR_CONNECT_TAP2} . " " . $L->{$lang}{ERR_CONNECT_TAP3});
	system(1,"TASKKILL /F /T /IM $vpnexe");
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
	$logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_DISCONNECTED} . '$',"insert");
	if (defined($logbox_index)) {
     if ($logbox_index =~ /[0-9\.]+/) {
	  $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
     }
    }
    $logbox->see('end');
	$statusvar = $L->{$lang}{TXT_CONNECTED};
	Tkx::update();
    $balloon_msg = $L->{$lang}{TXT_CONNECTED_BALLOON};
    $cancel->configure(-text => $L->{$lang}{TXT_DISCONNECT});	
	Tkx::update();
	alarm 0;
	if ($dnscrypt_var eq "on") {
	 &dnscrypt(0);
	 Tkx::update();
	}
	if ($update_var eq "on") {
     if ($widget_update_var eq $L->{$lang}{TXT_UPDATE_WHEN1}) {
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
        &grabnverify("bin/cryptostorm_setup.exe");
		copy("tmp\\cryptostorm_setup.exe",".");
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
	 }
	 if (defined($amsg)) {
      Tkx::tk___messageBox(-parent => $mw, -type =>    "ok",
                                           -message => "$amsg",
                                           -icon => "info", -title => "cryptostorm.is client");

     }
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
	 Tkx::update();
	}
	if (!$doupgrade) {
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
 	 Tkx::update();
     &hidewin;
	}
	Tkx::update();
   }
  }
 }
}

sub read_out {
 my ($lVPNfh) = @_;
 while (defined( my $rline = readline $lVPNfh) ) {
  $rline =~ s/^[0-9\.]+ [0-9a-f]+ //;
  if (($rline !~ /[UDPv4|TUN] [READ|WRITE]/) && 
      ($rline !~ /windows-driver/) &&
	  ($rline !~ /edirect-gateway and redirect-private/) &&
	  ($rline !~ /PID_ERR replay/) &&
	  ($rline !~ /CreateFile failed/) &&
      ($rline !~ /sending exit notification to peer/) &&
      ($rline !~ /\-\-mute/) &&
      ($rline !~ /mode = /) &&
	  ($rline !~ /config =/) &&
      ($rline !~ /Current Parameter Settings/) &&
	  ($rline !~ /MTU parms/) &&
	  ($rline !~ /MANAGEMENT/) &&
	  ($rline !~ /msg_channel=/)) {
   $buffer .= $rline;
  }
  last if $stop;
 }
 $buffer = '';
} 


sub do_exit {
 my $idunno = "whatever";
 Tkx::update();
 if (&isoncs > 0) {
  Tkx::update();
  $idunno = Tkx::tk___messageBox(-type =>    "yesno",
                                 -message => $L->{$lang}{QUESTION_DISCONNECT1} . "\n" .
								             $L->{$lang}{QUESTION_DISCONNECT2} . "\n" .
											 $L->{$lang}{QUESTION_DISCONNECT3},
	                             -icon => "question", -title => "cryptostorm.is client");
 }
 if (($idunno eq "yes") || ($idunno eq "whatever")) {
  &showwin;
  #if (($dnscrypt_var eq "on") && ($idunno eq "yes")) {
  # $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
  # Tkx::update();
  # &dnscrypt(0);
  #}
  @resolved_ips = qw();
  Tkx::update();
  $cancel->configure(-state => "disabled");
  Tkx::update();
  &kill_it;
  Tkx::update();
  $pbarval = 0;
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_EXIT}) {
   &savelogin;
   if ($adv_ssh_opt eq "on") {
    system(1,"taskkill /IM cs-ssh-tun.exe /F");
   }
   if ($adv_https_opt eq "on") {
    system(1,"taskkill /IM cs-https-tun.exe /F");
   }
   if ($dnscrypt_var eq "on") {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . "...";
    Tkx::update();
    &dnscrypt(0);
    Tkx::update();
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
    $rt = `netsh advfirewall firewall show rule name="cryptostorm"`;
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
   Tkx::update();
   &nostun_off;
   Tkx::update();
   system(1,"ipconfig /registerdns");
   Tkx::update();
   system(1,"TASKKILL /F /T /IM $vpnexe");
   Tkx::update();
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   if ($doupgrade) {
    system(1,"cryptostorm_setup.exe");
   }
   $stop = 1;
   $done = 1;
   $o_done3 = 1;
   if (-e "..\\user\\mydns.txt") {
    unlink("..\\user\\mydns.txt");
   }
   if (-e "..\\user\\socks.dat") {
    unlink("..\\user\\socks.dat");
   }
   $o_thread3->kill('KILL') unless !defined $o_thread3;
   $mw->g_destroy() if defined $mw;
   exit(0);
  }
  Tkx::update();
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_DISCONNECT}) {
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
   &kill_it;
   if ($dnscrypt_var eq "on") {
    $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
    Tkx::update();
    &dnscrypt(1);
   }
   $worldimage->configure(-image => "mainicon");
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
   #$logbox->delete("end - 1 line","end");
   #$logbox->delete("end - 1 line","end");
   #$logbox->insert_end("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
   $logbox->insert_end($L->{$lang}{TXT_DISCONNECTED} . "\n", "badline");
   $logbox_index = $logbox->search(-regexp, '^' . $L->{$lang}{TXT_CONNECTED} . '$',"insert");
   Tkx::update();
   if (defined($logbox_index)) {
    if ($logbox_index =~ /[0-9\.]+/) {
	 $logbox->delete($logbox_index,sprintf("%.1f", ($logbox_index+1)));
	}
   }
   $logbox->see('end');
   system(1,"TASKKILL /F /T /IM $vpnexe");
   $thread->kill('KILL') if defined($thread);
   #$TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   #undef $TrayWinHidden if defined $TrayWinHidden;
   $cancel->configure(-state => "normal");
   $statusvar = $L->{$lang}{TXT_DISCONNECTED};
   $pbarval = 0;
   $idle = 1;
   Tkx::update();
  }
 }
}

sub ren_tap {
 foreach my $subkey (keys( %{ $Registry->{"LMachine/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}"} } )) {
  my $NetCfgInstanceId = $Registry->{"LMachine/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}/$subkey/NetCfgInstanceId"};
  my $DriverDesc       = $Registry->{"LMachine/SYSTEM/ControlSet001/Control/Class/{4D36E972-E325-11CE-BFC1-08002BE10318}/$subkey/DriverDesc"};
  if (defined($DriverDesc) && ($DriverDesc eq "TAP-Windows Adapter V9")) {
   $Registry->{"LMachine/SYSTEM/ControlSet001/Control/Network/{4D36E972-E325-11CE-BFC1-08002BE10318}/$NetCfgInstanceId/Connection/Name"} = 'cryptostorm';
   return 1;
  }
 }
}

sub make_tap {
 $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/ControlSet001/Control/Network/NewNetworkWindowOff/'} = {};
 my $tap_install = system(1, "$tapexe /S");
 if (defined($tap_install)) {
  $statusvar = $L->{$lang}{TXT_TAP_INSTALLING} . "...";
  Tkx::update();
  while (kill(0,$tap_install) == 1) {
   Tkx::update();
   select(undef,undef,undef,0.01);
  }
  undef $tap_install;
 }
 else {
  &do_error("Unable to install TAP adapter");
  alarm 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $options->configure(-state => "normal");
  $update->configure(-state => "normal");
  $pbarval = 0;
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  Tkx::update();
 }
}

sub check_tapi {
 $tapi_counter++;
 if ($tapi_counter == 5) {
  &do_error("TAP install failed.\nStarting the Network Connections control panel...\nIf you see a TAP adapter listed, rename it to \"cryptostorm\"\nthen try connecting again.\nIf you don't see one listed, a reboot might be required");
  system(1,"ncpa.cpl");
  $tapi_counter = 0;
  return -1;
 }
 @tapicmd = `$vpnexe --show-adapters 2>&1|findstr "cryptostorm"`;
 if (defined($tapicmd[0])) {
  $statusvar = $L->{$lang}{TXT_TAP_FOUND};
  $tapi_counter = 0;
  Tkx::update();
  @tapicmd = ();
  return 1;
 }
 else {
  &make_tap;
  &ren_tap;
  Tkx::update();
  @tapicmd = ();
  return 1;
 }
}

sub uniq {
 my %seen;
 grep !$seen{$_}++, @_;
}

sub update_node_list {
 local $SIG{KILL} = sub { $done = 1;threads->exit; };
 my ($ua,$response);
 my @headers = ('User-Agent' => "Cryptostorm client");
 $ua = LWP::UserAgent->new(agent => "Cryptostorm client");
 $ua->timeout(10);
 $response = $ua->get("https://cryptostorm.nu/nodelist4.txt", @headers);
 $status = $response->content_type;
 if ($response->is_success) {
  while (defined($response->content and length $response->content)) {
   $nodebuf .= $response->content;
   last if $done;
  }
  $nodebuf = '';
 }
 else {
  $update_err = $response->status_line;
  $done = 1;
 }
}

sub do_options {
 if ($saveoption eq "off") {
  $autocon_var = "off";
 }
 $tmp_noipv6_var = $noipv6_var;
 $tmp_nostun_var = $nostun_var;
 $tmp_dnscrypt_var = $dnscrypt_var;
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
 if ($#favs > -1) {
  $selected_fav = $favs[0];
  if (defined($fav_combo)) {
   # the "beyond ugly" solution at https://www.perlmonks.org/?node_id=740013 works,
   # but will fail with strict refs. this works with strict refs:
   %stupidstrictrefs = (
    Tkx => \&{"Tkx::.t.n.f2.c5_configure"}
   );
   &{ $stupidstrictrefs{'Tkx'} }(-values => \@favs);
  }
  else {
   $fav_combo = $o_innerframe2->new_ttk__combobox(-textvariable => \$selected_fav, -values => \@favs, -width => 15, -state => "readonly")->g_pack();
   $fav_button = $o_innerframe2->new_ttk__button(-text => "Forget", -command => sub {
    @favs = grep !/$selected_fav/, @favs;
    if ($#favs == -1) {
	 undef $fav_combo;
	 undef $fav_button;
	 Tkx::destroy(".t.n.f2.c5");
	 Tkx::destroy(".t.n.f2.b");
	}
	else {
	 $selected_fav = $favs[0];
	 %stupidstrictrefs = (
      Tkx => \&{"Tkx::.t.n.f2.c5_configure"}
     );
	 &{ $stupidstrictrefs{'Tkx'} }(-values => \@favs, -textvariable => \$selected_fav);	
	}
   })->g_pack();
  }
 }
 Tkx::update();
}

sub backtomain {
 if ($adv_socks_opt eq "on") {
  if ($adv_socks_port =~ /^([0-9]+)$/) {
   if (($1 < 1) || ($1 > 65535)) {
    &do_error("Invalid SOCKS port");
    return;
   }
  }
  else {
   &do_error("Invalid SOCKS port");
   return;
  }
 }
 if ($adv_ssh_opt eq "on") {
  if ($disp_server ne "Global random") {
   my ($index) = grep { $servers[$_] =~ /$disp_server/} (0 .. @servers-1);
   my $tmpnode = $servers[$index];
   $tmpnode =~ s/.*://;
   if ($tmpnode eq $selected_tunnel_opt) {
    &do_error("Tunnel host needs to be different from selected VPN node ($disp_server)");
    return;
   }
  }
 }
 my $tmpvar = $statusvar;
 $port_var =~ s/[^0-9]//g;
 if ($port_var =~ /^([0-9]+)$/) {
  if (($1 < 1) || ($1 > 29999)) {
   &do_error($L->{$lang}{ERR_PORT});
   return;
  }
 }
 else {
  &do_error($L->{$lang}{ERR_PORT});
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
 if ($nostun_var ne $tmp_nostun_var) {
  if ($nostun_var eq "off") {
   &nostun_off;
  }
  if ($nostun_var eq "on") {
   &nostun_on;
  }
 }
 Tkx::update();
 if (($killswitch_var eq "on") && ($adv_socks_opt eq "on")) {
  Tkx::tk___messageBox(-icon => "info", -message => "The killswitch will be disabled since a SOCKS proxy is being used");
  $killswitch_var = "off";
 }
 &savelogin;
 Tkx::update();
 if ($killswitch_var eq "off") {
  Tkx::update();
  &killswitch_off;
  Tkx::update();
 }
 if ($killswitch_var eq "on") {
  my $winfirecheck = `net start|findstr "Windows.Firewall"`;
  if ($winfirecheck =~ /Windows Firewall/) {
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
 $statusvar = $tmpvar;
 &wait4thekill("ipconfig /registerdns");
 Tkx::update();
}

sub check_version {
 $o_done3 = 0;
 $o_thread3->kill('KILL') unless !defined($o_thread3);
 my $arg;
 $arg = $_[0] unless !defined $_[0];
 if (defined($arg)) {
  $o_thread3 = threads->new( \&check_version_thread($arg));
 }
 else {
  $o_thread3 = threads->new( \&check_version_thread());
 }
 $o_thread3->detach();
 while (!$o_done3) {
  Tkx::update();
  select(undef,undef,undef,0.001);
  if (defined($o_version_buf)) {
   $latest = $o_version_buf;
   $o_done3 = 1;
   if ($o_version_buf == -1) {
    $o_done3 = 1;
	return;
   }
   return;
  }
 }
 last if $o_done3;
}

sub check_version_thread {
 my $oncs = $_[0];
 my ($ua,$response);
 my @headers = ('User-Agent' => "Cryptostorm client");
 $ua = LWP::UserAgent->new(agent => "Cryptostorm client");
 $ua->timeout(2);
 #if (defined($oncs)) {
  $response = $ua->get("http://10.31.33.7/latest.txt", @headers);
 #}
 #else {
 # $response = $ua->get("https://cryptostorm.nu/latest.txt", @headers);
 #}
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
 my $dir_to_put;
 my $file_to_grab;
 if ($_[0] =~ /^(.*)\/(.*)$/) {
  $dir_to_put = $1;
  $file_to_grab = $2;
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
 my $tmpstatusvar = $statusvar;
 if ($_[0] == 0) {
  $statusvar = "Stopping DNSCrypt service...";
  Tkx::update();
  &wait4thekill("$dnscexe -service stop");
  Tkx::update();
  &wait4thekill("$dnscexe -service uninstall");
  $statusvar = "Uninstalling DNSCrypt service...";
  Tkx::update();
  $statusvar = "Restoring DNS settings...";
  Tkx::update();
  &restore_dns;
  $statusvar = $tmpstatusvar;
  Tkx::update();
 }
 if ($_[0] == 1) {
  $statusvar = "Installing DNSCrypt service...";
  Tkx::update();
  &wait4thekill("$dnscexe -service install");
  $statusvar = "Starting DNSCrypt service...";
  Tkx::update();
  &wait4thekill("$dnscexe -service start");
  Tkx::update();
  $statusvar = "Starting DNSCrypt service...";
  Tkx::update();
  $statusvar = "Setting DNS to DNSCrypt...";
  Tkx::update();
  &set_dns_to_dnscrypt;
  $statusvar = $tmpstatusvar;
  Tkx::update();
 }
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
   &kill_it;
   system(1,"TASKKILL /F /T /IM $vpnexe");
   #$TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   #undef $TrayWinHidden if defined $TrayWinHidden;
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
    $statusvar = "Setting $1 to DHCP...";
    Tkx::update();
   }
  }
  if (/^(.*):Static:(.*)$/) {
   if (($2 !~ /127\.0\.0\.1/) && ($dnscrypt_var ne "local")) {
    if ($1 !~ /NameServer/) {
	 $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$1/NameServer"} = "$2";
	 $statusvar = "Setting $1 to DNS $2...";
     Tkx::update();
	}
   }
   else {
    if ($1 !~ /NameServer/) {
     $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$1/NameServer"} = "";
	 $statusvar = "Setting $1 to DHCP...";
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
 system(1,"ipconfig /registerdns");
 Tkx::update();
}

sub set_dns_to_dnscrypt {
 my $tmpstatusvar = $statusvar;
 my $makesurednscryptisrunning = 0;
 foreach my $pids ( `net start|findstr "DNSCrypt"` ) {
  Tkx::update();
  if ($pids) {
   $makesurednscryptisrunning = 1;
  }
 }
 if ($makesurednscryptisrunning) {
  my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};
  foreach (keys %$interfaces) {
   my $GUID = $_;
   if ($GUID !~ /NameServer/) {
    $GUID =~ s/\/$//;
    my $intdns = $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer"};
    $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer"} = "127.0.0.1";
    $statusvar = "Setting adapter $GUID to DNSCrypt";
	Tkx::update();
   }
  }
 }
 $statusvar = $tmpstatusvar;
 Tkx::update();
 system(1,"ipconfig /registerdns");
 Tkx::update();
}

sub get_current_dns {
 my $interfaces = $Registry->{'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/'};
 foreach (keys %$interfaces) {
  Tkx::update();
  my $GUID = $_;
  if ($GUID !~ /NameServer/) {
   $GUID =~ s/\/$//;
   my $intdns = $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer"};
   if ($intdns) {
    if (($intdns =~ /127\.0\.0\.1/) && ($dnscrypt_var ne "local")) {
     if ($dnscrypt_var eq "off") {
      $Registry->{"HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/services/Tcpip/Parameters/Interfaces/$GUID/NameServer"} = "";
	  system(1,"ipconfig /registerdns");
	  Tkx::update();
	 }
	 push(@recover,"$GUID:DHCP:\n");
    }
    if ($intdns !~ /127\.0\.0\.1/) {
     push(@recover,"$GUID:Static:$intdns\n");
    }
   }
   else {
    push(@recover,"$GUID:DHCP:\n");
   }
  }
  if ($#recover > -1) {
   my $ret = open(MYDNS,">","..\\user\\mydns.txt");
   if ($ret) {
    print MYDNS @recover;
    close(MYDNS);
   }
  }
 }
}

sub wait4thekill {
 Tkx::update();
 my $runthis = system 1,qq($_[0]);
 while (kill(0,$runthis) == 1) {
  Tkx::update();
  select(undef,undef,undef,0.01);
  Tkx::update();
 }
 Tkx::update();
}

sub nostun_off {
 my $tmpstatusvar = $statusvar;
 $statusvar = $L->{$lang}{TXT_DISABLING_STUN_LEAK} . "...";
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall del rule name="cryptostorm - STUN leak block"));
 Tkx::update();
 $statusvar = $tmpstatusvar;
 Tkx::update();
}

sub nostun_on {
 my $tmpstatusvar = $statusvar;
 $statusvar = $L->{$lang}{TXT_ENABLING_STUN_LEAK} . "...";
 Tkx::update();
 &wait4thekill(qq(net start MpsSvc));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=out action=block protocol=UDP localport=3478));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=out action=block protocol=UDP remoteport=3478));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=in action=block protocol=UDP localport=3478));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=in action=block protocol=UDP remoteport=3478));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=out action=block protocol=UDP localport=19302));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=out action=block protocol=UDP remoteport=19302));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=in action=block protocol=UDP localport=19302));
 Tkx::update();
 &wait4thekill(qq(netsh advfirewall firewall add rule name="cryptostorm - STUN leak block" dir=in action=block protocol=UDP remoteport=19302));
 Tkx::update();
 $statusvar = $tmpstatusvar;
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
  $statusvar = $L->{$lang}{ERR_AUTOCON};
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
  &do_error($L->{$lang}{ERR_FREEPORT}) if $tryport > ($startport + 100);
 }
 return $freeport;
}

sub kill_it {
 if (!defined($manport)) { return -1; }
 if (!defined($manpass)) { return -1; }
 if ($cancel->cget(-text) eq $L->{$lang}{TXT_DISCONNECT}) {
  &killcx($manport);
  my ($socket,$client_socket,$data);
  $socket = new IO::Socket::INET (
  PeerHost => '127.0.0.1',
  PeerPort => $manport,
  Proto => 'tcp',
  Timeout => 1);
  if ($socket) {
   print $socket "$manpass\r\n";
   while (<$socket>) {
    if (/INFO:OpenVPN Management Interface Version/) {
	 print $socket "signal SIGTERM\r\nexit\r\n";
	 $stop = 1;
     close($socket);
	 system(1,"TASKKILL /F /T /IM $vpnexe");
	 &killcx($manport);
	 return;
    }
   }
  }
  else {
   return -1;
  }
 }
 else {
  $stop = 1;
  system(1,"TASKKILL /F /T /IM $vpnexe");
  &killcx($manport);
  return 1;
 }
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
 $rt = `netsh advfirewall export "..\\user\\all.wfw" 2>&1`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - " . $L->{$lang}{TXT_KILLSWITCH_EXPORT};
  Tkx::update();
 }
 $statusvar = "Kill switch - " . $L->{$lang}{TXT_KILLSWITCH_GET_VPN} . "...";
 Tkx::update();
 my $vpn_ips;
 for (@nodes) {
  Tkx::update();
  if (/^.*:.*:windows:(.*)$/) {
   $statusvar = "Kill switch - " . $L->{$lang}{TXT_RESOLVING} . " $1...";
   Tkx::update();
   @addresses = gethostbyname("$1") or &do_error($L->{$lang}{ERR_CANNOT_RESOLVE} . " $1: $!\n");
   Tkx::update();
   if ($#addresses == -1) {
    $killswitch_var = "off";
    $update->configure(-state => "normal");
    $options->configure(-state => "normal");
    $connect->configure(-state => "normal");
    $cancel->configure(-state => "normal");
    return;
   }
   @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
   Tkx::update();
   for (@addresses) {
    Tkx::update();
	$vpn_ips .= "$_,";
   }
  }
 }
 my @misc = ('balancer:balancer:windows:balancer.cstorm.is');
 for (@misc) {
  Tkx::update();
  if (/^.*:.*:windows:(.*)$/) {
   $statusvar = "Kill switch - " . $L->{$lang}{TXT_RESOLVING} . " $1...";
   Tkx::update();
   @addresses = gethostbyname("$1") or &do_error($L->{$lang}{ERR_CANNOT_RESOLVE} . " $1: $!\n");
   Tkx::update();
   if ($#addresses == -1) {
    $killswitch_var = "off";
    $update->configure(-state => "normal");
    $options->configure(-state => "normal");
    $connect->configure(-state => "normal");
    $cancel->configure(-state => "normal");
    return;
   }
   @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
   Tkx::update();
   for (@addresses) {
    Tkx::update();
	$vpn_ips .= "$_,";
   }
  }
 } 
 Tkx::update();
 $vpn_ips =~ s/,$//;
 my $ddns_ips;
 $statusvar = "Kill switch - " . $L->{$lang}{TXT_KILLSWITCH_GET_DDNS} . "...";
 Tkx::update();
 @addresses = gethostbyname("public.deepdns.net") or &do_error($L->{$lang}{ERR_CANNOT_RESOLVE} . ": $!\n");
 Tkx::update();
 if ($#addresses == -1) {
  $killswitch_var = "off";
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $connect->configure(-state => "normal");
  $cancel->configure(-state => "normal");
  return;
 }
 @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
 for (@addresses) {
  Tkx::update();
  $ddns_ips .= "$_,";
 }
 Tkx::update();
 my $csnu_ips;
 @addresses = gethostbyname("cryptostorm.nu") or &do_error($L->{$lang}{ERR_CANNOT_RESOLVE} . ": $!\n");
 Tkx::update();
 if ($#addresses == -1) {
  $killswitch_var = "off";
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $connect->configure(-state => "normal");
  $cancel->configure(-state => "normal");
  return;
 }
 @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
 for (@addresses) {
  $csnu_ips .= "$_,";
 }
 Tkx::update();
 $rt = `netsh advfirewall firewall delete rule name=all`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - deleting current firewall rules";
  Tkx::update();
 }
 $rt = `netsh advfirewall set allprofiles state on`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - turning on all profiles";
  Tkx::update();
 }
 $rt = `netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - private profile, blocking in/out";
  Tkx::update();
 }
 $rt = `netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - domain profile, blocking in/out";
  Tkx::update();
 }
 $rt = `netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - public profile, blocking in/out";
  Tkx::update();
 }
 $ddns_ips =~ s/,$//;
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=in action=allow remoteip=LocalSubnet`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow local subnet in";
  Tkx::update();
 }
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow remoteip=LocalSubnet`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow local subnet out";
  Tkx::update();
 }
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow program="%%SystemRoot%%\\system32\\svchost.exe" localip=0.0.0.0 localport=68 remoteip=255.255.255.255 remoteport=67 protocol=UDP`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow DHCP out";
  Tkx::update();
 }
 my @vpn_ips_arr = split(/,/,$vpn_ips);
 $vpn_ips = '';
 for (my $i=0; $i <= $#vpn_ips_arr; $i++) {
  $vpn_ips .= $vpn_ips_arr[$i] . ",";
  if ($i % 100 == 0) {
   $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow remoteip=$vpn_ips`;
   if ($rt =~ /Ok./) {
    $statusvar = "Kill switch - allow VPN IPs";
    Tkx::update();
   }
   $vpn_ips = '';   
  }
 }
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow remoteip=$ddns_ips`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow DeepDNS IPs";
  Tkx::update();
 }
 $csnu_ips =~ s/,$//;
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow remoteip=$csnu_ips`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow cryptostorm.nu";
  Tkx::update();
 }
 $rt = `netsh advfirewall set allprofiles settings inboundusernotification disable`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - disable notifications";
  Tkx::update();
 }
 $statusvar = $tmpbar;
 $update->configure(-state => "normal");
 $options->configure(-state => "normal");
 $connect->configure(-state => "normal");
 $cancel->configure(-state => "normal");
 Tkx::update();
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
   $statusvar = "Imported previous firewall rules";
   Tkx::update();
  }
  $rt = `netsh advfirewall firewall show rule name="cryptostorm"`;
  $statusvar = "Kill switch is enabled, disabling...";
  Tkx::update();
  if ($rt =~ /cryptostorm/) {
   $rt = `netsh advfirewall firewall del rule name="cryptostorm"`;
   if ($rt =~ /Ok./) {
    $statusvar = "Kill switch firewall rules deleted";
    Tkx::update();
   }
   $rt = `netsh advfirewall set allprofiles settings inboundusernotification enable`;
   if ($rt =~ /Ok./) {
    $statusvar = "Firewall notifications enabled";
    Tkx::update();
   }
   $rt = `netsh advfirewall set allprofiles firewallpolicy BlockInbound,AllowOutbound`;
   if ($rt =~ /Ok./) {
    $statusvar = "Firewall profile policies restored";
    Tkx::update();
   }
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

sub killcx {
 my $port = $_[0];
 for ($kcxt=0;$kcxt<=5;$kcxt++) {
  system ("..\\bin\\wkillcx.exe 127.0.0.1:$port");
 }
}

sub isoncs {
 if (!defined($manport)) { return 0; }
 if (!defined($manpass)) { return 0; }
 if ($cancel->cget(-text) eq $L->{$lang}{TXT_EXIT}) { return 0; }
 &killcx($manport);
 my $ison_socket = new IO::Socket::INET (
 PeerHost => '127.0.0.1',
 PeerPort => $manport,
 Proto => 'tcp',
 Timeout => 1) or return 0;
 print $ison_socket "$manpass\r\n";
 while (<$ison_socket>) { 
  if (/INFO:OpenVPN Management Interface Version/) {
   print $ison_socket "state\r\n";
   my $response = "";
   $ison_socket->recv($response, 64) || &killcx($manport);
   if ($response =~ /CONNECTED,SUCCESS/) {
    close($ison_socket);
    &killcx($manport);
    return 1;
   }
   else {
    &killcx($manport);
    return 0;
   }
  }
 }
 return 0;
 &killcx($manport);
}

sub genpass {
 # generate a random password for the management interface
 my @chars = ('a' .. 'z', '0' ..'9', 'A' .. 'Z');
 return join '' => map $chars[rand @chars], 0 .. int(rand(100))+20;
}

sub dnsw {
 my $dnsw = $mw->new_toplevel;
 $dnsw->g_wm_withdraw();
 Tkx::wm_title($dnsw, "");
 Tkx::wm_iconphoto($dnsw, "mainicon");
 $dnsw->g_wm_resizable(0,0);
 Tkx::wm_attributes($dnsw, -toolwindow => 1, -topmost => 1);
 my $dnsw_frame1 = $dnsw->new_ttk__frame();
 my $dnsw_label = $dnsw_frame1->new_ttk__label(-justify => "center", -compound => 'top', -text => "\n" . $L->{$lang}{TXT_CHOOSE_IP} . ":\n");
 my $dnsw_row = 2;
 my $dnsw_col = 0;
 my $the_ip;
 for (@resolved_ips) {
  $dnsw_frame1->new_ttk__radiobutton(-text => "$_", -variable => \$the_ip, -value => "$_")->g_grid(-column => $dnsw_col, -row => $dnsw_row, -sticky => "we");
  $dnsw_row++;
  if ($dnsw_row % 10 == 0) {
   $dnsw_col++;
   $dnsw_row=2;
  }
 }
 my $dnsw_button = $dnsw->new_ttk__button(-text => "Ok", -command => sub {
  $dnsw->g_destroy();
  Tkx::update();
 });
 $dnsw->g_wm_protocol('WM_DELETE_WINDOW', sub {
  $dnsw->g_destroy();
  Tkx::update();
 });
 my $dns_choice_member;
 my $dnsw_checkbox = $dnsw->new_ttk__checkbutton(-text => $L->{$lang}{TXT_REMEMBER}, -variable => \$dns_choice_member, -onvalue => "on", -offvalue => "off");
 $dnsw_frame1->g_grid(-column => 0, -row => 0);
 $dnsw_label->g_grid(-column => 0, -row => 0);
 $dnsw_row++;
 $dnsw_button->g_grid(-column => 0, -row => $dnsw_row);
 $dnsw_row++;
 $dnsw_checkbox->g_grid(-column => 0, -row => $dnsw_row);
 Tkx::update('idletasks');
 my $width  ||= Tkx::winfo('reqwidth',  $dnsw);
 my $height ||= Tkx::winfo('reqheight', $dnsw);
 my $x = int((Tkx::winfo('screenwidth',  $dnsw) / 2) - ($width / 2));
 my $y = int((Tkx::winfo('screenheight', $dnsw) / 2) - ($height / 2));
 $dnsw->g_wm_geometry($width . "x" . $height . "+" . $x . "+" . $y);
 $dnsw->g_bind("<Return>", sub { $dnsw_button->invoke(); });
 $dnsw_button->g_bind("<Return>", sub { $dnsw_button->invoke(); });
 $dnsw_label->g_bind("<Return>", sub { $dnsw_button->invoke(); });
 $dnsw_frame1->g_bind("<Return>", sub { $dnsw_button->invoke(); });
 $dnsw->g_bind("<Escape>", sub { $dnsw_button->invoke(); });
 $dnsw_button->g_bind("<Escape>", sub { $dnsw_button->invoke(); });
 $dnsw_label->g_bind("<Escape>", sub { $dnsw_button->invoke(); });
 $dnsw_frame1->g_bind("<Escape>", sub { $dnsw_button->invoke(); });
 $dnsw->g_raise();
 $dnsw->g_wm_deiconify();
 $dnsw->g_focus();
 Tkx::tkwait("window",$dnsw);
 if ($dns_choice_member eq "on") {
  push(@favs,"$the_ip");
 }
 return $the_ip;
}

sub preresolve {
 my $chosen_node = $_[0];
 $chosen_node =~ s/cstorm\.is.*/cstorm.is/;
 undef @resolved_ips;
 @resolved_ips = gethostbyname($chosen_node) or &do_error("Can't resolve $chosen_node: $!\n");
 @resolved_ips = map { inet_ntoa($_) } @resolved_ips[4 .. $#resolved_ips]; 
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
 if ($tls_sel eq 'secp521r1') {
  $vpn_args = "$port_var --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_secp521r1.crt --tls-crypt ..\\user\\tc.key";
 }
 if ($tls_sel eq 'Ed25519') {
  $vpn_args = "5061 --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_ed25519.crt --tls-crypt ..\\user\\tc.key";
 }
 if ($tls_sel eq 'Ed448') {
  $vpn_args = "5062 --client --auth-nocache --auth-user-pass ..\\user\\client.dat --dev tun --resolv-retry 16 --remote-cert-tls server --down-pre --verb 6 --mute 3 --data-ciphers $cipher_sel --cipher $cipher_sel --tls-version-min 1.2 --tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384 --tls-cipher TLS-ECDHE-ECDSA-WITH-CHACHA20-POLY1305-SHA256:TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca_ed448.crt --tls-crypt ..\\user\\tc.key";
 }
 if ($proto_var eq 'UDP') {
  $vpn_args .= " --proto udp --explicit-exit-notify 3 ";
 }
 if ($proto_var eq 'TCP') {
  $vpn_args .= " --proto tcp ";
 }
 if ($dnsleak_var eq "on") {
  $vpn_args .= " --block-outside-dns ";
 }
 if ($dnsleak_var eq "off") {
  $vpn_args .= " --pull-filter ignore \"block-outside-dns\" ";
 }
 if ($noipv6_var eq "on") {
  $vpn_args .= ' --block-ipv6 ';
 }
 if ($ts_var eq "on") {
  $vpn_args .= ' --dhcp-option DNS 10.31.33.7 ';
 }
 $vpn_args .= ' --machine-readable-output ';
 #$vpn_args .= ' --dev-node "cryptostorm" ';
 $vpn_args .= ' --windows-driver tap-windows6 ';
 if ($selected_adv_opt2 ne 'disabled') {
  $vpn_args .= " --mssfix $selected_adv_opt2 ";
 }
 if ($selected_adv_opt3 ne 'adaptive') {
  $vpn_args .= " --route-method $selected_adv_opt2 ";
 }
 if ($selected_adv_opt4 ne '0.0.0.0') {
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
                "sni = .";
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
