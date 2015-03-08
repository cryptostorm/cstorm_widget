#!/usr/bin/perl #-d:Trace
#open(STDERR, ">&STDOUT") or warn "failed to dup STDOUT:$!";
#$Devel::Trace::TRACE = 1;
if (-d "\\Program Files\\Cryptostorm Client\\bin") {
 chdir("\\Program Files\\Cryptostorm Client\\bin\\");
}
if (-d "\\Program Files (x86)\\Cryptostorm Client\\bin") {
 chdir("\\Program Files (x86)\\Cryptostorm Client\\bin\\");
}
our @i;
$i[0] = "Copy failed: ";
$i[1] = "Delete failed: ";
$i[2] = "Another program is attempting to close the cryptostorm client.\nDo you want to allow this?\n(If you are upgrading using setup.exe, choose \"Yes\" here)\n";
$i[3] = "Connected";
$i[4] = "Not connected";
$i[5] = "Options";
$i[6] = "Back";
$i[7] = "Automatically connect";
$i[8] = "Automatically start with Windows";
$i[9] = "Check for updates on startup";
$i[10] = "Connect to port";
$i[11] = "Connect with protocol";
$i[12] = "\n\"Random\" port\n";
$i[13] = "Startup";
$i[14] = "Connecting";
$i[15] = "Security";
$i[16] = "Disable IPv6";
$i[17] = "DNS leak prevention";
$i[18] = "STUN/WebRTC leak prevention";
$i[19] = "To connect to the darknet, provide a Network Token below.\n" .
           "If you don't have one, you can get one at\n[ https://cryptostorm.is/join ]\n" .
		   "or you can try the new free/capped \"Cryptofree\" node\n".
		   "from the dropdown list below.\n" .
		   "[ http://cryptofree.me ]\n\n\n";
$i[20] = "Token format: xxxx-xxxx-xxxx-xxx9 (including dashes)";
$i[21] = "\nConnect\n";
$i[22] = "Exit";
$i[23] = "Save?";
$i[24] = "Update";
$i[25] = "Updating node list...";
$i[26] = "Can't write to $nodelist";
$i[27] = "Node list update complete.";
$i[28] = "Error downloading list from http://cryptostorm.nu/nodelist.txt";
$i[29] = "There is a new version available.\nWould you like to upgrade now?\n";
$i[30] = "Show"; # In the program, will appear as "Show client" in the systray
$i[31] = "Hide"; # In the program, will appear as "Hide client" in the systray
$i[32] = "Creating Menu failed";
$i[33] = "Connect took longer than 60 seconds, retrying...\n";
$i[34] = "You didn't enter a token";
$i[35] = "Checking token syntax...";
$i[36] = "Token does not appear to be valid\n(Note that tokens include the dashes)";
$i[37] = "Checking if 32 or 64-bit...";
$i[38] = "Detected xxx bits...";
$i[39] = "Checking for TAP-Win32 driver...";
$i[40] = "Logging into the darknet...";
$i[41] = "Can't write to .\\user\\";
$i[42] = "Stopping STUN/WebRTC leak...";
$i[43] = "Disabling IPv6...";
$i[44] = "Can't open csvpn.exe";
$i[45] = "Authorization failed\n";
$i[46] = "Cannot resolve $server";
$i[47] = "Connected with errors (most likely TAP related)\n";
$i[48] = "Connection errors occurred. This is usually caused by a bug in Windows 8/8.1 that affects the TAP-Win32 driver. If the problem persists, go to https://openvpn.net/index.php/open-source/downloads.html and download/install the latest TAP-windows installer, then run this program again.";
$i[49] = "Connected to the cryptostorm darknet.";
$i[50] = "Disconnect";
$i[51] = "You are connected to the Cryptostorm darknet.\nIf you disconnect you will no longer be secured.\n" .
		 "Are you sure you want to disconnect?";
$i[52] = "Unblocking STUN/WebRTC...";
$i[53] = "Re-enabling IPv6...";
$i[54] = "Disconnected.";
$i[55] = "Can't find $tapexe";
$i[56] = "TAP driver found";
$i[57] = "Multiple TAP drivers found. Removing extra ones...";
$i[58] = "Couldn't install TAP driver (Administrator privileges are required).";
$i[59] = "Installing TAP driver...";
$i[60] = "Installed succesfully.";
$i[61] = "Couldn't install TAP driver";
$i[62] = "Autoconnect disabled due to error. Re-enable it in Options.";
$i[63] = "Port needs to be a number between 1 and 655334";
$i[64] = "Authorization failed for that token.";
$i[65] = "Global random";
$i[66] = "Only one instance of this program can be ran at a time.\nWould you like to close the other instance?\n";
$i[67] = "Running DNS leak prevention...\n";
$i[68] = "Disable splash image on startup.";
our $VERSION = "2.22";
use threads;
use threads::shared;
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
use Win32::Process::Info;
use Win32::TieRegistry(Delimiter => "/");
use Win32::Process::Info;
use Cwd 'abs_path';
use File::Copy;
our $self = abs_path($0);
$self =~ s/\//\\/g;
our $dns_line_from_openvpn;
my $buffer : shared;
my $stop : shared;
my $done : shared;
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
my $authfile = "..\\user\\logo.jpg";
my $hashfile = "..\\user\\client.dat";
my $vpncfgfile = "..\\user\\custom.conf";
our $whichvpn = "";
my $cacertfile = "..\\user\\ca.crt";
my $cclientfile = "..\\user\\client.crt";
my $clientkey  = "..\\user\\client.key";
my $nodelistfile = "..\\user\\nodelist.txt";
my $c = 0;
my $alreadylong = 0;
my $server = "";
my ( $line, $VPNfh, $thread, $updatethread, $bit, $tapexe, $vpnexe, $h);
my ($frame1, $frame2, $frame3, $frame4, $saveoption, $password, $userlbl, $passlbl, $connect, $cancel, $pass, 
    $save, $progress, $pbar, $pbarval, $statuslbl, $statusvar, $token_textbox, $token, $worldimage, $logbox, 
	$scroll, $errorimage, $server_textbox, $disp_server, $tripimage, $server_host, $update, $menu, $send, $options);
my ($autocon, $autocon_var, $autorun, $autorun_var, $o_frame1, $o_worldimage, $back, $o_tabs, $o_innerframe1, 
    $o_innerframe2, $o_innerframe3);
my ($o_thread3); 
my $autosplash_var;
my $hiddenornot = $i[31];
my ($TrayIcon,$TrayWinHidden,$TrayNotify,$TrayMenu);
my $showtiponce = 0;
my ($x, $y, $width, $height);
our (@servers, @disp_servers);
my $upgrade = 0;
my $balloon_msg;
my $idle = 0;
my $update_var;
my $tokillornot;
my $o_myip;
our @msgs;
my @tmparray;
my $tmpline = "";
my $vpn_args = "";
$disp_server = "$i[65]";
$SIG{'TERM'} = 'TERM_handler';
$SIG{'ABRT'} = 'TERM_handler';
$SIG{'INT'} = 'TERM_handler';
$SIG{'KILL'} = 'TERM_handler';
$SIG{'HUP'} = 'TERM_handler';
if ((-e $ENV{'TEMP'} . "\\client.dat") && (-e $ENV{'TEMP'} . "\\logo.jpg")) {
 copy($ENV{'TEMP'} . "\\client.dat",$hashfile) or die "$i[0]: $!\n";
 copy($ENV{'TEMP'} . "\\logo.jpg",$authfile) or die "$i[0]: $!\n";
 unlink($ENV{'TEMP'} . "\\client.dat") or die "$i[1]: $!\n";
 unlink($ENV{'TEMP'} . "\\logo.jpg") or die "$i[1]: $!\n";
}
my $nostun_var = "on";
my $noleak_var = "on";
my $ipv6_var = "on";
our $port_var = "443";
my $proto_var = "UDP";
my @protos = ('UDP', 'TCP');
if (-e "$authfile") {
 open(CREDS,"$authfile");
 while (<CREDS>) {
  if ((/^([a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5})$/) ||
      (/^([a-f0-9]{128})$/)) {
   $token = $1 unless ($1 eq "4a8d8a7ef2cdde9979a5c014d8f7d73a39617450fa212fe54b40e5d166f313e15502a9d954191a72b6aba0f275d98294598ec1fbbb0e542d2e9ecba069ad3ecd");
  }
  if (/^nostun=(.*)$/) {
   $nostun_var = $1;
  }
  if (/^nodnsleak=(.*)$/) {
   $noleak_var = $1;
  }
  if (/^noipv6=(.*)$/) {
   $ipv6_var = $1;
  }
  if (/^port=(.*)$/) {
   $port_var = $1;
  }
  if (/^proto=(.*)$/) {
   $proto_var = $1;
  }
  if (/^node=(.*)$/) {
   $disp_server = $1 unless ($1 eq "Cryptofree");
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
sub TERM_handler {
 $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                      -message => "$i[2]",
                                      -icon => "question", -title => "cryptostorm.is client");
 if ($tokillornot eq "yes") {
  if ($token) {
   copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
   copy($authfile,$ENV{'TEMP'} . "\\logo.jpg");
  }
  exit;
 }
}
my $cw = $mw->new_toplevel;
$cw->g_wm_withdraw();
Tkx::tk(appname => "cryptostorm.is darknet client");
Tkx::wm_iconphoto($mw, "mainicon");
my $pi = Win32::Process::Info->new;
my @info = $pi->GetProcInfo();
foreach(@info) {
 if($_->{Name} =~ /^csvpn.exe$/) {
  Win32::Process::KillProcess ($_->{ProcessId}, 0);
 }
 if($_->{Name} =~ /^client.exe$/) {
  if (($_->{ExecutablePath} =~ /Cryptostorm Client/) && ($_->{ProcessId} != $$)) {
   $tokillornot = Tkx::tk___messageBox(-parent => $mw, -type =>    "yesno", 
                                        -message => "$i[66]",
                                        -icon => "question", -title => "cryptostorm.is client");
   if ($tokillornot eq "yes") {
    Win32::Process::KillProcess ($_->{ProcessId}, 0);
	$pi = Win32::Process::Info->new;
    @info = $pi->GetProcInfo();
	foreach(@info) {
     if($_->{Name} =~ /^csvpn.exe$/) {
      Win32::Process::KillProcess ($_->{ProcessId}, 0);
	 }
	}
   }
   if ($tokillornot eq "no") {
    exit;
   }
  }
 }
}
if ($autosplash_var eq "on") {
 $upgrade = 0;
 if (defined($update_var) && ($update_var eq "on")) {
  &check_version;
  if ($latest ne "nope") {
   if ($VERSION < $latest) {
    $upgrade = 1;
   }
  }
 }
 $mw->g_wm_deiconify();
 $mw->g_raise();
 $mw->g_focus();
}
else {
 my $sr = $mw->new_tkx_SplashScreen(
 -image      => Tkx::image_create_photo(-file => "..\\res\\splash.png"),
 -width      => 'auto',
 -height     => 'auto',
 -show       => 1,
 -topmost    => 1,
 );
 my $cv = $sr->canvas();
 $cv->create_text(qw(10 10), -anchor => 'w');
 $upgrade = 0;
 if (defined($update_var) && ($update_var eq "on")) {
  &check_version;
  if ($latest ne "nope") {
   if ($VERSION < $latest) {
    $upgrade = 1;
   }
  }
 }
 $cv->create_text(qw(10 10), -anchor => 'w');
 Tkx::after(3000 => sub {
  $sr->g_destroy();
  $mw->g_wm_deiconify();
  $mw->g_raise();
  $mw->g_focus();
 });
}
$mw->g_wm_protocol('WM_DELETE_WINDOW', sub { 
 if ($statusvar =~ /$i[3]/) { 
  &hidewin;
 }
 else {
  &do_exit;
 }
});
$mw->g_wm_resizable(0,0);
Tkx::wm_title($mw, "cryptostorm widget");
$pbarval = 0;
$statusvar = $i[4] . ".";
Tkx::wm_attributes($mw, -toolwindow => 0, -topmost => 0);

$cw->g_wm_protocol('WM_DELETE_WINDOW', sub { 
 &backtomain;
});
$cw->g_wm_resizable(0,0);
Tkx::wm_title($cw, "$i[5]");
Tkx::wm_iconphoto($cw, "mainicon");
$o_frame1 = $cw->new_ttk__frame(-relief => "flat");
$o_worldimage = $o_frame1->new_ttk__label(-anchor => "nw", -justify => "center", -image => 'opticon', -compound => 'top', -text => "Widget v$VERSION");
$back = $o_frame1->new_ttk__button(-text => "$i[6]", -command => \&backtomain);
$o_tabs = $cw->new_ttk__notebook(-height => 100, -width => 260);
$o_innerframe1 = $o_tabs->new_ttk__frame();
$o_innerframe2 = $o_tabs->new_ttk__frame();
$o_innerframe3 = $o_tabs->new_ttk__frame();

$o_innerframe1->new_ttk__label(-text => "                           \n                           \n")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "$i[68]", -variable => \$autosplash_var, -onvalue => "on", -offvalue => "off")->g_pack
(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "$i[7]", -variable => \$autocon_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "$i[8]", -variable => \$autorun_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe1->new_ttk__checkbutton(-text => "$i[9]", -variable => \$update_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe2->new_ttk__label(-text => "$i[10]")->g_pack(qw/-anchor s/);
my $port_textbox = $o_innerframe2->new_ttk__entry(-textvariable => \$port_var, -width => 6)->g_pack(qw/-anchor s/);
$o_innerframe2->new_ttk__label(-text => "$i[11]")->g_pack(qw/-anchor s/);
my $proto_textbox = $o_innerframe2->new_ttk__combobox(-textvariable => \$proto_var, -values => \@protos, -width => 4, -state=>"readonly")->g_pack(qw/-anchor s/);
my $randomize_it;
$o_innerframe2->new_ttk__checkbutton(-text => "$i[12]", -variable => \$randomize_it, -onvalue => "on", -offvalue => "off", -command => sub {
 if ($randomize_it eq "on") {
  $port_var = int(rand(65533) + 1);
 }
 if ($randomize_it eq "off") {
  $port_var = 443;
 }
 })->g_pack(qw/-anchor s/);

$o_tabs->add($o_innerframe1, -text => "$i[13]");
$o_tabs->add($o_innerframe2, -text => "$i[14]");
$o_tabs->add($o_innerframe3, -text => "$i[15]");

$o_innerframe3->new_ttk__label(-text => "                           \n                           \n")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => "$i[16]", -variable => \$ipv6_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => "$i[17]", -variable => \$noleak_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);
$o_innerframe3->new_ttk__checkbutton(-text => "$i[18]", -variable => \$nostun_var, -onvalue => "on", -offvalue => "off")->g_pack(qw/-anchor nw/);

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
$userlbl = $frame1->new_ttk__label(-text => "$i[19]");
$frame2 = $mw->new_ttk__frame(-relief => "flat");
$token_textbox = $frame2->new_ttk__entry(-textvariable => \$token, -width => 27, -font => "token_font");
$server_textbox = $frame2->new_ttk__combobox(-textvariable => \$disp_server, -width => 29, -state => "readonly");
@disp_servers = ("$i[65]","Cryptofree");
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
   #my $nodename = $1;
   if ($disp_server !~ /$country/) {
    push(@disp_servers,"$country");
   }
   push(@servers,"$tmp");
  }
 }
}
if ($disp_server ne "$i[65]") {
 unshift(@disp_servers, "$disp_server");
}
$server_textbox->configure(-values => \@disp_servers);
Tkx::tooltip($token_textbox, "$i[20]");
$frame3 = $mw->new_ttk__frame(-relief => "flat");
$connect = $frame3->new_ttk__button(-text => "$i[21]", -command => \&connect);
$options = $frame3->new_ttk__button(-text => "$i[5]", -command => \&do_options);
$cancel = $mw->new_ttk__button(-text => "$i[22]", -command => \&do_exit);
$save = $frame2->new_ttk__checkbutton(-text => "$i[23]", -variable => \$saveoption, -onvalue => "on", -offvalue => "off");
$update = $frame2->new_ttk__button(-text => "$i[24]", -command => sub { 
 $statusvar = "$i[25]";
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
    @disp_servers = ("$i[65]","Cryptofree");
    my @data=split(/\n/, $tmpnodebuf);
    open(NODELIST,">$nodelistfile") || &do_error("$i[26] $nodelistfile");
    foreach my $line (uniq(@data)) {
	 if ($line =~ /windows/) {
      print NODELIST "$line\n";
      $line =~ /^(.*):(.*):(.*):(.*)$/;
      push(@disp_servers,"$1");
      push(@servers,"$line");
     }
    }
    close(NODELIST);
    $server_textbox->configure(-values => \@disp_servers, -state => "readonly");
    $update->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = "$i[27]";
	$done = 1;
	$updatethread->kill('KILL');
   }
   else {
    $server_textbox->configure(-state => "readonly");
    $update->configure(-state => "normal");
	$connect->configure(-state => "normal");
    $statusvar = "$i[28]";
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
  $token = "4a8d8a7ef2cdde9979a5c014d8f7d73a39617450fa212fe54b40e5d166f313e15502a9d954191a72b6aba0f275d98294598ec1fbbb0e542d2e9ecba069ad3ecd";
  Tkx::tooltip($token_textbox, "");
  $token_textbox->configure(-state => "disabled");
  $whichvpn = "free";
 }
 else {
  $token = $tmptok;
  Tkx::tooltip($token_textbox, "$i[20]");
  $token_textbox->configure(-state => "normal");
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
                                        -message => "$i[29]",
                                        -icon => "question", -title => "cryptostorm.is client");
 if ($upgrade_or_not eq "yes") {
  if ($token) {
   copy($hashfile,$ENV{'TEMP'} . "\\client.dat");
   copy($authfile,$ENV{'TEMP'} . "\\logo.jpg");
  }
  system("start http://cryptostorm.nu/setup.exe");
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
 if ($mw->g_wm_state eq "normal") {
  $idle = 1;
  $hiddenornot = "$i[30]";
  $mw->g_wm_withdraw();
  &do_menu(1);
 }
}

sub showwin {
 if ($mw->g_wm_state eq "withdrawn") {
  $hiddenornot = "$i[31]";
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
 if ($hiddenornot eq "$i[30]") {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => "$i[5]",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&showwin},
              ">-" => {-name => "LS"},
              ">$i[22]"   => {-name => "Exit",-onClick => \&do_exit }
               ) or die "$i[32]";
 }
 if ($hiddenornot eq "$i[31]") {
  $TrayMenu = Win32::GUI::Menu->new(
              "" => "$i[5]",
              ">$hiddenornot client" => {-name => "Toggle", -onClick => \&hidewin, -default => 0},
              ">-" => {-name => "LS"},
              ">$i[22]"   => {-name => "Exit",-onClick => \&do_exit }
              ) or die "$i[32]";
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
 if ($disp_server ne "$i[65]") {
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
 if ($update_var =~ /(on|off)/) {
  print CREDS "checkforupdate=$1\n";
 }
 if ($nostun_var =~ /(on|off)/) {
  print CREDS "nostun=$1\n";
 }
 if ($noleak_var =~ /(on|off)/) {
  print CREDS "nodnsleak=$1\n";
 }
 if ($ipv6_var =~ /(on|off)/) {
  print CREDS "noipv6=$1\n";
 }
 if ($port_var =~ /([0-9]+)/) {
  print CREDS "port=$1\n";
 }
 if ($proto_var =~ /(UDP|TCP)/) {
  print CREDS "proto=$1\n";
 }
 close(CREDS);
}

sub check_bit {
 if (uc($ENV{PROCESSOR_ARCHITECTURE}) eq "AMD64" || uc($ENV{PROCESSOR_ARCHITEW6432}) eq "AMD64") {
  $tapexe = "tap64.exe";
  $vpnexe = "csvpn.exe";
  $bit = "64";
 } 
 else {
  $tapexe = "tap32.exe";
  $vpnexe = "csvpn.exe";
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
sub recon {
 $logbox->insert_end("$i[33]", "warnline");
 $logbox->see('end');
 $statusvar = $i[4] . ".";
 $pbarval = 0;
 $cancel->configure(-text => "$i[22]");
 $connect->configure(-state => "normal");
 $update->configure(-state => "normal");
 $server_textbox->configure(-state => "readonly");
 $stop = 1;
 $o_done3 = 1;
 $showtiponce = 0;
 Win32::Process::KillProcess($pid, 0) if defined $pid;
 $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
 undef $TrayWinHidden if defined $TrayWinHidden;
 alarm 0;
 select(undef,undef,undef,0.05); 
 &connect;
}

sub connect {
 $SIG{ALRM} = sub { &recon; };
 alarm 60;
 if (!$token) {
  &do_error("$i[34]");
  alarm 0;
  return;
 }
 if ($disp_server ne "$i[65]") {
  my @actual_server = grep(/$1/,@servers);
  $server = $actual_server[0];
  $server = "" unless defined($actual_server[0]);
  $server =~ s/.*://;
 }
 if (!$server) {
  $server = $disp_server;
 }
 $connect->configure(-state => "disabled");
 $update->configure(-state => "disabled");
 $server_textbox->configure(-state => "disabled");
 $statusvar = "$i[35]";
 $token =~ s/[^a-zA-Z0-9\-]//g;
 if (($token !~ /^[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}\-[a-zA-Z0-9]{5}$/) &&
     ($token !~ /^[a-f0-9]{128}$/)) {
  $statusvar = $i[4] . ".";
  $pbarval = 0;
  $cancel->configure(-text => "$i[22]");
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  $server_textbox->configure(-state => "readonly");
  &do_error("$i[36]");
  alarm 0;
  return;
 }
 step_pbar();
 if ($saveoption eq "on") {
  &savelogin;
 }
 if (($autocon_var eq "on") && ($saveoption eq "off") || (!$saveoption)) {
  $autocon_var = "off";
 }
 $statusvar = "$i[37]";
 step_pbar();
 check_bit();
 $statusvar = "$i[38]";
 $statusvar =~ s/xxx/$bit/;
 Tkx::update();
 sleep(2);
 $statusvar = "$i[39]";
 step_pbar();
 check_tapi();
 my $stoopid;
 for ($stoopid=0;$stoopid<=10;$stoopid++) {
  longer(25*$stoopid+200);
 }
 $alreadylong = 1;
 Tkx::update();
 if ($statusvar =~ /$i[56]/) {
  step_pbar();
  $statusvar = "$i[40]";
  Tkx::update();
  $stop = 0;
  chdir("..\\user");
  open(TMP,">$hashfile") || &do_error("$i[41]");
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
  if ($disp_server eq "Cryptofree") {
   $whichvpn = "free";
  }
  else {
   $whichvpn = "paid";
  }
  if ($nostun_var eq "on") {
   $statusvar = "$i[42]";
   Tkx::update();
   system("nostun.bat");
   $statusvar = "$i[40]";
   Tkx::update();
  }
  if ($ipv6_var eq "on") {
   $statusvar = "$i[43]";
   Tkx::update();
   system("ipv6_off.bat");
   $statusvar = "$i[40]";
   Tkx::update();
  }
  undef @tmparray;
  undef $tmpline;
  undef $vpn_args;
  if ($whichvpn eq "free") {
   if ($proto_var eq "UDP") {
    $vpn_args = "--client --dev tun --proto udp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
   }
   if ($proto_var eq "TCP") {
    $vpn_args = "--client --dev tun --proto tcp --remote windows-cryptofree1-a.cstorm.pw $port_var --remote windows-cryptofree1-a.cryptostorm.net $port_var --remote windows-cryptofree1-a.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
   }
  }
  if ($whichvpn eq "paid") {
   if ($proto_var eq "UDP") {
    if ($server eq "$i[65]") {
     $vpn_args = "--client --dev tun --proto udp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	}
	else {
	 my @tmparray = grep(/$server/,@servers);
	 my $tmpline = $tmparray[0];
	 $tmpline =~ s/.*://;
	 $tmpline =~ s/\.cstorm\.pw//;
	 $vpn_args = "--client --dev tun --proto udp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --explicit-exit-notify 3 --hand-window 17 --fragment 1400 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	}
   }
   if ($proto_var eq "TCP") {
    if ($server eq "$i[65]") {
     $vpn_args = "--client --dev tun --proto tcp --remote windows-balancer.cstorm.pw $port_var --remote windows-balancer.cryptostorm.net $port_var --remote windows-balancer.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
	}
	else {
	 my @tmparray = grep(/$server/,@servers);
	 my $tmpline = $tmparray[0];
	 $tmpline =~ s/.*://;
	 $tmpline =~ s/\.cstorm\.pw//;
	 $vpn_args = "--client --dev tun --proto tcp --remote $tmpline.cstorm.pw $port_var --remote $tmpline.cryptostorm.net $port_var --remote $tmpline.cryptostorm.org $port_var --resolv-retry infinite --nobind --comp-lzo --down-pre --reneg-sec 0 --hand-window 17 --verb 4 --mute 3 --auth-user-pass client.dat --ca ca2.crt --ns-cert-type server --auth SHA512 --cipher AES-256-CBC --tls-cipher TLS-DHE-RSA-WITH-AES-256-CBC-SHA --tls-client --key-method 2";
    }
   }
  }
  $pid = open $VPNfh, "..\\bin\\$vpnexe $vpn_args --config $vpncfgfile|" or &do_error("$i[44]");
  step_pbar();
  Tkx::update();
  $thread = threads->new( \&read_out, $VPNfh );
  $thread->detach();
  @msgs = ('cryptostorm_darknet',
           'PUSH: Received control message',
           'TAP-WIN32 device .* opened',
           'Route addition via IPAPI succeeded',
           'TEST ROUTES:');
  &logbox_loop;
 }
 alarm 0;
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
   if ($line =~ /dhcp-option DNS/) {
    $dns_line_from_openvpn = $line;
   }
  }
  if ($line =~ /AUTH: Received control message: AUTH_FAILED/) {
   $logbox->insert_end("$i[45]", "badline");
   $logbox->see('end');
   $statusvar = $i[4] . ".";
   $pbarval = 0;
   $cancel->configure(-text => "$i[22]");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error("$i[64]");
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   alarm 0;
  }
  if ($line =~ /Cannot resolve host address:/) {
   $logbox->insert_end("$i[46] $server\n", "badline");
   $logbox->see('end');
   $statusvar = $i[4] . ".";
   $pbarval = 0;
   $cancel->configure(-text => "$i[22]");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   &do_error("Cannot resolve $server");
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   alarm 0;
  }
  if ($line =~ /Initialization Sequence Complete/) {
   if ($line =~ /Initialization Sequence Completed With Errors/) {
    $logbox->insert_end("$i[47]", "badline");
    $logbox->see('end');
    $cancel->configure(-text => "$i[22]");
    $statusvar = $i[4] . ".";
    $connect->configure(-state => "normal");
    $update->configure(-state => "normal");
	$server_textbox->configure(-state => "readonly");
    &do_error("$i[48]");
	Win32::Process::KillProcess($pid, 0) if defined $pid;
	alarm 0;
   }
   else {
    step_pbar();
    $logbox->insert_end("$i[3]\n", "goodline");
    $logbox->see('end');
	$statusvar = $i[3] . ".";
    $balloon_msg = "$i[49]";
    $cancel->configure(-text => "$i[50]");
	alarm 0;
	if ($noleak_var eq "on") {
     $statusvar = "$i[67]";
     &plugdnsleak;
	 $statusvar = $i[3] . ".";
	 Tkx::update();
    }
    &hidewin;
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
 if ($statusvar =~ /$i[3]/) {
  $worldimage->g_grid_remove();
  $tripimage->g_grid(-column => 0, -row => 0);
  $idunno = Tkx::tk___messageBox(-type =>    "yesno", 
                                 -message => "$i[51]",
	                             -icon => "question", -title => "cryptostorm.is client");
  $tripimage->g_grid_remove();
  $worldimage->g_grid(-column => 0, -row => 0);
 }
 if (($idunno eq "yes") || ($idunno eq "whatever")) {
  $cancel->configure(-state => "disabled");
  if ($nostun_var eq "on") {
   $statusvar = "$i[52]";
   Tkx::update();
   system("netsh advfirewall firewall del rule name=\"No STUN leak for j00!\"");
  }
  if ($ipv6_var eq "on") {
   $statusvar = "$i[53]";
   Tkx::update();
   system("ipv6_on.bat");
  }
  if ($noleak_var eq "on") {
   for (@recover) {
	if (/^(.*):DHCP:(.*)$/) {
	 system(qq(netsh interface ip set dns "$1" dhcp));
	}
	if (/^(.*):Static:(.*)$/) {
	 system(qq(netsh interface ip set dns "$1" static $2));
	}
   }
  }
  $statusvar = "$i[54]";
  Tkx::update();
  if ($cancel->cget(-text) eq "$i[22]") {
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   $stop = 1;
   $done = 1;
   $o_done3 = 1;
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   $mw->g_destroy() if defined $mw;
   exit(0);
  }
  if ($cancel->cget(-text) eq "$i[50]") {
   $stop = 1;
   $o_done3 = 1;
   $pbarval = 0;
   $showtiponce = 0;
   $statusvar = "$i[54]";
   $cancel->configure(-text => "$i[22]");
   $update->configure(-state => "normal");
   $connect->configure(-state => "normal");
   $server_textbox->configure(-state => "readonly");
   $logbox->delete("end - 1 line","end");
   $logbox->delete("end - 1 line","end");
   $logbox->insert_end("\n\n\n\n\n\n\n\n\n\n\n");
   $logbox->insert_end("$i[54]\n", "badline");
   $logbox->see('end');  
   Win32::Process::KillProcess($pid, 0) if defined $pid;
   $TrayWinHidden->Open->Remove() if defined $TrayWinHidden;
   undef $TrayWinHidden if defined $TrayWinHidden;
   $cancel->configure(-state => "normal");
  }
 }
}

sub check_tapi {
 chdir("..\\bin") unless defined($_[0]);
 if (!-e "$tapexe") {
  &do_error("$i[55] $tapexe");
  return;
 }
 my $cmd = `$tapexe hwids tap0901`;
 if ($cmd =~ /([0-9]+) matching device\(s\) found./) {
  if ($1 == 1) {
   $statusvar = "$i[56]";
   Tkx::update();
   return;
  }
  else {
   $statusvar = "$i[57]";
   Tkx::update();
   my $cmd = `$tapexe remove tap0901`;
   Tkx::update();
   check_tapi(1);
  }
 }
 if ($cmd =~ /tap[32|64] failed/) {
  $cancel->configure(-text => "$i[22]");
  $connect->configure(-state => "normal");
  $update->configure(-state => "normal");
  &do_error("$i[58]");
  $statusvar = $i[4] . ".";
  Tkx::update();
  return;
 }
 if ($cmd =~ /No matching devices found./) {
  $statusvar = "$i[59]";
  Tkx::update();
  $cmd = `$tapexe install OemWin2k.inf tap0901`;
  if ($cmd =~ /Drivers installed successfully./) {
   $statusvar = "$i[60]";
   Tkx::update();
  }
  else {
   $cancel->configure(-text => "$i[22]");
   $connect->configure(-state => "normal");
   $update->configure(-state => "normal");
   &do_error("$i[61]: $cmd");
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
  $statusvar = "$i[62]";
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
$port_var =~ s/[^0-9]//g;
 if ($port_var =~ /^([0-9]+)$/) {
  if (($1 < 1) || ($1 > 65534)) {
   &do_error("$i[63]");
   return;
  }
 }
 if ($port_var !~ /^([0-9]+)$/) {
  &do_error("$i[63]");
  return
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
 if ($nostun_var eq "off") {
   system("netsh advfirewall firewall del rule name=\"No STUN leak for j00!\"");
 }
 if ($ipv6_var eq "off") {
  system("ipv6_on.bat");
 }
 &savelogin;
 $cw->g_wm_deiconify();
 $cw->g_wm_withdraw();
 $mw->g_raise();
 $mw->g_wm_deiconify();
 $mw->g_focus();
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

sub plugdnsleak {
 splice(@words);
 splice(@dns_ips);
 @words = split(/,/, $dns_line_from_openvpn);
 for (@words) {
  if (/^dhcp-option DNS (.*)/) {
   push(@dns_ips,"$1");
  }
 }
 open(my $fh, '-|', 'netsh interface ipv4 show dnsserv') or die $!;
 my $current_interface;
 for (@dns_ips) {
  my $pushed_dns_ip = $_;
  chomp($pushed_dns_ip);
  while (my $line = <$fh>) {
   if ($line =~ /Configuration for interface "(.*)"/) {
    $current_interface = $1;
   }
   if (($line =~ /DNS servers configured through (DHCP):(.*)/) ||
       ($line =~ /(Static)ally Configured DNS Servers:(.*)/)) {
	my $dnstype = $1;
    my $tmpy = $2;
	$tmpy =~ s/\s//g;
	if (($tmpy ne $pushed_dns_ip) && ($tmpy ne "None")) {
	 push(@recover,"$current_interface:$dnstype:$tmpy");
	 system 1, qq(netsh interface ip set dns "$current_interface" static $pushed_dns_ip);
	 for (@dns_ips) {
	  system 1, (qq(netsh interface ip add dns "$current_interface" addr=$_));
	 }
	}
   }
  }
 }
}
