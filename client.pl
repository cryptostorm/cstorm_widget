#!/usr/bin/perl #-d:Trace
#$Devel::Trace::TRACE = 1;
#BEGIN {
# my $trace_file = $ENV{TRACE_FILE} // "mytrace.$$.txt";
# print STDERR "Saving trace to $trace_file\n";
# open my $fh, '>>', $trace_file;
# sub DB::DB {
#  my ($package, $file, $line ) = caller;
#  my $code = \@{"::_<$file"};
#  print $fh "[@{[time]}] $file $line $code->[$line]";
# }
#}
if (-d "\\Program Files\\Cryptostorm Client\\bin") {
 chdir("\\Program Files\\Cryptostorm Client\\bin\\");
}
if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
 chdir("\\Program Files (x86)\\Cryptostorm Client\\bin\\");
}
our $VERSION = "3.16";
use threads;
use threads::shared;
use Time::Out qw(timeout);
use strict;
use warnings;
use Tkx;
use Fcntl;
use Tie::File;
#$Tkx::TRACE=64;
use Tkx::SplashScreen;
use Win32;
use Win32::GUI();
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa373247%28v=vs.85%29.aspx
use constant WM_POWERBROADCAST => 0x218;
use constant PBT_APMSUSPEND => 0x4;
use constant PBT_APMRESUMEAUTOMATIC => 0x12;
use constant PBT_APMRESUMECRITICAL => 0x6;
if (defined &Win32::SetChildShowWindow) {
 Win32::SetChildShowWindow(0);
}
use Digest::SHA qw(sha512_hex);
use HTTP::Request::Common qw(GET POST);
use LWP::UserAgent;
use Digest::MD5::File qw(file_md5_hex url_md5_hex);
use IO::Socket;
use Socket;
use Win32::AbsPath;
use Win32::File::VersionInfo;
use Win32::Process;
use Win32::Process::Info;
use Win32::TieRegistry qw(REG_DWORD),(Delimiter => "/");
use File::Copy;
use Net::DNS::Resolver::MSWin32;
our $self = Win32::AbsPath::Fix "$0";
our $BUILDVERSION;
our ($ovpnver, $osslver, $replaceossl, $replaceovpn, $verstuff, $final_data, $counter, $manport, $doupgrade, $total_size, $fh, $dnsleak_var, $dncstat);
our ($dnsfix1,$dnsfix2, $startwinfire);
our @animation = qw( \ | / -- );
our @output;
our @resolved_ips;
our @addresses;
our @favs : shared;
our $rt;
our $manpass;
our $cfdns = 0;
my $lang = "English";
my $timeout_var = 60;
my $foo = GetFileVersionInfo ( "$self" );
if ($foo) {
 $BUILDVERSION = $foo->{FileVersion};
}
else {
 $BUILDVERSION = "3.16.0.0";
}
our $iwasconnected = 0;
my $masterpid;
my $buffer : shared;
my $stop : shared;
my $done : shared;
my $thread4_done : shared;
my $nodebuf : shared;
my $status : shared;
my $pid : shared;
my $o_version_buf : shared;
my $o_done3 : shared;
my $latest : shared;
my $amsg : shared;
my @latency_tmparray : shared;
my @latency_array : shared;
our @words;
our @dns_ips;
our @recover;
my $authfile = '..\user\logo.jpg';
my $hashfile = '..\user\client.dat';
my $vpncfgfile = '..\user\custom.conf';
our $whichvpn = "";
my $cacertfile = '..\user\ca.crt';
my $cclientfile = '..\user\client.crt';
my $clientkey  = '..\user\client.key';
my $nodelistfile = '..\user\nodelist.txt';
my $c = 0;
my $alreadylong = 0;
my $server = "";
my $widget_update_var;
my ( $line, $VPNfh, $thread, $updatethread, $bit, $tapexe, $vpnexe, $osslexe, $dnscexe, $h);
my ($frame1, $frame2, $frame3, $frame4, $saveoption, $password, $userlbl, $passlbl, $connect, $cancel, $pass, 
    $save, $progress, $pbar, $pbarval, $statuslbl, $statusvar, $token_textbox, $token, $worldimage, $logbox, 
	$scroll, $errorimage, $server_textbox, $disp_server, $tripimage, $server_host, $update, $menu, $send, $options);
my ($autocon, $autocon_var, $autorun, $autorun_var, $o_frame1, $o_worldimage, $back, $o_tabs, $o_innerframe1, 
    $o_innerframe2, $o_innerframe3);
my ($o_thread3, $o_thread4); 
my $autosplash_var = "";
my $dnscrypt_var = "on";
my $killswitch_var = "off";
my $ts_var = "on";
my ($TrayIcon,$TrayWinHidden,$TrayNotify,$TrayMenu);
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
my @tmparray;
my $tmpline = "";
my $vpn_args = "";
$SIG{'TERM'} = 'TERM_handler';
$SIG{'ABRT'} = 'TERM_handler';
$SIG{'INT'} = 'TERM_handler';
$SIG{'KILL'} = 'TERM_handler';
$SIG{'HUP'} = 'TERM_handler';
if ((-e $ENV{'TEMP'} . '\client.dat') && (-e $ENV{'TEMP'} . '\logo.jpg')) {
 copy($ENV{'TEMP'} . '\client.dat',$hashfile);
 copy($ENV{'TEMP'} . '\logo.jpg',$authfile);
 unlink($ENV{'TEMP'} . '\client.dat');
 unlink($ENV{'TEMP'} . '\logo.jpg');
}
my $nostun_var = "on";
my $ipv6_var = "on";
my $ecc_var = "off";
our $port_var = "443";
my $proto_var = "UDP";
my @protos = ('UDP', 'TCP');
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
   $ipv6_var = $1;
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
  if (/^ecc=(.*)$/) {
   $ecc_var = $1;
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
  if (/^lang=(.*)$/) {
   $lang = $1;
  }
  if (/^favs=(.*)$/) {
   @favs = split(/,/,$1);   
  }
 }
}

#`reg query "hklm\system\controlset001\control\nls\language" /v Installlanguage`
#returns:
#
#HKEY_LOCAL_MACHINE\system\controlset001\control\nls\language
#    Installlanguage    REG_SZ    0409
#
#somewhere there's a list that says 0409 = English, 0407 = German, 040C = French, 0C0A = Spanish, etc.
#could be useful for auto-loading non-English langs.
#
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
$disp_server = $L->{$lang}{TXT_DEFAULT_SERVER};
my $hiddenornot = $L->{$lang}{TXT_HIDE};

if ($randomize_it eq "on") {
 $port_var = int(rand(65533) + 1);
}

Tkx::package_require('img::png');
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
sub TERM_handler {
 $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                      -message => $L->{$lang}{QUESTION_ANOTHERPROG1} . "\n" .
									              $L->{$lang}{QUESTION_ANOTHERPROG2} . "\n" .
												  $L->{$lang}{QUESTION_ANOTHERPROG3} . "\n",
                                      -icon => "question", -title => "cryptostorm.is client");
 if ($tokillornot eq "yes") {
  if ($token) {
   copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
   copy($authfile,$ENV{'TEMP'} . "\\logo.jpg");
  }
  &do_exit;
 }
}
my $cw = $mw->new_toplevel;
$cw->g_wm_withdraw();
Tkx::tk(appname => "cryptostorm.is client");
Tkx::wm_iconphoto($mw, "mainicon");
&check_bit();
my $pi = Win32::Process::Info->new;
$masterpid = Win32::Process::GetCurrentProcessID();
my @info = $pi->GetProcInfo();
foreach(@info) {
 next if $_->{ProcessId} == $masterpid;
 if ($_->{Name} =~ /^$vpnexe$/) {
  Win32::Process::KillProcess ($_->{ProcessId}, 0);
 }
 if ($_->{Name} =~ /^client.exe$/) {  
  $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                      -message => $L->{$lang}{QUESTION_ONLYONE1} . "\n" .
									              $L->{$lang}{QUESTION_ONLYONE2} . "\n",
                                      -icon => "question", -title => "cryptostorm.is client");
  if ($tokillornot eq "yes") {
   Win32::Process::KillProcess ($_->{ProcessId}, 0);
  }
  if ($tokillornot eq "no") {
   Win32::Process::KillProcess ($masterpid, 0);
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

$verstuff = `..\\bin\\$vpnexe --version 2>&1`;
if ($verstuff =~ /OpenVPN ([0-9\.]+)/) {
 $ovpnver = $1;
}
$verstuff = `..\\bin\\$osslexe version 2>&1`;
if ($verstuff =~ /OpenSSL ([0-9\.a-z]+)/) {
 $osslver = $1;
} 

if ($autosplash_var ne "on") {
 my $sr2;
 my $sr = $mw->new_tkx_SplashScreen(
 -image      => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
 -width      => 'auto',
 -height     => 'auto',
 -show       => 1,
 -topmost    => 1,
 );
 my $cv = $sr->canvas();
 $cv->create_text(qw(10 10), -anchor => 'w'); 
 Tkx::after(2600 => sub {
  $sr->g_destroy();
  $sr2 = $mw->new_tkx_SplashScreen(
  -image      => Tkx::image_create_photo(-file => "..\\res\\burn.png"),
  -width      => 'auto',
  -height     => 'auto',
  -show       => 1,
  -topmost    => 1,
 );
 });
 Tkx::after(3000 => sub {
  $sr2->g_destroy();
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
Tkx::wm_title($mw, "cryptostorm widget v$BUILDVERSION");
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
$width  = Tkx::winfo('reqwidth',  $cw);
$height = Tkx::winfo('reqheight', $cw);
$width += 100;
$x = int((Tkx::winfo('screenwidth',  $cw)  - $width  ) / 2);
$y = int((Tkx::winfo('screenheight', $cw)  - $height ) / 2);
$o_tabs = $cw->new_ttk__notebook(-height => $height, -width => $width);
$o_innerframe1 = $o_tabs->new_ttk__frame();
$o_innerframe2 = $o_tabs->new_ttk__frame();
$o_innerframe3 = $o_tabs->new_ttk__frame();

my $powerw = Win32::GUI::Window->new();
$powerw->Hook(WM_POWERBROADCAST, \&power_event);
$powerw->Hide();

my $lbl_blank = $o_innerframe1->new_ttk__label(-text => "                           \n                           \n");
my $lbl_lang;
my $lang_update;
if ($#langs > 0) { 
 $lbl_lang = $o_innerframe1->new_ttk__label(-text => "\n" . $L->{$lang}{TXT_LANGUAGE} . ":\n");
 $lang_update = $o_innerframe1->new_ttk__combobox(-textvariable => \$lang, -values => \@langs, -state=>"readonly");
 $lang_update->g_bind("<<ComboboxSelected>>", sub {
  Tkx::tk___messageBox(-icon => "info", -message => "Restart the widget to switch the language to $lang");
 });
}
my $chk_splash = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_NOSPLASH}, -variable => \$autosplash_var, -onvalue => "on", -offvalue => "off");
my $chk_autocon = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_CONNECT}, -variable => \$autocon_var, -onvalue => "on", -offvalue => "off");
my $chk_autorun = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_AUTO_START}, -variable => \$autorun_var, -onvalue => "on", -offvalue => "off");
my $chk_update = $o_innerframe1->new_ttk__checkbutton(-text => $L->{$lang}{TXT_UPDATE}, -variable => \$update_var, -onvalue => "on", -offvalue => "off");
my @widget_update_values = ($L->{$lang}{TXT_UPDATE_WHEN2},$L->{$lang}{TXT_UPDATE_WHEN1});
$widget_update_var = $L->{$lang}{TXT_UPDATE_WHEN1} unless defined $widget_update_var;
my $widget_update = $o_innerframe1->new_ttk__combobox(-textvariable => \$widget_update_var, -values => \@widget_update_values, -state=>"readonly");

$lbl_blank->g_grid(-column => 0, -row => 0, -sticky => "nw");
$chk_splash->g_grid(-column => 0, -row => 1, -sticky => "w");
$chk_autocon->g_grid(-column => 0, -row => 2, -sticky => "w");
$chk_autorun->g_grid(-column => 0, -row => 3, -sticky => "w");
$chk_update->g_grid(-column => 0, -row => 4, -sticky => "w");
$widget_update->g_grid(-column => 0, -row => 4, -sticky => "e");
if ($#langs > 0) {
 $lbl_lang->g_grid(-column => 0, -row => 6, -sticky => "w");
 $lang_update->g_grid(-column => 0, -row => 6, -sticky => "e");
}

$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PORT})->g_pack();
my $port_textbox = $o_innerframe2->new_ttk__entry(-textvariable => \$port_var, -width => 6)->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_CONNECT_PROTOCOL})->g_pack();
my $proto_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"readonly")->g_pack();
$o_innerframe2->new_ttk__label(-text => $L->{$lang}{TXT_TIMEOUT})->g_pack();
my @timeouts = (60, 120, 180, 240);
my $timeout_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$timeout_var, -values => \@timeouts, -width => 4, -state=>"readonly")->g_pack();
$o_innerframe2->new_ttk__checkbutton(-text => "\n" . $L->{$lang}{TXT_RANDOM_PORT} . "\n", -variable => \$randomize_it, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($randomize_it eq "on") {
  $port_var = int(rand(65533) + 1);
 }
 if ($randomize_it eq "off") {
  if ($ecc_var eq "on") {
   $port_var = 5060;
  }
  else {
   $port_var = 443;
  }
 }
 });
$o_innerframe2->new_ttk__checkbutton(-text => $L->{$lang}{TXT_LET_ME_CHOOSE_EXIT}, -variable => \$dns_choice_opt, -onvalue => "on", -offvalue => "off")->g_pack();
my $selected_fav;
if ($#favs > -1) {
 $selected_fav = $favs[0]; 
 $fav_combo = $o_innerframe2->new_ttk__combobox(-textvariable => \$selected_fav, -values => \@favs, -width => 15, -state => "readonly")->g_pack();
 my %stupidstrictrefs;
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
$o_tabs->add($o_innerframe1, -text => $L->{$lang}{TXT_STARTUP});
$o_tabs->add($o_innerframe2, -text => $L->{$lang}{TXT_CONNECTING});
$o_tabs->add($o_innerframe3, -text => $L->{$lang}{TXT_SECURITY});

$o_innerframe3->new_ttk__label(-text => "                           \n")->g_pack(qw/-anchor nw/);
if ($bit eq "64") { 
 $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ECC}, -variable => \$ecc_var, -onvalue => "on", -offvalue => "off", -command => sub {
  if ($ecc_var eq "on") {   
   $port_var = 5060;
  }
  if ($ecc_var eq "off") {
   if ($randomize_it eq "on") {
    $port_var = int(rand(65533) + 1);
   }
   else {
    $port_var = 443;
   }
  }
 })->g_pack(qw/-anchor nw/);
}
if ($bit eq "32") { 
 $ecc_var = "off";
 $o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{ERR_ECC_BIT}, -variable => \$ecc_var, -onvalue => "on", -offvalue => "off", -state => "disabled")->g_pack(qw/-anchor nw/); 
}
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DISABLE_IPV6}, -variable => \$ipv6_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_STUN_LEAK}, -variable => \$nostun_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_DNS_LEAK}, -variable => \$dnsleak_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_DNSCRYPT}, -variable => \$dnscrypt_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_KILLSWITCH}, -variable => \$killswitch_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => $L->{$lang}{TXT_ENABLE_ADBLOCK}, -variable => \$ts_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);

$o_frame1->g_grid(-column => 0, -row => 0, -sticky => "nswe");
$o_worldimage->g_grid(-column => 0, -row => 0);
$back->g_grid(-column => 0, -row => 1, -sticky => "nswe");
$o_tabs->g_grid(-column => 1, -row => 0, -sticky => "nswe");

Tkx::update('idletasks');
$width  = Tkx::winfo('reqwidth',  $cw);
$height = Tkx::winfo('reqheight', $cw);
$height = $height - 20;
$width += 200;
$x = int((Tkx::winfo('screenwidth',  $cw)  - $width  ) / 2);
$y = int((Tkx::winfo('screenheight', $cw)  - $height ) / 2);
$cw->g_wm_geometry("+$x+$y");


$frame1 = $mw->new_ttk__frame(-relief => "flat");
$worldimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'mainicon', -compound => 'top', -text => "Token:", -font => "logo_font");
$errorimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'erroricon', -compound => 'top', -text => "Token:", -font => "logo_font");
$userlbl = $frame1->new_tk__text;
$userlbl->tag(qw/configure link1 -foreground blue -underline 1/);
$userlbl->tag(qw/configure link2 -foreground blue -underline 1/);
$userlbl->tag(qw/configure link3 -foreground blue -underline 1/);
$userlbl->tag_bind("link1", "<Button-1>", sub { system 1, "start https://cryptostorm.is/#section5"; $userlbl->tag(qw/configure link1 -foreground purple -underline 1/);});
$userlbl->tag_bind("link1", "<Double-1>", sub { });
$userlbl->tag_bind("link1", "<Enter>", sub { $userlbl->configure(-cursor => 'hand2'); });
$userlbl->tag_bind("link1", "<Leave>", sub { $userlbl->configure(-cursor => 'arrow'); });
$userlbl->tag_bind("link2", "<Button-1>", sub { system 1, "start https://cryptostorm.is/cryptofree"; $userlbl->tag(qw/configure link2 -foreground purple -underline 1/); });
$userlbl->tag_bind("link2", "<Double-1>", sub { });
$userlbl->tag_bind("link2", "<Enter>", sub { $userlbl->configure(-cursor => 'hand2'); });
$userlbl->tag_bind("link2", "<Leave>", sub { $userlbl->configure(-cursor => 'arrow'); });
$userlbl->tag_bind("link3", "<Button-1>", sub { system 1, "start https://cryptostorm.nu/"; $userlbl->tag(qw/configure link3 -foreground purple -underline 1/); });
$userlbl->tag_bind("link3", "<Double-1>", sub { });
$userlbl->tag_bind("link3", "<Enter>", sub { $userlbl->configure(-cursor => 'hand2'); });
$userlbl->tag_bind("link3", "<Leave>", sub { $userlbl->configure(-cursor => 'arrow'); });
$userlbl->insert("1.0", "\n" . $L->{$lang}{TXT_MAINWINDOW1} . "\n" . $L->{$lang}{TXT_MAINWINDOW2} . " ");
$userlbl->insert('insert', $L->{$lang}{TXT_HERE}, 'link1');
$userlbl->insert('insert', " , \n" . $L->{$lang}{TXT_MAINWINDOW3} . " ");
$userlbl->insert('insert', "Cryptofree", 'link2');
$userlbl->insert('insert', "\n " . $L->{$lang}{TXT_MAINWINDOW4} . "\n");
$userlbl->insert('insert', $L->{$lang}{TXT_MAINWINDOW5} . " ");
$userlbl->insert('insert', $L->{$lang}{TXT_HERE}, 'link3');
$userlbl->insert('insert', ".\n");
$userlbl->configure(-width => 55, -height => 10, -borderwidth => 0, -state=> 'disabled', -font => "TkTextFont", -cursor => 'arrow', -wrap => 'none', -background => 'gray95');
$frame2 = $mw->new_ttk__frame(-relief => "flat");
$token_textbox = $frame2->new_ttk__entry(-textvariable => \$token, -width => 27, -font => "token_font"); 
Tkx::bind($token_textbox,"<3>", [ sub {
 my($x,$y) = @_;
 my $current_window = Tkx::winfo('containing',$x,$y);
 my $pop_menu = $token_textbox->new_menu;
 my $popup_menu = $pop_menu->new_menu(-tearoff => 0,);
 $popup_menu->add_command(-label => $L->{$lang}{TXT_COPY}, -underline => 1, -command => [ sub {
  if (($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
      ($token =~ /^([a-f0-9]{128})$/)) {
   Tkx::clipboard("clear");
   Tkx::clipboard("append",$token);
  } 
 }]);
 $popup_menu->add_command(-label => $L->{$lang}{TXT_PASTE}, -underline => 1, -command => [ sub {
  my $clipboard = Tkx::clipboard("get");  
  if (($clipboard =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
      ($clipboard =~ /^([a-f0-9]{128})$/)) {
   $token = $clipboard;
  }  
 }]); 
 $popup_menu->g_tk___popup($x,$y)
}
,Tkx::Ev('%X','%Y') ] );
$server_textbox = $frame2->new_ttk__combobox(-textvariable => \$disp_server, -width => 29, -state => "readonly");
@disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER},"Cryptofree");
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
    @disp_servers = ($L->{$lang}{TXT_DEFAULT_SERVER},"Cryptofree");
    my @data=split(/\n/, $tmpnodebuf);
    open(NODELIST,">$nodelistfile") || &do_error($L->{$lang}{ERR_CANT_WRITE_TO} . " $nodelistfile");
    foreach my $line (uniq(@data)) {
	 if ($line =~ /windows/) {
      print NODELIST "$line\n";
      $line =~ /^(.*):(.*):(.*):(.*)$/;
      push(@disp_servers,"$1");
      push(@servers,"$line");
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
 Tkx::update();
});
if ($token) {
 $saveoption = "on";
}
my $tmptok;
if (defined($token)) {
 $tmptok = $token;
}
else {
 $tmptok = "";
}
$server_textbox->g_bind("<<ComboboxSelected>>", sub {
 $server_textbox->configure(-state => "readonly");
 if ($disp_server eq "Cryptofree") {
  $token = "813db7fa66134df5295d98c5abbf90ff7206d68f3372a25138ee9c2bbb4c96d22f978ffd3da550f8dc38a15e106bec5266f91bc8447241b79e4ae0ce9fb8ff88";
  Tkx::tooltip($token_textbox, "");
  $token_textbox->configure(-state => "disabled");
  $saveoption = "off";
  $save->configure(-state => "disabled");
  $whichvpn = "free";
 }
 else {
  $token = $tmptok;
  Tkx::tooltip($token_textbox, $L->{$lang}{TXT_TOOLTIP_TOKEN});
  $token_textbox->configure(-state => "normal");
  $save->configure(-state => "normal");
  $saveoption = "on";
  $whichvpn = "paid";
 }
});
$progress = $mw->new_ttk__frame(-padding => "3 0 0 0", -relief => "flat");
my $pbarlen = Tkx::winfo('reqwidth',  $mw) * 2 + Tkx::winfo('reqwidth',  $connect);
$pbar = $progress->new_ttk__progressbar (-orient => "horizontal", -length => $pbarlen, -mode => "determinate", -variable => \$pbarval)->g_grid (-column => 0, -row => 0, -sticky => "we");
$statuslbl = $mw->new_ttk__label(-textvariable => \$statusvar, -padding => "0 0 0 0", -relief => "sunken", -width => 64);
$frame4 = $mw->new_ttk__frame(-relief => "flat");
$logbox = $frame4->new_tk__text(-width => 40, -height => 14, -undo => 1, -state => "disabled", -bg => "black", -fg => "grey");
$logbox->tag_configure("goodline", -foreground => "black", -background => "green", -font => "helvetica 14 bold", -relief => "raised");
$logbox->tag_configure("badline", -background => "red", -font => "helvetica 14 bold", -relief => "raised");
$logbox->tag_configure("warnline", -foreground => "black", -background => "yellow", -font => "helvetica 14 bold", -relief => "raised");
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
$server_textbox->g_bind("<Return>", sub { $connect->invoke(); });
$token_textbox->g_bind("<Return>", sub { $connect->invoke(); });
$connect->g_bind("<Return>", sub { $connect->invoke(); });
$frame1->g_grid(-column => 0, -row => 0);
$worldimage->g_grid(-column => 0, -row => 0);
$userlbl->g_grid(-column => 1, -row => 0);
$frame2->g_grid(-column => 0, -row => 0, -sticky => "s");
$token_textbox->g_grid(-column => 0, -row => 3);
$save->g_grid(-column => 4, -row => 3, -sticky => "w");
$server_textbox->g_grid(-column => 0, -row => 2, -sticky => "nw");
$update->g_grid(-column => 4, -row => 2, -sticky => "w");
$frame3->g_grid(-column => 0, -row => 0, -sticky => "se");
$progress->g_grid (-column => 0, -row => 2, -sticky => "we");
$statuslbl->g_grid(-column => 0, -row => 1, -sticky => "w");
$options->g_grid(-column => 1, -row => 1, -sticky => "e");
$connect->g_grid(-column => 1, -row => 2, -sticky => "nswe");
$cancel->g_grid(-column => 0, -row => 1, -sticky => "e");
$password = "93b66e7059176bbfa418061c5cba87dd";
Tkx::update('idletasks');
$width  = Tkx::winfo('reqwidth',  $mw);
$height = Tkx::winfo('reqheight', $mw);
$x = int((Tkx::winfo('screenwidth',  $mw)  - $width  ) / 2);
$y = int((Tkx::winfo('screenheight', $mw)  - $height ) / 2);
$mw->g_wm_geometry("+$x+$y");
$pbarlen = $width;

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

if ($dnscrypt_var eq "on") { 
 &dnscrypt(1);
}
if (defined($update_var) && ($update_var eq "on") && ($widget_update_var eq $L->{$lang}{TXT_UPDATE_WHEN2})) {
 $statusvar = $L->{$lang}{TXT_UPDATE_CHECKING} . "...";
 Tkx::update();
 &check_version;
 if ($latest ne "nope") {
  if ($VERSION < $latest) {
   $upgrade = 1;
  }
 }
 $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
 Tkx::update();
}
if ($ipv6_var eq "on") {
 my $tmpstatusvar = $statusvar;
 $statusvar = $L->{$lang}{TXT_DISABLING_IPV6} . "...";
 Tkx::update();
 &ipv6_off;
 $statusvar = $tmpstatusvar;
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
   copy($authfile,$ENV{'TEMP'} . "\\logo.jpg");
  }
  system("start https://cryptostorm.nu/cryptostorm_setup.exe");
  exit;
 }
}
if (defined($amsg)) {
 Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                       -message => "$amsg",
                                       -icon => "info", -title => "cryptostorm.is client");

}
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
 $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
 $TrayIcon  = new Win32::GUI::Icon("../res/world1.ico");
 $TrayWinHidden = Win32::GUI::Window->new(
                  -name => 'TrayWindow',
                  -text => 'TrayWindow',
                  -width => 20,
                  -height => 20,
                  -visible => 0,
                  );
 $TrayNotify = $TrayWinHidden->AddNotifyIcon(
                -name => "Open",
                -icon => $TrayIcon,
                -tip => "cryptostorm.is client",
                -balloon_icon => "info",
                -onRightClick => \&TrackTrayMenu,
                -onClick => \&showwin,
                -balloon => $balloon,
                -balloon_tip => $balloon_msg,
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
 $TrayNotify->Win32::GUI::TrackPopupMenu($TrayMenu->{Options});
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
 if ($ecc_var =~ /(.*)/) {
  print CREDS "ecc=$1\n";
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
 if ($ipv6_var =~ /(on|off)/) {
  print CREDS "noipv6=$1\n";
 }
 if ($port_var =~ /([0-9]+)/) {
  print CREDS "port=$1\n";
 }
 if ($randomize_it =~ /(on|off)/) {
  print CREDS "randomport=$1\n";
 }
 if ($lang =~ /(.*)/) {
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
 close(CREDS);
}

sub check_bit {
 if (uc($ENV{PROCESSOR_ARCHITECTURE}) eq "AMD64" || uc($ENV{PROCESSOR_ARCHITEW6432}) eq "AMD64") {
  $tapexe = "tap64.exe";
  $vpnexe = "csvpn.exe";
  $osslexe = "ossl.exe";
  $dnscexe = "dnscrypt-proxy.exe";
  $bit = "64";
 } 
 else {
  $tapexe = "tap32.exe";
  $vpnexe = "32\\csvpn32.exe";
  $osslexe = "32\\ossl32.exe";
  $dnscexe = "32\\dnscrypt-proxy.exe";
  $bit = "32";
 }
}

sub longer {
 if (!$alreadylong) {
  $frame4->g_grid(-column => 0, -row => 3, -sticky => "nswe");
  $logbox->g_grid(-column => 0, -row => 4, -sticky => "nwes");
  $scroll->g_grid(-column => 1, -row => 4, -sticky => "ns");
  $h = $_[0];
  if ($h == 450) {
   $h -= 36;
  }
  $width  = Tkx::winfo('reqwidth',  $mw);
  $height = Tkx::winfo('reqheight', $mw);
  $x = int((Tkx::winfo('screenwidth',  $mw) / 2) - ($width / 2));
  $y = int((Tkx::winfo('screenheight', $mw) / 2) - ($h / 2));
  $mw->g_wm_geometry($width . "x" . $h . "+" . $x . "+" . $y);
  Tkx::update();
 }
}

sub step_pbar {
 &blue_derp unless $statusvar eq $L->{$lang}{TXT_CONNECTED};
 Tkx::update();
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
 Win32::Process::KillProcess($pid, 0) if defined $pid;
 $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
 undef $TrayWinHidden if defined $TrayWinHidden;
 alarm 0;
 select(undef,undef,undef,0.05);
 &connectt;
}

sub connectt {
 $logbox->delete("1.0","end") if defined $logbox;
 $SIG{ALRM} = sub { &recon($L->{$lang}{TXT_CONNECT_TIMEOUT});return; };
 alarm $timeout_var;
 if (!$token) {
  $worldimage->configure(-image => "mainicon");
  &do_error($L->{$lang}{ERR_NO_TOKEN});
  alarm 0;
  return;
 }
 if ($disp_server ne $L->{$lang}{TXT_DEFAULT_SERVER}) {
  my @actual_server = grep(/$disp_server/,@servers);
  $server = $actual_server[0];
  $server = "" unless defined($actual_server[0]);
  $server =~ s/.*://;
 }
 if (!$server) {
  $server = $disp_server;
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
  &do_error($L->{$lang}{ERR_INVALID_TOKEN1} . "\n" . $L->{$lang}{ERR_INVALID_TOKEN2});
  alarm 0;
  return;
 }
 if ($server =~ /^obfs/) {
  $statusvar = $L->{$lang}{TXT_STARTING_OBFS} . "...";
  Tkx::update();
  &start_obfsproxy;
 }
 step_pbar();
 if (($autocon_var eq "on") && ($saveoption eq "off") || (!$saveoption)) {
  $autocon_var = "off";
 }
 $statusvar = $L->{$lang}{TXT_CHECKING_BIT} . "...";
 &step_pbar(); 
 Tkx::update();
 &blue_derp;
 $statusvar = $L->{$lang}{TXT_CHECKING_TAP} . "...";
 &step_pbar();
 &check_tapi();
 my $stoopid;
 for ($stoopid=0;$stoopid<=10;$stoopid++) {
  longer(25*$stoopid+200);
 }
 $alreadylong = 1;
 Tkx::update();
 &step_pbar();
 $statusvar = $L->{$lang}{TXT_LOGGING_IN} . "...";
 Tkx::update();
 $stop = 0;
 chdir("..\\user");
 open(TMP,">$hashfile") || &do_error($L->{$lang}{ERR_CANT_WRITE_TO} . " .\\user\\");
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
 $logbox->configure(-state => "normal");
 if ($disp_server eq "Cryptofree") {
  $whichvpn = "free";
 }
 else {
  $whichvpn = "paid";
 }
 if ($nostun_var eq "on") {
  $statusvar = $L->{$lang}{TXT_ENABLING_STUN_LEAK} . "...";
  Tkx::update();
  system 1, "nostun.bat";
  $statusvar = $L->{$lang}{TXT_LOGGING_IN} . "...";
  Tkx::update();
 }
 if ($ipv6_var eq "on") {
  $statusvar = $L->{$lang}{TXT_DISABLING_IPV6} . "...";
  Tkx::update();
  &ipv6_off;
  $statusvar = $L->{$lang}{TXT_LOGGING_IN} . "...";
  Tkx::update();
 }
 if ($randomize_it eq "on") {
  $port_var = int(rand(65533) + 1);
 }
 if ($ecc_var eq "on") {
  $port_var = 5060;
 }
 if ($server =~ /voodoo/) {
  $port_var = 443;
 }
 undef @tmparray;
 undef $tmpline;
 undef $vpn_args;
 if ($whichvpn eq "free") {
  if ($proto_var eq "UDP") {
   if ($port_var eq "5060") {
    $vpn_args = "--client --dev tun --proto udp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry 16 --float --explicit-exit-notify 3 --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
   }
   else {
    $vpn_args = "--client --dev tun --proto udp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
   }
  }
  if ($proto_var eq "TCP") {
   if ($port_var eq "5060") {
    $vpn_args = "--client --dev tun --proto tcp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry 16 --float --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
   }
   else {
    $vpn_args = "--client --dev tun --proto tcp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
   }
  }
 }
 if ($whichvpn eq "paid") {
  if ($proto_var eq "UDP") {
   if ($server eq $L->{$lang}{TXT_DEFAULT_SERVER}) {
    if ($port_var eq "5060") {
     $vpn_args = "--client --dev tun --proto udp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry 16 --float --explicit-exit-notify 3 --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
    }
    else {
     $vpn_args = "--client --dev tun --proto udp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
    }
   }
   else {
	my @tmparray = grep(/$server/,@servers);
	my $tmpline = $tmparray[0];
	if ($tmpline =~ /^obfsproxy/) { 
	 $tmpline =~ s/.*://;	
	 $tmpline =~ s/\.cstorm\.pw//;
	 $vpn_args = "--client --dev tun --proto tcp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2 --socks-proxy-retry --socks-proxy 127.0.0.1 10194";
	}
	else {
	 $tmpline =~ s/.*://;
	 $tmpline =~ s/\.cstorm\.pw//;
	 if ($port_var eq "5060") {
	  $vpn_args = "--client --dev tun --proto udp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry 16 --float --explicit-exit-notify 3 --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
	 }
	 else {
	  $vpn_args = "--client --dev tun --proto udp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	 }
	}
   }
  }
  if ($proto_var eq "TCP") {
   if ($server eq $L->{$lang}{TXT_DEFAULT_SERVER}) {
	if ($port_var eq "5060") {
	 $vpn_args = "--client --dev tun --proto tcp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry 16 --float --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
	}
	else {
     $vpn_args = "--client --dev tun --proto tcp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	}
   }
   else {
	my @tmparray = grep(/$server/,@servers);
	my $tmpline = $tmparray[0];
	if ($tmpline =~ /^obfsproxy/) { 
	 $tmpline =~ s/.*://;
	 $tmpline =~ s/\.cstorm\.pw//;
	 $vpn_args = "--client --dev tun --proto tcp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2 --socks-proxy-retry --socks-proxy 127.0.0.1 10194";	 
	}
	else {
 	 $tmpline =~ s/.*://;
	 $tmpline =~ s/\.cstorm\.pw//;
	 if ($port_var eq "5060") {
	  $vpn_args = "--client --dev tun --proto tcp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry 16 --float --remote-cert-tls server --compress lz4 --down-pre --verb 4 --mute 3 --auth SHA512 --auth-nocache --auth-user-pass ..\\user\\client.dat --cipher AES-256-GCM --tls-version-min 1.2 --tls-version-max 1.2 --tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384 --tls-client --ca ..\\user\\ca-ec.crt --tls-crypt ..\\user\\tc.key";
     }
	 else {
	  $vpn_args = "--client --dev tun --proto tcp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --float --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass ..\\user\\client.dat --ca ..\\user\\ca2.crt --remote-cert-tls server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	 }
	}
   }
  }
 }
 my $chosen_ip;
 my $chosen_node = $vpn_args;
 if ($server eq $L->{$lang}{TXT_DEFAULT_SERVER}) {
  $chosen_node = "windows-balancer.cstorm.pw";
 }
 $chosen_node =~ s/.* ([a-zA-Z0-9\-]+\.cstorm.pw) .*/$1/;
 $statusvar = $L->{$lang}{TXT_RESOLVING} . " $chosen_node...";
 Tkx::update();
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
  @resolved_ips = qw();
  &recon($L->{$lang}{TXT_DNS_UPDATED} . "\n");
  return;
 }
 if (($dnsret =~ /[0-9]+/) || ($#resolved_ips == -1)) {
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  $pbarval = 0;
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $options->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  $worldimage->configure(-image => "mainicon");
  alarm 0;
  @resolved_ips = qw();
  return;
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
 $manport = get_next_free_local_port(5000);
 $manpass = &genpass; 
 open(TMP,"$vpncfgfile");
 while (<TMP>) {
  if (/^remote/) {
   $vpn_args =~ s/\-\-remote [a-zA-Z0-9\-\.]+ [0-9]+//g;
  }
 }
 close(TMP);
 if ($dnsleak_var eq "on") {
  $vpn_args .= " --block-outside-dns ";
 }
 if ($dnsleak_var eq "off") {
  $vpn_args .= " --pull-filter ignore block-outside-dns ";
 }
 if ($ts_var eq "on") {
  $vpn_args .= " --dhcp-option DNS 10.31.33.7 ";
 }
 $statusvar = $L->{$lang}{TXT_CONNECTING} . "...";
 Tkx::update();
 $pid = open $VPNfh, "echo $manpass|..\\bin\\$vpnexe $vpn_args --config $vpncfgfile --management 127.0.0.1 $manport stdin|";
 step_pbar();
 Tkx::update(); 
 $thread = threads->new( \&read_out, $VPNfh );
 $thread->detach();
 @msgs = ('cryptostorm',
          'PUSH: Received control message',
          'TAP-WIN32 device .* opened',
          'Route addition via IPAPI succeeded',
          'TEST ROUTES:',
          'TLS: Initial packet from');
 &logbox_loop; 
 alarm 0;
}

sub start_obfsproxy {
 my $pi = Win32::Process::Info->new;
 my @info = $pi->GetProcInfo();	
 foreach(@info) {
  if($_->{Name} =~ /^obfsproxy.exe$/) {
   Win32::Process::KillProcess ($_->{ProcessId}, 0);
  }
 }
 system 1, "..\\bin\\obfsproxy --log-file=obfsproxy.log --log-min-severity=info obfs3 socks 127.0.0.1:10194";
}

sub logbox_loop {
 while (!$idle) {
  select(undef,undef,undef,0.01);
  &watch_logbox;
 }
}

sub watch_logbox {
 Tkx::update() unless $idle;
 select(undef,undef,undef,0.01);
 if (defined $buffer and length $buffer ) {
  $line   = $buffer;
  $buffer = '';
  $logbox->insert('end', $line );
  $logbox->see('end');
  Tkx::update() unless $idle;
  for (@msgs) {
   if ($line =~ /$_/) {
    step_pbar();
   }
  }
  if ($line =~ /AUTH: Received control message: AUTH_FAILED/) {
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
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   alarm 0;
  }
  if ($line =~ /Cannot resolve host address: (.*)/) {
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
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   alarm 0;
  }
  if ($line =~ /Initialization Sequence Completed/) {
   if ($line =~ /Initialization Sequence Completed With Errors/) {
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
	Win32::Process::KillProcess($pid, 0) if defined $pid;
	alarm 0;
   }
   else {
    step_pbar();
	if ($saveoption eq "on") {
     &savelogin;
    }
    $worldimage->configure(-image => "g3"); 
    $logbox->insert_end($L->{$lang}{TXT_CONNECTED} . "\n", "goodline");
    $logbox->see('end');
	$statusvar = $L->{$lang}{TXT_CONNECTED};
	Tkx::update();
    $balloon_msg = $L->{$lang}{TXT_CONNECTED_BALLOON};
    $cancel->configure(-text => $L->{$lang}{TXT_DISCONNECT});	
	alarm 0;
	if ($dnscrypt_var eq "on") {
	 &dnscrypt(0);
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
         copy($authfile,$ENV{'TEMP'} . "\\logo.jpg");
        }       
		$statusvar = $L->{$lang}{TXT_DOWNLOADING_LATEST} . "...";
	    Tkx::update();		
        &grabnverify("bin/cryptostorm_setup.exe");
		copy("..\\bin\\tmp\\cryptostorm_setup.exe","..\\bin\\");
		unlink "..\\bin\\tmp\\cryptostorm_setup.exe" if (-e "..\\bin\\tmp\\cryptostorm_setup.exe");
		unlink "..\\bin\\tmp\\cryptostorm_setup.exe.hash" if (-e "..\\bin\\tmp\\cryptostorm_setup.exe.hash");
	    rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
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
	if ((!$replaceossl) && (!$replaceovpn) && (!$doupgrade)) {
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
 	 Tkx::update();
     &hidewin;
	}
   }
  }
 }
}

sub read_out {
 my ($VPNfh) = @_; 
 while ( defined( my $line = <$VPNfh> ) ) { 
  $buffer .= $line;
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
  if (($dnscrypt_var eq "on") && ($idunno eq "yes")) {
   $statusvar = $L->{$lang}{TXT_SET_DNS_DNSCRYPT} . "...";
   Tkx::update();
   &dnscrypt(0);
  }
  @resolved_ips = qw();
  Tkx::update();
  $cancel->configure(-state => "disabled");
  &kill_it;
  if ($nostun_var eq "on") {
   $statusvar = $L->{$lang}{TXT_DISABLING_STUN_LEAK} . "...";
   Tkx::update();
   my $stunpid = system 1, "netsh advfirewall firewall del rule name=\"No STUN leak for j00!\"";
   if (defined($stunpid)) {
    Tkx::update();
    while (kill(0,$stunpid) == 1) {
	 Tkx::update();
	}
   }
   Tkx::update();
  }
  if ($ipv6_var eq "on") {
   $statusvar = $L->{$lang}{TXT_ENABLING_IPV6} . "...";
   Tkx::update();
   &ipv6_on;
   Tkx::update();
  }  
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_EXIT}) {
   if ($dnscrypt_var eq "on") {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE} . "...";
    Tkx::update();
	&dnscrypt(0);
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
	  Tkx::update();
     }
    }
   }
   my $pi = Win32::Process::Info->new;
   my @info = $pi->GetProcInfo();
   foreach(@info) {
    if($_->{Name} =~ /^dnscrypt-proxy.exe$/) {
     Win32::Process::KillProcess ($_->{ProcessId}, 0);
    }
    if($_->{Name} =~ /^obfsproxy.exe$/) {
     Win32::Process::KillProcess ($_->{ProcessId}, 0);
    }
	if($_->{Name} =~ /^$vpnexe$/) {
     Win32::Process::KillProcess ($_->{ProcessId}, 0);
    }
   }
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   if ($doupgrade) {    
	my $ParentPID;
	$ParentPID = $$;
	my $ChildProc;	
    my $CWD = "..\\bin";
	my $CMD = "cryptostorm_setup.exe";		
	Win32::Process::Create($ChildProc, "$CWD\\$CMD", "$CMD", 0, DETACHED_PROCESS, "..\\bin") or &do_error("Couldn't run $CWD\\$CMD: $!");	
   }
   $stop = 1;
   $done = 1;
   $o_done3 = 1;
   if (-e "..\\user\\mydns.txt") {
    unlink("..\\user\\mydns.txt");
   }
   if (defined($dnsfix1)) {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE_WAIT} . "...";
    Tkx::update();
    while (kill(0,$dnsfix1) == 1) {
     Tkx::update();
     select(undef,undef,undef,0.01);
    }
   }
   if (defined($dnsfix2)) {
    $statusvar = $L->{$lang}{TXT_DNS_RESTORE_WAIT} . "...";
    Tkx::update();
    while (kill(0,$dnsfix2) == 1) {
     Tkx::update();
     select(undef,undef,undef,0.01);
    }
   }
   $o_thread3->kill('KILL') unless !defined $o_thread3;
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   Win32::Process::KillProcess($masterpid, 0) if defined $masterpid;
   $mw->g_destroy() if defined $mw;
   exit(0);
  }
  Tkx::update();
  if ($cancel->cget(-text) eq $L->{$lang}{TXT_DISCONNECT}) {
   Tkx::update();
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
   $logbox->delete("end - 1 line","end");
   $logbox->delete("end - 1 line","end");
   $logbox->insert_end("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
   $logbox->insert_end($L->{$lang}{TXT_DISCONNECTED} . "\n", "badline");
   $logbox->see('end');    
   Win32::Process::KillProcess($pid, 0) if defined $pid;   
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   $cancel->configure(-state => "normal");
   my $pi = Win32::Process::Info->new;
   my @info = $pi->GetProcInfo();
   foreach(@info) {
    if($_->{Name} =~ /^obfsproxy.exe$/) {
     Win32::Process::KillProcess ($_->{ProcessId}, 0);
    }
   }
   Tkx::update();
   if ($replaceossl) {
    $statusvar = $L->{$lang}{TXT_UPGRADE_OSSL} . "...";
	Tkx::update();
	sleep 1;
    unlink("..\\bin\\$osslexe");
    unlink("..\\bin\\libeay32.dll");
    unlink("..\\bin\\ssleay32.dll");
	foreach (glob "..\\bin\\tmp\\*.*") {
	 copy($_,"..\\bin\\");
	}
	$replaceossl = 0;
    $statusvar = $L->{$lang}{TXT_DONE};
    Tkx::update();
	$verstuff = `..\\bin\\$vpnexe --version 2>&1`;
    if ($verstuff =~ /OpenVPN ([0-9\.]+)/) {
     $ovpnver = $1;
    }
	$verstuff = `..\\bin\\$osslexe version 2>&1`;
    if ($verstuff =~ /OpenSSL ([0-9\.a-z]+)/) {
     $osslver = $1;
    }
	foreach (glob "..\\bin\\tmp\\*.*") {
	 unlink($_);
	}
	rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
   }
   if ($replaceovpn) {
    $statusvar = $L->{$lang}{TXT_UPGRADE_OVPN} . "...";
	Tkx::update();	
    my $pi = Win32::Process::Info->new;
    my @info = $pi->GetProcInfo();    
    foreach(@info) {
     if($_->{Name} =~ /^$vpnexe$/) {
	  &kill_it;
      Win32::Process::KillProcess ($_->{ProcessId}, 0);
     }	 
	}
	sleep 2;
    unlink("..\\bin\\$vpnexe");	
	unlink("..\\bin\\$osslexe");
	unlink("..\\bin\\libeay32.dll");
	unlink("..\\bin\\ssleay32.dll");
	unlink("..\\bin\\liblzo2-2.dll");
	unlink("..\\bin\\libpkcs11-helper-1.dll");
	unlink("..\\bin\\msvcr120.dll");
	foreach (glob "..\\bin\\tmp\\*.*") {
	 copy($_,"..\\bin\\");
	}
	$replaceovpn = 0;
    $statusvar = $L->{$lang}{TXT_DONE};
    Tkx::update();
	$verstuff = `..\\bin\\$vpnexe --version 2>&1`;
    if ($verstuff =~ /OpenVPN ([0-9\.]+)/) {
     $ovpnver = $1;
    }
	$verstuff = `..\\bin\\$osslexe version 2>&1`;
    if ($verstuff =~ /OpenSSL ([0-9\.a-z]+)/) {
     $osslver = $1;
    }
	foreach (glob "..\\bin\\tmp\\*.*") {
	 unlink($_);
	}
	rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;	
   }
   $statusvar = $L->{$lang}{TXT_DISCONNECTED};
   Tkx::update();
  }
 }
}

sub check_tapi {
 my @cmd = `..\\bin\\$tapexe hwids tap0901 2>&1`;
 if ($cmd[$#cmd] =~ /([0-9]+) matching device\(s\) found./) {
  if ($1 == 1) {
   $statusvar = $L->{$lang}{TXT_TAP_FOUND};
   Tkx::update();
   return;
  }
  else {
   $statusvar = $L->{$lang}{TXT_TAP_MULTI};
   Tkx::update();
   @cmd = `..\\bin\\$tapexe remove tap0901 2>&1`;
   Tkx::update();
   &check_tapi(1);
  }
 }
 if ($cmd[$#cmd] =~ /tap[32|64] failed/) {
  $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
  $connect->configure(-state => "normal");
  $options->configure(-state => "normal");
  $update->configure(-state => "normal");
  &do_error($L->{$lang}{ERR_TAP});
  $statusvar = $L->{$lang}{TXT_NOT_CONNECTED};
  Tkx::update();
  return;
 }
 if ($cmd[$#cmd] =~ /No matching devices found./) {
  $statusvar = $L->{$lang}{TXT_TAP_INSTALLING} . "...";
  Tkx::update();
  @cmd = `..\\bin\\$tapexe install OemVista.inf tap0901 2>&1`;
  if ($cmd[$#cmd] =~ /Drivers installed successfully./) {
   $statusvar = $L->{$lang}{TXT_TAP_INSTALLED};
   Tkx::update();
   &check_tapi(1);
  }
  else {
   $cancel->configure(-text => $L->{$lang}{TXT_EXIT});
   $connect->configure(-state => "normal");
   $options->configure(-state => "normal");
   $update->configure(-state => "normal");
   &do_error($L->{$lang}{ERR_TAP} . ": $cmd[$#cmd]");
   return;
  }
 }
}

sub uniq {
 my %seen; 
 grep !$seen{$_}++, @_;
}
 
sub update_node_list {
 local $SIG{KILL} = sub { threads->exit };
 my ($ua,$response);
 my @headers = ('User-Agent' => "Cryptostorm client");
 $ua = LWP::UserAgent->new(agent => "Cryptostorm client");
 $ua->timeout(10);
 if (($statusvar eq $L->{$lang}{TXT_CONNECTED}) && ($widget_update_var eq $L->{$lang}{TXT_UPDATE_WHEN1})) {
  $response = $ua->get("http://10.31.33.7/nodelist.txt", @headers);
 }
 else {
  $response = $ua->get("https://cryptostorm.nu/nodelist3.txt", @headers);
 }
 $status = $response->content_type;
 if ($response->is_success) {
  while (defined($response->content and length $response->content)) {
   $nodebuf .= $response->content;
   last if $done;
  }
  $nodebuf = '';
 }
 else {
  return;
 }
}

sub do_options {
 my $width  = Tkx::winfo('reqwidth',  $cw);
 my $height = Tkx::winfo('reqheight', $cw);
 $height = $height - 20;
 $width += 200;
 my $x = int((Tkx::winfo('screenwidth',  $cw)  - $width  ) / 2);
 my $y = int((Tkx::winfo('screenheight', $cw)  - $height ) / 2);
 if ($saveoption eq "off") {
  $autocon_var = "off";
 } 
 $mw->g_wm_deiconify();
 $mw->g_wm_withdraw();
 $cw->g_wm_geometry("+$x+$y");
 $cw->g_raise();
 $cw->g_wm_deiconify();
 $cw->g_focus();  
 my %stupidstrictrefs;
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
}

sub backtomain {
 my $tmpvar = $statusvar;
 $port_var =~ s/[^0-9]//g;
 if ($port_var =~ /^([0-9]+)$/) {
  if (($1 < 1) || ($1 > 65534)) {
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
 if ($dnscrypt_var eq "on") {  
  &dnscrypt(1);
 }
 $mw->g_focus(); 
 Tkx::update();
 if ($dnscrypt_var eq "off") {
  &dnscrypt(0);  
  Tkx::update();
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
 if ($nostun_var eq "off") {
   system 1, "netsh advfirewall firewall del rule name=\"No STUN leak for j00!\"";
 } 
 Tkx::update();
 if ($ipv6_var eq "off") {
  &ipv6_on;
 } 
 Tkx::update();
 &savelogin; 
 Tkx::update();
 if ($killswitch_var eq "off") {
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
}

sub check_version {
 $o_done3 = 0;
 $o_thread3->kill('KILL') unless !defined($o_thread3);
 my $arg;
 $arg = $_[0] unless !defined $_[0];
 if (defined($arg)) {
  $o_thread3 = threads->create( \&check_version_thread($arg));
 }
 else { 
  $o_thread3 = threads->create( \&check_version_thread);
 }
 $o_thread3->detach();
 while (!$o_done3) {
  Tkx::update();
  select(undef,undef,undef,0.001);
  if (defined($o_version_buf)) {
   $latest = $o_version_buf;
   $o_done3 = 1;
   if ($o_version_buf eq "nope") {
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
 if (defined($oncs)) {
  $response = $ua->get("http://10.31.33.7/latest.txt", @headers);
 }
 else {
  $response = $ua->get("https://cryptostorm.nu/latest.txt", @headers);
 }
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
  if (($response->content() =~ /LATEST_OVPN:([0-9\.]+)/) && ($bit eq "64")) {
   my $newestver = $1;
   chomp($newestver);
   if ($newestver ne $ovpnver) {
	$upgradeornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno", 
                                         -message => $L->{$lang}{QUESTION_UPGRADE_OVPN1} . "\n" .
										             $L->{$lang}{QUESTION_UPGRADE_OVPN2},
                                         -icon => "question", -title => "cryptostorm.is client");
    if ($upgradeornot eq "yes") {
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenVPN...";
	 Tkx::update();
	 mkdir("..\\bin\\tmp") if (!-d "..\\bin\\tmp");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libeay32.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/libeay32.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " ssleay32.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/libcrypto-1_1-x64.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libcrypto-1_1-x64.dll...\n";
	 Tkx::update();
	 &grabnverify("bin/libssl-1_1-x64.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libssl-1_1-x64.dll...\n";
	 Tkx::update();
	 &grabnverify("bin/ssleay32.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " liblzo2-2.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/liblzo2-2.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libpkcs11-helper-1.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/libpkcs11-helper-1.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " msvcr120.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/msvcr120.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenSSL...";
	 Tkx::update();	 
	 &grabnverify("bin/$osslexe");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenVPN...";
	 Tkx::update();	 
	 &grabnverify("bin/$vpnexe");	 
	 $statusvar = $L->{$lang}{TXT_OVPN_DONE};
	 Tkx::update();	 
	 if (-e "..\\bin\\tmp\\$vpnexe") {
	  Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                      -message => $L->{$lang}{TXT_OVPN_NOW1} . "\n" .
									              $L->{$lang}{TXT_OVPN_NOW2},
                                      -icon => "info", -title => "cryptostorm.is client");
      $replaceovpn = 1;
	 }
	 else {	  
	  $statusvar = $L->{$lang}{ERR_OVPN_DOWNLOAD};
	  Tkx::update();
	 }	 
	 if (!$replaceovpn) {
	  unlink "..\\bin\\tmp\\$vpnexe";
	  unlink "..\\bin\\tmp\\$vpnexe.hash";
	  rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
	 }
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
	 Tkx::update();
    }
   }
  }
  if (($response->content() =~ /LATEST_OVP32:([0-9\.]+)/) && ($bit eq "32")) {
   my $newestver = $1;
   chomp($newestver);
   if ($newestver ne $ovpnver) {
	$upgradeornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno", 
                                         -message => $L->{$lang}{QUESTION_UPGRADE_OVPN1} . "\n" .
										             $L->{$lang}{QUESTION_UPGRADE_OVPN2},
                                         -icon => "question", -title => "cryptostorm.is client");
    if ($upgradeornot eq "yes") {
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenVPN...";
	 Tkx::update();
	 mkdir("..\\bin\\tmp") if (!-d "..\\bin\\tmp");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libeay32.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/libeay32.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " ssleay32.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/ssleay32.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " liblzo2-2.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/liblzo2-2.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libpkcs11-helper-1.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/libpkcs11-helper-1.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " msvcr120.dll...";
	 Tkx::update();	 
	 &grabnverify("bin/msvcr120.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenSSL...";
	 Tkx::update();	 
	 &grabnverify("bin/$osslexe");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " OpenVPN...";
	 Tkx::update();	 
	 &grabnverify("bin/$vpnexe");	 
	 $statusvar = $L->{$lang}{TXT_OVPN_DONE};
	 Tkx::update();	 
	 if (-e "..\\bin\\tmp\\$vpnexe") {
	  Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                      -message => $L->{$lang}{TXT_OVPN_NOW1} . "\n" .
									              $L->{$lang}{TXT_OVPN_NOW2},
                                      -icon => "info", -title => "cryptostorm.is client");
      $replaceovpn = 1;
	 }
	 else {	  
	  $statusvar = $L->{$lang}{ERR_OVPN_DOWNLOAD};
	  Tkx::update();
	 }	 
	 if (!$replaceovpn) {
	  unlink "..\\bin\\tmp\\$vpnexe";
	  unlink "..\\bin\\tmp\\$vpnexe.hash";
	  rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
	 }
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
	 Tkx::update();
    }
   }
  }
  if ($response->content() =~ /LATEST_OSSL:([0-9\.a-z]+)/) {
   my $newestver = $1;
   if ($newestver ne $osslver) {
	$upgradeornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno", 
                                      -message => $L->{$lang}{QUESTION_UPGRADE_OSSL1} . "\n" .
									              $L->{$lang}{QUESTION_UPGRADE_OVPN2},
                                      -icon => "question", -title => "cryptostorm.is client");
    if ($upgradeornot eq "yes") {
	 mkdir("..\\bin\\tmp");
     $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " $osslexe...";
	 Tkx::update();
     &grabnverify("bin/$osslexe");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " libeay32.dll...";
	 Tkx::update();
     &grabnverify("bin/libeay32.dll");
	 $statusvar = $L->{$lang}{TXT_DOWNLOADING} . " ssleay32.dll...";
	 Tkx::update();
     &grabnverify("bin/ssleay32.dll");	 
	 if (-e "..\\bin\\tmp\\ssleay32.dll") {
	  Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                      -message => $L->{$lang}{TXT_OVPN_NOW1} . "\n" .
									              $L->{$lang}{TXT_OSSL_NOW2},
                                      -icon => "info", -title => "cryptostorm.is client");
      $replaceossl = 1;
	 }
	 else {
	  $statusvar = $L->{$lang}{ERR_OSSL_DOWNLOAD};
	  Tkx::update();
	 }
	 if (!$replaceossl) {
	  unlink "..\\bin\\tmp\\$vpnexe";
	  unlink "..\\bin\\tmp\\$vpnexe.hash";
	  unlink "..\\bin\\tmp\\libeay32.dll";
	  unlink "..\\bin\\tmp\\libeay32.dll.hash";
	  unlink "..\\bin\\tmp\\ssleay32.dll";
	  unlink "..\\bin\\tmp\\ssleay32.dll.hash";
	  rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
	 }
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
	 Tkx::update();
    }
   }
  }
  if ($response->content() =~ /LATEST_DNSC:([0-9a-f]+)/) {
   my $newestver = $1;
   my $md5 = Digest::MD5->new;
   my $digest = file_md5_hex("..\\bin\\dnscrypt-proxy.toml");
   if ($newestver ne $digest) {
	$upgradeornot = Tkx::tk___messageBox(-parent => $mw, -type => "yesno", 
                                      -message => $L->{$lang}{QUESTION_DNSCRYPT},
                                      -icon => "question", -title => "cryptostorm.is client");
    if ($upgradeornot eq "yes") {
	 mkdir("..\\bin\\tmp");
     $statusvar = $L->{$lang}{TXT_DOWNLOADING} . "  dnscrypt-proxy.toml...";
	 Tkx::update();
     &grabnverify("bin/dnscrypt-proxy.toml");
	 if ($statusvar =~ /Downloaded file verified correctly/) {
      copy("..\\bin\\tmp\\dnscrypt-proxy.toml","..\\bin\\") or &do_error($L->{$lang}{ERR_COPY} . " ..\\bin\\tmp\\dnscrypt-proxy.toml to ..\\bin\\");
	 }
     unlink "..\\bin\\tmp\\dnscrypt-proxy.toml";
	 unlink "..\\bin\\tmp\\dnscrypt-proxy.toml.hash";
	 rmdir("..\\bin\\tmp") unless &isEmpty("..\\bin\\tmp") > 0;
	 $statusvar = $L->{$lang}{TXT_CONNECTED};
	 Tkx::update();
    }
   }
  }
  if ((!$o_version_buf) && (!$amsg)) {
   $o_version_buf = "nope";
  }
 }
 else {
  $o_version_buf = "nope";
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
 if (!-d "..\\bin\\tmp") { mkdir "..\\bin\\tmp"; } 
 my $ua = LWP::UserAgent->new(  );
 my $url = "http://10.31.33.7/" . $file_to_grab;
 my $response = $ua->head($url);
 my $remote_headers = $response->headers;
 $total_size = $remote_headers->content_length;
 $ua = LWP::UserAgent->new;
 binmode STDOUT,':raw';
 open $fh, '>', "..\\bin\\tmp\\$file_to_grab" or &do_error("\n" . $L->{$lang}{ERR_CREATE} . " ..\\bin\\tmp\\$file_to_grab: $!\n");
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
 open $fh, '>', "..\\bin\\tmp\\$file_to_grab.hash" or &do_error("\n" . $L->{$lang}{ERR_CREATE} . " ..\\bin\\tmp\\$file_to_grab: $!\n");
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
 my $yayornay = `..\\bin\\$osslexe dgst -sha512 -verify ..\\bin\\widget.pub -signature ..\\bin\\tmp\\$file_to_grab.hash ..\\bin\\tmp\\$file_to_grab 2>&1`;
 if ($yayornay =~ /Verified OK/) {
  $statusvar = $L->{$lang}{TXT_DOWNLOAD_VERIFIED}; 
  Tkx::update();  
 }
 else {
  $statusvar = $L->{$lang}{ERR_VERIFY} . " - $file_to_grab";
  Tkx::update();  
  &do_error($L->{$lang}{ERR_VERIFY} . " - $file_to_grab: $yayornay\n..\\bin\\$osslexe dgst -sha512 -verify ..\\bin\\widget.pub -signature ..\\bin\\tmp\\$file_to_grab.hash ..\\bin\\tmp\\$file_to_grab");
  unlink("..\\bin\\tmp\\$file_to_grab");
 }
 $cancel->configure(-state => "normal");
}

sub dnscrypt {
 if ($_[0] == 0) {  
  if (`..\\bin\\$dnscexe -service stop 2>&1` =~ /(Service stopped|been started)/) {
   if (`..\\bin\\$dnscexe -service uninstall 2>&1` =~ /(Service uninstalled|not installed)/) {
    &restore_dns;
    return 1;
   }
  }
 }
 if ($_[0] == 1) {
  my @isinuse = `netstat -anob`;
  my $nodns = "0";
  my $dnsinc;
  for (@isinuse) {
   if (/127\.0\.0\.1:53\s.*LISTENING(.*)/) {
    my $pidness = $1;
    $pidness =~ s/\r|\n|\s//g;
    my $program = $isinuse[$dnsinc + 1];
    $program =~ s/\[//g;
    $program =~ s/\]//g;
    $program =~ s/\r|\n//g;
    $program =~ s/\s//g;
    if (($program !~ /dnscrypt-proxy/) && ($program !~ /^System$/)) {
     $nodns = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                   -message => $L->{$lang}{QUESTION_ANOTHER_DNSCRYPT1} . "\n" .
								               $L->{$lang}{QUESTION_ANOTHER_DNSCRYPT2} . "\n" .
											   $L->{$lang}{QUESTION_ANOTHER_DNSCRYPT3},
                                   -icon => "question", -title => "cryptostorm.is client");
     if ($nodns eq "yes") {
      Win32::Process::KillProcess ($pidness, 0);
     }
    }
   }
   $dnsinc++;
  }
  if (($nodns eq "0") || ($nodns eq "yes")) {   
   if (`..\\bin\\$dnscexe -service install 2>&1` =~ /(Installed as a service|service dnscrypt-proxy already)/) {
    if (`..\\bin\\$dnscexe -service start 2>&1` =~ /(Service started|already running)/) {
     &set_dns_to_dnscrypt; 	 
	 return 0;
    }
    else {
     return -1;
    }
   }
   else {
    return -1;
   }
  }
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
   $logbox->see('end');
   &kill_it;
   Win32::Process::KillProcess($pid, 0) if defined $pid;   
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   $cancel->configure(-state => "normal");
  }
 }
 if (($args[0] eq PBT_APMRESUMEAUTOMATIC) || ($args[0] eq PBT_APMRESUMECRITICAL)) {
  # resuming from suspend, so reconnect if client was connected before suspend
  if ($iwasconnected) {
   $worldimage->configure(-image => "mainicon");
   if ($dnscrypt_var eq "on") {
    &get_dnscrypt_sel;
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
  if (/^(.*):DHCP:(.*)$/) {   
   #system qq(netsh interface ip set dns "$1" dhcp);
   $dnsfix1 = system 1,qq(netsh interface ip set dns "$1" dhcp);
  }
  if (/^(.*):Static:(.*)$/) {
   if ($2 !~ /127\.0\.0\.1/) {    
    #system qq(netsh interface ip set dns "$1" static $2);
	$dnsfix2 = system 1,qq(netsh interface ip set dns "$1" static $2);
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

sub set_dns_to_dnscrypt { 
 my $current_interface;  
 my $ovpnadapter;
 my @ovpnadapt = `..\\bin\\$vpnexe --show-adapters`; 
 if ($ovpnadapt[1] =~ /^'(.*)' {/) {
  $ovpnadapter = $1;
 }
 foreach my $line (@output) {
  if ($line =~ /Configuration for interface "(.*)"/) {
   $current_interface = $1;
  }  
  if (($line =~ /DNS servers configured through (DHCP):\s+(.*)/) ||
      ($line =~ /(Static)ally Configured DNS Servers:\s+(.*)/)) {	  
   my $dnstype = $1;
   my $tmpy = $2;
   if (($tmpy !~ /127\.0\.0\.1/) && ($tmpy !~ /None/)) {
    if ($current_interface !~ /$ovpnadapter/) {
     system 1, qq(netsh interface ip set dns "$current_interface" static 127.0.0.1);
	}
   }
  }
 }
}

sub get_current_dns {
 if (-e "..\\user\\mydns.txt") {  
  return;
 }
 open(my $fh, '-|', 'netsh interface ipv4 show dnsserv') or &do_error("&get_current_dns: $!");
 my $current_interface;
 @output = <$fh>;
 close($fh);
 foreach my $line (@output) {
  if ($line =~ /Configuration for interface "(.*)"/) {
   $current_interface = $1;
  }
  if (($line =~ /DNS servers configured through (DHCP):\s+(.*)/) ||
      ($line =~ /(Static)ally Configured DNS Servers:\s+(.*)/)) {
   my $dnstype = $1;
   my $tmpy = $2;
   if ($tmpy !~ /None/) {
	push(@recover,"$current_interface:$dnstype:$tmpy\r\n");
   }
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

sub ipv6_off {
 system 1, '..\user\ipv6_off.bat';
}

sub ipv6_on {
 system 1, '..\user\ipv6_on.bat';
}

sub blue_derp {
 $worldimage->configure(-image => "mainicon"); 
 for (my $derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "b$derp"); 
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for (my $derp=6;$derp>=1;$derp--) {
  $worldimage->configure(-image => "b$derp"); 
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 $worldimage->configure(-image => "mainicon"); 
}

sub green_derp {
 $worldimage->configure(-image => "mainicon"); 
 for (my $derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "g$derp"); 
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for (my $derp=6;$derp>=1;$derp--) {
  $worldimage->configure(-image => "g$derp"); 
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 $worldimage->configure(-image => "mainicon"); 
}

sub red_derp {
 $worldimage->configure(-image => "mainicon"); 
 for (my $derp=1;$derp<=6;$derp++) {
  $worldimage->configure(-image => "r$derp"); 
  Tkx::update();
  select(undef,undef,undef,0.049);
 }
 for (my $derp=6;$derp>=1;$derp--) {
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
 my $iaddr = inet_aton('localhost');
 my $timeout = 5;
 my $freeport = 0;
 my $paddr = sockaddr_in($portnumber, $iaddr);
 socket(SOCKET, PF_INET, SOCK_STREAM, $proto);
 eval {
  local $SIG{ALRM} = sub { &do_error($L->{$lang}{TXT_TIMEOUT}); };
  alarm($timeout);
  connect(SOCKET, $paddr) || error();
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
  $tryport ++;
  &do_error($L->{$lang}{ERR_FREEPORT}) if $tryport > ($startport + 100);
 }
 return $freeport;
}

sub kill_it {
 $| = 1; 
 if (!$manport) { return -1; }
 my ($socket,$client_socket,$data);
 $socket = new IO::Socket::INET (
 PeerHost => '127.0.0.1',
 PeerPort => $manport,
 Proto => 'tcp', 
 ) or return; 
 print $socket "$manpass\r\n";
 while (<$socket>) {
  if (/INFO:OpenVPN Management Interface Version/) {
   print $socket "signal SIGTERM\r\n";   
   my @info = $pi->GetProcInfo();
   foreach(@info) {    
    if ($_->{Name} =~ /^$vpnexe$/) {
     Win32::Process::KillProcess ($_->{ProcessId}, 0);
    }
   }
  }
  if (/SUCCESS: signal SIGTERM thrown/) {
   print $socket "exit\r\n";   
   undef $manport;   
   return;   
  }
 }
 return;
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
 my @whitelist;
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
    push(@whitelist,"$_");
   }
  }
 }
 @addresses = uniq(@whitelist);
 for (@addresses) {
  Tkx::update();
  $vpn_ips .= "$_,";
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
 push(@addresses,"1.1.1.1");
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
 $rt = `netsh advfirewall firewall add rule name="cryptostorm" dir=out action=allow remoteip=$vpn_ips`;
 if ($rt =~ /Ok./) {
  $statusvar = "Kill switch - allow VPN IPs";
  Tkx::update();   
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

sub isoncs {
 if (!$manport) { return -1; }
 $| = 1;
 my ($socket,$client_socket,$data);
 $socket = new IO::Socket::INET (
 PeerHost => '127.0.0.1',
 PeerPort => $manport,
 Proto => 'tcp',
 Timeout => 1
 ) or return -1;
 print $socket "$manpass\r\n";
 while (<$socket>) {
  if (/INFO:OpenVPN Management Interface Version/) {
   print $socket "state\n";
   my $response = "";
   $socket->recv($response, 64);
   if ($response =~ /CONNECTED,SUCCESS/) {
    $socket->close();
    return 1;
   }
   else {
    return -1;
   }
  }
 }
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

sub dns_error {
 $_[0] =~ /(.*):(.*):(.*)/;
 my $chosen_node = $1;
 my $yerdns = $2;
 my $error = $3;
 my $msg;
 if ($error eq "timeout") {
  if ($yerdns eq "1.1.1.1") {
   $msg = $L->{$lang}{ERR_DNS_FINAL_NOTICE1} . "\n" .
          $L->{$lang}{ERR_DNS_FINAL_NOTICE2} . "\n" .
		  $L->{$lang}{ERR_DNS_FINAL_NOTICE3} . "\n\n";
   Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                   -message => $msg,
                                   -icon => "error", -title => "cryptostorm.is client");
   $logbox->delete("1.0","end");
   return "$yerdns:$chosen_node:$error";
  }
  $msg = $L->{$lang}{ERR_DNS_TIMEOUT1} . "\n" .
         $L->{$lang}{ERR_DNS_TIMEOUT2} . " $yerdns\n" .
		 $L->{$lang}{ERR_DNS_TIMEOUT3} . "\n\n";
 }
 else {
  $msg = $L->{$lang}{ERR_DNS_GENERIC1} . "\n" .
         $L->{$lang}{ERR_DNS_GENERIC2} . " $yerdns\n" .
		 $L->{$lang}{ERR_DNS_GENERIC3} . " $error\n\n";
 }
 $msg .= $L->{$lang}{QUESTION_DNSFIX} . "\n";
 if ($dnscrypt_var eq "off") {
  $msg .= $L->{$lang}{TXT_DNSFIX1};
 }
 if ($dnscrypt_var eq "on") {
  $msg .= $L->{$lang}{TXT_DNSFIX2};
 }
 my $msgbox = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                   -message => $msg,
                                   -icon => "error", -title => "cryptostorm.is client");
 if ($msgbox eq "yes") {
  if (-e "..\\user\\mydns.txt") {
   unlink("..\\user\\mydns.txt");
  }
  if ($dnscrypt_var eq "on") {
   my $current_interface;  
   my $ovpnadapter;
   my @ovpnadapt = `..\\bin\\$vpnexe --show-adapters`; 
   if ($ovpnadapt[1] =~ /^'(.*)' {/) {
    $ovpnadapter = $1;
   }
   foreach my $line (@output) {
    Tkx::update();
    if ($line =~ /Configuration for interface "(.*)"/) {
     $current_interface = $1;
    }  
    if (($line =~ /DNS servers configured through (DHCP):\s+(.*)/) ||
        ($line =~ /(Static)ally Configured DNS Servers:\s+(.*)/)) {	  
     my $dnstype = $1;
     my $tmpy = $2;
     if ($current_interface !~ /$ovpnadapter/) {
      system 1, qq(netsh interface ip set dns "$current_interface" static 1.1.1.1);
	  $cfdns = 1;
	 }
    }
   }
  }
  else {
   $dnscrypt_var = "on";
   &dnscrypt(1);
  }
  return "recon";
 }
 else {
  return "$yerdns:$chosen_node:$error";
 }
}

sub preresolve {
 my $chosen_node = $_[0];
 $chosen_node =~ s/cstorm\.pw.*/cstorm.pw/;
 my $resolver;
 my $query;
 if ($dnscrypt_var eq "on") {
  if ($cfdns) {
   $resolver = new Net::DNS::Resolver::MSWin32(nameservers => ["1.1.1.1"]);
   $cfdns=0;
  }
  else {
   $resolver = new Net::DNS::Resolver::MSWin32(nameservers => ["127.0.0.1"])
  }
 }
 else {
  $resolver = new Net::DNS::Resolver::MSWin32;
 }
 $resolver->tcp_timeout(7);
 $resolver->udp_timeout(7);
 my @yerdns = $resolver->nameservers();
 my $handle = $resolver->bgsend("127.0.0.1");
 while ($resolver->bgbusy($handle)) {
  Tkx::update();
 }
 my $packet = $resolver->bgread($handle);
 if (defined($packet)) {
  my $query = $resolver->search("$chosen_node");
  if ($query) {
   foreach my $rr ($query->answer) {
    Tkx::update();
    next unless $rr->type eq "A";
    push(@resolved_ips,$rr->address);
   }
  }
  else {
   return &dns_error("$chosen_node:" . $yerdns[0] . ":" . $resolver->errorstring);
  }
 }
 else {
  return &dns_error("$chosen_node:" . $yerdns[0] . ":timeout");
 }
}
