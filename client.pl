#!/usr/bin/perl #-d:Trace
#open(STDERR, ">&STDOUT") or warn "failed to dup STDOUT:$!";
if (-d "\\Program Files\\Cryptostorm Client\\bin") {
 chdir("\\Program Files\\Cryptostorm Client\\bin\\");
}
if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
 chdir("\\Program Files (x86)\\Cryptostorm Client\\bin\\");
}
our $VERSION = "1.22";
use strict;
use warnings;
use Tkx;
#$Tkx::TRACE=64;
use Tkx::SplashScreen;
use Win32::GUI();
use Digest::SHA qw(sha512_hex);
use HTTP::Request::Common qw(GET POST);
use LWP::UserAgent;
use IO::Socket;
use Time::HiRes qw( gettimeofday tv_interval);
use Win32::Process;
use Win32::Process::Info;;
use threads;
use threads::shared;
use Win32::TieRegistry(Delimiter => "/");
use Cwd 'abs_path';
our $self = abs_path($0);
$self =~ s/\//\\/g;
my $buffer : shared;
my $stop : shared;
my $done : shared;
my $nodebuf : shared;
my $status : shared;
my $pid : shared;
my $o_nodelist_buf : shared;
my $o_version_buf : shared;
my $o_done1 : shared;
my $o_done3 : shared;
my $latest : shared;
my $amsg : shared;
my @latency_tmparray : shared;
my @latency_array : shared;
my $authfile = "..\\user\\logo.jpg";
my $hashfile = "..\\user\\client.dat";
my $vpncfgfile = "..\\user\\vpn.conf";
my $cacertfile = "..\\user\\ca.crt";
my $cclientfile = "..\\user\\client.crt";
my $clientkey  = "..\\user\\client.key";
my $nodelistfile = "..\\user\\nodelist.txt";
my $c = 0;
my $alreadylong = 0;
my ( $line, $VPNfh, $thread, $updatethread, $bit, $tapexe, $vpnexe, $h);
my ($frame1, $frame2, $frame3, $frame4, $saveoption, $password, $userlbl, $passlbl, $connect, $cancel, $pass, 
    $save, $progress, $pbar, $pbarval, $statuslbl, $statusvar, $token_textbox, $token, $worldimage, $logbox, 
	$scroll, $errorimage, $server_textbox, $server, $disp_server, $tripimage, $server_host, $update, $menu, $send, $options);
my ($autocon, $autocon_var, $autorun, $autorun_var, $o_frame1, $o_worldimage, $back, $o_tabs, $o_innerframe1, 
    $o_innerframe2, $o_button1, $o_button2, $o_nodelist);
my ($o_thread1, $o_thread3);
my $hiddenornot = "Hide";
my $custom = "";
my ($TrayIcon,$TrayWinHidden,$TrayNotify,$TrayMenu);
my $showtiponce = 0;
my ($x, $y, $width, $height);
my (@servers, @disp_servers);
my $balloon_msg;
my $idle = 0;
my $update_var;
our @msgs;
$disp_server = "Default node";
if (-e "$authfile") {
 open(CREDS,"$authfile");
 while (<CREDS>) {
  if ((/^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
      (/^([a-f0-9]{128})$/)) {
   $token = $1;
  }
  if (/^node=(.*)$/) {
   $disp_server = $1;
  }
  if (/^autocon=(.*)$/) {
   $autocon_var = $1;
  }
  if (/^autorun=(.*)$/) {
   $autorun_var = $1;
  }
  if (/^checkforupdate=(.*)$/) {
   $update_var = $1;
  }
 } 
}
Tkx::package_require('img::png');
Tkx::package_require("style");
Tkx::package_require('tooltip');
Tkx::style__use("as", -priority => 70);
Tkx::font_create("logo_font", -family => "Helvetica", -size => 10, -weight => "bold");
Tkx::font_create("token_font", -family => "Arial", -size => 10);
Tkx::image_create_photo("mainicon", -file => "..\\res\\world-128x128.png");
Tkx::image_create_photo("erroricon", -file => "..\\res\\gears.png");
Tkx::image_create_photo("tripicon", -file => "..\\res\\tripping.png");
Tkx::image_create_photo("opticon", -file => "..\\res\\world2.png");
Tkx::namespace_import("::tooltip::tooltip");
my $mw = Tkx::widget->new(".");
$mw->g_wm_withdraw();
my $cw = $mw->new_toplevel;
$cw->g_wm_withdraw();
Tkx::tk(appname => "cryptostorm.is darknet client");
Tkx::wm_iconphoto($mw, "mainicon");
my $sr = $mw->new_tkx_SplashScreen(
-image      => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
-width      => 'auto',
-height     => 'auto',
-show       => 1,
-topmost    => 1,
);
my $cv = $sr->canvas();
my $logotext = "\nv$VERSION\n";
$cv->create_text(qw(10 10), -text => $logotext, -anchor => 'w');
my $upgrade = 0;
if (defined($update_var) && ($update_var eq "on")) {
 $logotext = "\n\n\nv$VERSION\nChecking for new version..\n\n";
 &check_version;
 if ($latest ne "nope") {
  if ($VERSION < $latest) {
   $upgrade = 1;
  }
 }
} 
$cv->create_text(qw(10 10), -text => $logotext, -anchor => 'w');
Tkx::after(3000 => sub {
 $sr->g_destroy();
 $mw->g_wm_deiconify();
 $mw->g_raise();
 $mw->g_focus();
});
$mw->g_wm_protocol('WM_DELETE_WINDOW', sub { 
 if ($statusvar =~ /Connected/) { 
  &hidewin;
 }
 else {
  &do_exit;
 }
});
$mw->g_wm_resizable(0,0);
Tkx::wm_title($mw, "cryptostorm.is darknet login");
$pbarval = 0;
$statusvar = "Not connected.";
Tkx::wm_attributes($mw, -toolwindow => 0, -topmost => 0);

$cw->g_wm_protocol('WM_DELETE_WINDOW', sub { 
 &backtomain;
});
$cw->g_wm_resizable(0,0);
Tkx::wm_title($cw, "Options");
Tkx::wm_iconphoto($cw, "mainicon");
$o_frame1 = $cw->new_ttk__frame(-relief => "flat");
$o_worldimage = $o_frame1->new_ttk__label(-anchor => "nw", -justify => "center", -image => 'opticon', -compound => 'top', -text => "Widget v$VERSION");
$back = $o_frame1->new_ttk__button(-text => "Back", -command => \&backtomain);
$o_tabs = $cw->new_ttk__notebook(-height => 100, -width => 260);
$o_innerframe1 = $o_tabs->new_ttk__frame();
$o_innerframe2 = $o_tabs->new_ttk__frame();

$o_innerframe1->new_ttk__label(-text => "                           \n                           \n")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "Automatically connect", -variable => \$autocon_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "Automatically start with Windows", -variable => \$autorun_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "Check for new version on startup", -variable => \$update_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_button1 = $o_innerframe2->new_ttk__button(-text => "Find node with quickest reply", -command => \&o_latency)->g_pack(qw/-anchor nw/);

$o_innerframe2->new_ttk__label(-textvariable => \$o_nodelist)->g_pack(qw/-anchor sw/);
$o_tabs->add($o_innerframe1, -text => 'Startup');
$o_tabs->add($o_innerframe2, -text => 'Nodes');

$o_frame1->g_grid(-column => 0, -row => 0, -sticky => "nswe");
$o_worldimage->g_grid(-column => 0, -row => 0);
$back->g_grid(-column => 0, -row => 1, -sticky => "nswe");
$o_tabs->g_grid(-column => 1, -row => 0, -sticky => "nswe");

$width  = Tkx::winfo('reqwidth',  $cw);
$height = Tkx::winfo('reqheight', $cw);
$height = $height - 20;
$width += 200;
$x = int((Tkx::winfo('screenwidth',  $cw) / 2) - ($width / 2));
$y = int((Tkx::winfo('screenheight', $cw) / 2) - ($height / 2));
$cw->g_wm_geometry($width . "x" . $height . "+" . $x . "+" . $y);

$frame1 = $mw->new_ttk__frame(-relief => "flat");
$worldimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'mainicon', -compound => 'top', -text => "Token:", -font => "logo_font");
$errorimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'erroricon', -compound => 'top', -text => "Token:", -font => "logo_font");
$tripimage = $frame1->new_ttk__label(-anchor => "center", -justify => "center", -image => 'tripicon', -compound => 'top', -text => "Token:", -font => "logo_font");
$userlbl = $frame1->new_ttk__label(-text => "To initiate darknet join, please provide a Network Token below\n" .
                                             "(if you don't have one, you can acquire one at\nhttp://cryptokens.ca)");
$frame2 = $mw->new_ttk__frame(-relief => "flat");
$token_textbox = $frame2->new_ttk__entry(-textvariable => \$token, -width => 27, -font => "token_font");
$server_textbox = $frame2->new_ttk__combobox(-textvariable => \$disp_server, -width => 29, -state => "readonly");
@disp_servers = ("Default node");
open(NODELIST, "$nodelistfile") || &do_error("Can't open $nodelistfile");
my @nodes = <NODELIST>;
close(NODELIST);
for (@nodes) {
 my $tmp = $_;
 chomp($tmp);
 if (($disp_server !~ /$tmp/) && ($disp_server !~ /^\n+$/)) {
  if ($tmp =~ /windows/) {
   /^(.*):(.*):(.*):(.*)$/;
   my $country = $1;
   my $nodename = $2;
   if ($disp_server !~ /^$country \- $nodename$/) {
    push(@disp_servers,"$country - $nodename");
   }
   push(@servers,"$tmp");
  }
 }
}
if ($disp_server ne "Default node") {
 unshift(@disp_servers, "$disp_server");
}
push(@disp_servers,"Custom");
$server_textbox->configure(-values => \@disp_servers);
$server_textbox->g_bind("<<ComboboxSelected>>", sub {
 if ($disp_server eq "Custom") {
  $server_textbox->configure(-state => "normal");
  $disp_server = "";
 }
 else {
  $server_textbox->configure(-state => "readonly");
 }
});
Tkx::tooltip($token_textbox, "Token format: xxxx-xxxx-xxxx-xxx9 (including dashes)");
$frame3 = $mw->new_ttk__frame(-relief => "flat");
$connect = $frame3->new_ttk__button(-text => "\nConnect\n", -command => \&connect);
$options = $frame3->new_ttk__button(-text => "Options", -command => \&do_options);
$cancel = $mw->new_ttk__button(-text => "Exit", -command => \&do_exit);
$save = $frame2->new_ttk__checkbutton(-text => "Save?", -variable => \$saveoption, -onvalue => "on", -offvalue => "off");
$update = $frame2->new_ttk__button(-text => "Update", -command => sub { 
 $statusvar = "Updating node list...";
 Tkx::update();
 $done = 0;
 $update->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $connect->configure(-state => "disabled");
 $updatethread = threads->create( \&update_node_list );
 $updatethread->detach();
 while (!$done) {
  Tkx::update();
  select(undef,undef,undef,0.001);
  if (defined $nodebuf and length $nodebuf) {
   if ($status eq "text/plain") {
    my $tmpnodebuf = $nodebuf;
    $nodebuf = '';
    @disp_servers = ("Default node");
    my @data=split(/\n/, $tmpnodebuf);
    open(NODELIST,">$nodelistfile") || &do_error("Can't write to $nodelistfile");
    foreach my $line (uniq(@data)) {
	 if ($line =~ /windows/) {
      print NODELIST "$line\n";
      $line =~ /^(.*):(.*):(.*):(.*)$/;
      push(@disp_servers,"$1 - $2");
      push(@servers,"$line");
     }
    }
    close(NODELIST);
    push(@disp_servers,"Custom");
    $server_textbox->configure(-values => \@disp_servers, -state => "readonly");
    $update->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = "Node list update complete.";
	$done = 1;
	$updatethread->kill('KILL');
   }
   else {
    $server_textbox->configure(-state => "readonly");
    $update->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = "Error downloading list from http://cryptostorm.nu/nodelist.txt";
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
$progress = $mw->new_ttk__frame(-padding => "3 0 0 0", -relief => "flat");
my $pbarlen = Tkx::winfo('reqwidth',  $mw) * 2 + Tkx::winfo('reqwidth',  $connect);
$pbar = $progress->new_ttk__progressbar (-orient => "horizontal", -length => $pbarlen, -mode => "determinate", -variable => \$pbarval)->g_grid (-column => 0, -row => 0, -sticky => "we");
$statuslbl = $mw->new_ttk__label(-textvariable => \$statusvar, -padding => "0 0 0 0", -relief => "sunken", -width => 64);
$frame4 = $mw->new_ttk__frame(-relief => "flat");
$logbox = $frame4->new_tk__text(-width => 40, -height => 14, -undo => 1, -state => "disabled", -bg => "black", -fg => "grey");
$scroll = $frame4->new_ttk__scrollbar(-command => [$logbox, "yview"], -orient => "vertical");
$logbox->configure(-yscrollcommand => [$scroll, "set"]);
$frame4->g_grid_columnconfigure(0, -weight => 1); 
$frame4->g_grid_rowconfigure(0, -weight => 1);
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
$x = int((Tkx::winfo('screenwidth',  $mw) / 2) - ($width / 2));
$y = int((Tkx::winfo('screenheight', $mw) / 2) - ($height / 2));
$mw->g_wm_geometry($width . "x" . $height . "+" . $x . "+" . $y);
$pbarlen = $width;
if ($autocon_var eq "on") {
 $connect->invoke();
}
if ($upgrade) {
 sleep 3;
 my $upgrade_or_not;
 $upgrade_or_not = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                        -message => "There is a new version available.\nWould you like to upgrade now?\n",
                                        -icon => "question", -title => "cryptostorm.is client");
 if ($upgrade_or_not eq "yes") {
  system("start http://cryptostorm.nu/setup.exe");
 }
}
if (defined($amsg)) {
 Tkx::tk___messageBox(-parent => $mw, -type =>    "ok", 
                                       -message => $amsg,
                                       -icon => "info", -title => "cryptostorm.is client");
}
Tkx::MainLoop();
exit;

sub hidewin {
 if ($mw->g_wm_state eq "normal") {
  $idle = 1;
  #$stop = 1;
  $hiddenornot = "Show";
  $mw->g_wm_withdraw();
  &do_menu(1);
 }
}

sub showwin {
 if ($mw->g_wm_state eq "withdrawn") {
  $hiddenornot = "Hide";
  $idle = 0;
  #$stop = 0;
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
 $TrayIcon  = new Win32::GUI::Icon("../res/world-128x128.ico");
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
 if ($hiddenornot eq "Show") {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => "Options",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&showwin},
              ">-" => {-name => "LS"},
              ">Exit"   => {-name => "Exit",-onClick => \&do_exit }
               ) or die "Creating Menu failed";
 }
 if ($hiddenornot eq "Hide") {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => "Options",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&hidewin, -default => 0},
              ">-" => {-name => "LS"},
              ">Exit"   => {-name => "Exit",-onClick => \&do_exit }
              ) or die "Creating Menu failed";
 }
 if ($balloon) {
  $showtiponce = 1;
 }
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
 if ($disp_server ne "Default node") {
  print CREDS "node=$disp_server\n";
 }
 if ($autocon_var =~ /(on|off)/) {
  print CREDS "autocon=$1\n";
 }
 if ($autorun_var =~ /(on|off)/) {
  print CREDS "autorun=$1\n";
 }
 if ($update_var =~ /(on|off)/) {
  print CREDS "checkforupdate=$1\n";
 }
 close(CREDS);
}

sub check_bit {
 if (uc($ENV{PROCESSOR_ARCHITECTURE}) eq "AMD64" || uc($ENV{PROCESSOR_ARCHITEW6432}) eq "AMD64") {
  $tapexe = "tap64.exe";
  # Not using the 64 bit openvpn cause that would require the 64 bit ssleay/libeay/etc. dlls which would increase 
  # the size of everything and add more files. The performance hit from 32 vs 64 bit openvpn won't be noticable anyways.
  $vpnexe = "vpn32.exe";
  $bit = "64";
 } 
 else {
  $tapexe = "tap32.exe";
  $vpnexe = "vpn32.exe";
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

sub connect {
 if (!$token) {
  &do_error("You didn't enter a token");
  return;
 }
 if (!$disp_server) {
  &do_error("You didn't enter a custom node");
  return;
 }
 if ($disp_server =~ / \- (.*)/) {
  my @actual_server = grep(/:$1:/,@servers);
  $server = $actual_server[0];
  $server =~ s/.*://;
 }
 if (!$server) {
  $server = $disp_server;
 }
 $connect->configure(-state => "disabled");
 $update->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $statusvar = "Checking token syntax...";
 if (($token !~ /^[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}$/) &&
     ($token !~ /^[a-f0-9]{128}$/)) {
  $statusvar = "Not connected.";
  $pbarval = 0;
  $cancel->configure(-text => "Exit");
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $server_textbox->configure(-state => "normal");
  &do_error("Token does not appear to be valid\n(Note that tokens include the dashes)");
  return;
 }
 step_pbar();
 $statusvar = "Checking node syntax...";
 if ($disp_server ne "Default node") {
  $server_host = $server;
  $server_host =~ s/^.* \- //;
  if ($server_host =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/) {
   if (($1 > 255) || ($2 > 255) || ($3 > 255) || ($4 > 255) || ($4 < 1)) {
    $statusvar = "Not connected.";
    $pbarval = 0;
    $cancel->configure(-text => "Exit");
    $connect->configure(-state => "normal");
	$update->configure(-state => "normal");
    $server_textbox->configure(-state => "normal");
	&do_error("Invalid IP address specified");
	return;
   }
  }
  if ($server_host =~ /^([a-zA-Z0-9\-\.]+)$/) {
   if (($1 =~ /^\-/) || ($1 =~ /\-$/) || ($1 =~ /^\./) || ($1 =~ /\.$/) || ($1 =~ /\-\-/) || ($1 =~ /\.\./) || ($1 !~ /\./)) {
    $statusvar = "Not connected.";
    $pbarval = 0;
    $cancel->configure(-text => "Exit");
    $connect->configure(-state => "normal");
	$update->configure(-state => "normal");
    $server_textbox->configure(-state => "normal");
	&do_error("Invalid hostname specified.");
	return;
   }
  }
  else {
   $statusvar = "Not connected.";
   $pbarval = 0;
   $cancel->configure(-text => "Exit");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "normal");
   &do_error("Invalid hostname/IP specified.");
   return;
  }
  $custom = "--remote $server_host 443";
 }
 step_pbar();
 if ($saveoption eq "on") {
  &savelogin;
 }
 if (($autocon_var eq "on") && ($saveoption eq "off") || (!$saveoption)) {
  $autocon_var = "off";
 }
 $statusvar = "Checking if 32 or 64-bit...";
 step_pbar();
 check_bit();
 $statusvar = "Detected $bit bit...";
 Tkx::update();
 $statusvar = "Checking for TAP-Win32 driver...";
 step_pbar();
 check_tapi();
 my $stoopid;
 for ($stoopid=0;$stoopid<=10;$stoopid++) {
  longer(25*$stoopid+200);
 }
 $alreadylong = 1;
 $statusvar = "Syntax verification complete...";
 Tkx::update();
 if ($statusvar =~ /Syntax/) {
  step_pbar();
  $statusvar = "Logging into the darknet...";
  Tkx::update();
  $stop = 0;
  chdir("..\\user");
  open(TMP,">$hashfile") || &do_error("Can't write to .\\user\\");
  if (length($token)) {
   if ($token =~ /^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) {
    print TMP sha512_hex("$token") . "\n";
   }
   if ($token =~ /^([a-f0-9]{128})$/) {
    print TMP "$token\n";
   }
  }
  else {
   print TMP sha512_hex("$token") . "\n";
  }
  print TMP "$password\n";
  close(TMP);
  $logbox->configure(-state => "normal");
  $pid = open $VPNfh, "..\\bin\\$vpnexe $custom --config vpn.conf|" or &do_error("Can't open $vpnexe: $!");
  step_pbar();
  $thread = threads->new( \&read_out, $VPNfh );
  $thread->detach();
  @msgs = ('cryptostorm_darknet',
           'PUSH: Received control message',
           'TAP-WIN32 device .* opened',
           'Route addition via IPAPI succeeded',
           'TEST ROUTES:');
  &logbox_loop;
 }
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
   $statusvar = "Not connected.";
   $pbarval = 0;
   $cancel->configure(-text => "Exit");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "normal");
   &do_error("Authorization failed for that token.");
   $custom = '';
  }
  if ($line =~ /Cannot resolve host address:/) {
   $statusvar = "Not connected.";
   $pbarval = 0;
   $cancel->configure(-text => "Exit");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "normal");
   &do_error("Cannot resolve $server");
   $custom = '';
  }
  if ($line =~ /Initialization Sequence Complete/) {
   #$logbox->configure(-state => "disabled");
   step_pbar();
   $statusvar = "Connected.";
   $balloon_msg = "Connected to the cryptostorm darknet.";
   $cancel->configure(-text => "Disconnect");
   &hidewin;
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
 if ($statusvar =~ /Connected/) {
  $worldimage->g_grid_remove();
  $tripimage->g_grid(-column => 0, -row => 0);
  $idunno = Tkx::tk___messageBox(-type =>    "yesno", 
                                 -message => "You are connected to the Cryptostorm darknet.\nIf you disconnect you will no longer be secured.\n" .
                                             "Are you sure you want to disconnect?",
	                             -icon => "question", -title => "cryptostorm.is client");
  $tripimage->g_grid_remove();
  $worldimage->g_grid(-column => 0, -row => 0);
 }
 if (($idunno eq "yes") || ($idunno eq "whatever")) {
  if ($cancel->cget(-text) eq "Exit") {
   Win32::Process::KillProcess($pid, 0) unless !defined $pid;
   $TrayWinHidden->Open->Remove() unless !defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   $stop = 1;
   $done = 1;
   $o_done1 = 1;
   $mw->g_destroy() unless !defined $mw;
   threads->exit();
   exit;
  }
  if ($cancel->cget(-text) eq "Disconnect") {
   Win32::Process::KillProcess($pid, 0) unless !defined $pid;
   $stop = 1;
   $o_done1 = 1;
   $pbarval = 0;
   $showtiponce = 0;
   $statusvar = "Disconnected.";
   $cancel->configure(-text => "Exit");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "normal");
   $logbox->configure(-state => "normal");
   $logbox->insert('end', "Disconnected.\n");
   $logbox->see('end');
   $TrayWinHidden->Open->Remove() unless !defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   Tkx::update();
  }
 }
}

sub check_tapi {
 chdir("..\\bin") unless defined($_[0]);
 if (!-e "$tapexe") {
  &do_error("Can't find $tapexe");
  return;
 }
 my $cmd = `$tapexe hwids tap0901`;
 if ($cmd =~ /([0-9]+) matching device\(s\) found./) {
  if ($1 == 1) {
   $statusvar = "TAP driver found\n";
   Tkx::update();
   return;
  }
  else {
   $statusvar = "Multiple TAP drivers found. Removing extra ones...";
   Tkx::update();
   my $cmd = `$tapexe remove tap0901`;
   Tkx::update();
   check_tapi(1);
  }
 }
 if ($cmd =~ /tap[32|64] failed/) {
  $cancel->configure(-text => "Exit");
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $server_textbox->configure(-state => "normal");
  &do_error("Couldn't install TAP driver (Administrator privileges are required).");
  $statusvar = "Not connected.";
  Tkx::update();
  return;
 }
 if ($cmd =~ /No matching devices found./) {
  $statusvar = "Installing TAP driver...";
  Tkx::update();
  $cmd = `$tapexe install OemWin2k.inf tap0901`;
  if (($cmd =~ /Drivers installed successfully./) || 
      ($cmd =~ /Device node created. Install is complete when drivers are installed/)) {
   $statusvar = "Installed succesfully.\n";
   Tkx::update();
  }
  else {
   $cancel->configure(-text => "Exit");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "normal");
   &do_error("Couldn't install TAP driver: $cmd");
  }
 }
}

sub do_error {
 my $error = $_[0];
 $worldimage->g_grid_remove();
 $errorimage->g_grid(-column => 0, -row => 0);
 Tkx::tk___messageBox(-icon => "error", -message => "Error: $error");
 $errorimage->g_grid_remove();
 $worldimage->g_grid(-column => 0, -row => 0);
 $options->configure(-state => "normal");
 if ($autocon_var eq "on") {
  $statusvar = "Autoconnect disabled due to error. Re-enable it in Options.";
  $autocon_var = "off";
  &savelogin;
 }
 return;
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
 $response = $ua->get("http://cryptostorm.nu/nodelist.txt", @headers);
 $status = $response->content_type;
 while (defined($response->content and length $response->content)) {
  $nodebuf .= $response->content;
  last if $done;
 }
 $nodebuf = '';
}

sub do_options {
 if ($saveoption eq "off") {
  $autocon_var = "off";
 }
 $mw->g_wm_deiconify();
 $mw->g_wm_withdraw();
 $cw->g_raise();
 $cw->g_wm_deiconify();
 $cw->g_focus();
}

sub backtomain {
 if (defined($o_thread1) && $o_thread1->is_running()) {
  $o_thread1->kill('KILL');
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
 $o_nodelist = "";
 $o_nodelist_buf = "";
 $o_done1 = 1;
 &savelogin;
 $cw->g_wm_deiconify();
 $cw->g_wm_withdraw();
 $mw->g_raise();
 $mw->g_wm_deiconify();
 $mw->g_focus();
}

sub o_latency {
 if (($statusvar =~ /Connected/) || ($statusvar =~ /Logging into/)) {
  $o_nodelist = "\n\nYou must disconnect before you can use\nthis feature.\n";
  return;
 }
 if ((defined($o_thread1) && $o_thread1->is_running())) {
  return;
 }
 $o_nodelist = "";
 $o_done1 = 0;
 $o_thread1 = threads->create( \&o_latency_thread );
 $o_thread1->detach();
 while (!$o_done1) {
  Tkx::update();
  select(undef,undef,undef,0.001);
  if (defined($o_nodelist_buf)) {
   $o_nodelist = $o_nodelist_buf;
  }
  last if $o_done1;
 }
 @latency_array = sort @latency_tmparray;
 my $lowest_latency = $latency_array[0];
 $lowest_latency =~ s/.*://;
 my @node_name = grep(/:$lowest_latency/,@servers);
 $lowest_latency = $node_name[0];
 $lowest_latency =~ s/:windows:.*//;
 $lowest_latency =~ s/.*://;
 $o_nodelist = "\n\n" . uc($lowest_latency) . " has the quickest reply\n";
}

sub check {
 our $ip = $_[0];
 our $port = 443;
 our $message;
 sub timeout {
  close($message);
  $o_done1 = 1;
  Tkx::update();
  return "\n\n$ip timed out\n";
 }
 eval {
  local $SIG{ALRM} = sub { &timeout; };
  alarm 5;
  my $now = [gettimeofday()];
  my $message = IO::Socket::INET->new(Proto=>"udp",PeerPort=>$port,PeerAddr=>"$ip") or die "$@";
  $message->send("\x38\x40\x80\x2a\xfa\xdb\x9b\x67\x95\x00\x00\x00\x00\x00");
  my ($datagram,$flags);
  $message->recv($datagram,26,$flags);
  if (length($datagram) == 26) {
   my $andagain = tv_interval($now)*1000;
   my $ms = sprintf("%d", $andagain);
   Tkx::update();
   return "\n\n$ip replied in $ms ms\n";
   if ($ms =~ /^[0-9]{3}$/) {
    $ms =~ s/^/0/;
   }
   if ($ms =~ /^[0-9]{2}$/) {
    $ms =~ s/^/00/;
   }
  }
  else {
   Tkx::update();
   return "\n\n$ip looks DOWN\n";
  }
  alarm 0;
 }
}

sub o_latency_thread {
 local $SIG{KILL} = sub { threads->exit };
 for (@nodes) {
  if (/.*:([0-9\.]+)$/) {
   $o_nodelist_buf = &check($1);
   if (defined($o_nodelist_buf) && ($o_nodelist_buf =~ /([0-9\.]+) replied in ([0-9]+) ms/)) {
    push(@latency_tmparray,"$2:$1");
   }
  }
 }
 undef $o_nodelist_buf;
 $o_done1 = 1;
}

sub check_version {
 $o_done3 = 0;
 $o_thread3 = threads->create( \&check_version_thread );
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
 my ($ua,$response);
 my @headers = ('User-Agent' => "Cryptostorm client");
 $ua = LWP::UserAgent->new(agent => "Cryptostorm client");
 $ua->timeout(2);
 $response = $ua->get("http://cryptostorm.nu/latest.txt", @headers);
 if ($response->is_success()) {
  if ($response->content() =~ /LATEST:([0-9\.]+)/) {
   $o_version_buf = $1;
  }
  if ($response->content() =~ /MSG:ON:(.*)/) {
   $amsg = $1;
  }
  if ((!$o_version_buf) && (!$amsg)) {
   $o_version_buf = "nope";
  }
 }
 else {
  $o_version_buf = "nope";
 }
}
