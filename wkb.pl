use Irssi 20020217;
$VERSION = '1.121';

%IRSSI = (
 authors => 'Matti "qvr" Hiljanen, Mark Sangster "znx"',
 contact => 'matti@hiljanen.com, znxster@gmail.com',
 name => 'wkb',
 description => 'A simple word kickbanner',
 license => 'GPL',
 url => 'http://kutzooi.co.uk/?p=irssi',
);

use strict;
use Irssi;

sub sig_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  my $debug = Irssi::settings_get_bool('wkb_verbose');
  
  return if $nick eq $server->{nick};
  
  $msg =~ s/[\000-\037]//g;
  my $rmsg = $msg;
  $msg = lc($msg);
  
  # bad word
  my @words = split(',', Irssi::settings_get_str('wkb_words'));
  my $nono = 0;
  foreach (@words) { s/ //g; $_ = lc($_); $nono = 1 if $msg =~ /$_/ }
  return unless $nono;
  Irssi::print("wkb: $nick\@$target: found ban word") if $debug;

  # channel?
  my @channels = split(',', Irssi::settings_get_str('wkb_channels'));
  my $react = 0;
  foreach (@channels) { s/ //g; $react = 1 if lc($target) eq lc($_) }
  return unless $react;
  Irssi::print("wkb: $nick\@$target: found watch channel") if $debug;
  
  # god-like person?
  my @gods = split(',', Irssi::settings_get_str('wkb_gods'));
  my $jumala = 0;
  foreach (@gods) { s/ //g; $jumala = 1 if lc($nick) =~ /$_/; }
  return if $jumala;
  Irssi::print("wkb: $nick\@$target: not a god!") if $debug;
  
  # voiced or op'd?
  return if $server->channel_find($target)->nick_find($nick)->{op} ||
    $server->channel_find($target)->nick_find($nick)->{voice};
  
  my $reason = Irssi::settings_get_str('wkb_reason');
  my $kickcounter = Irssi::settings_get_int('wkb_kicked') + 1;
  $server->command("kickban $target $nick $reason #$kickcounter");
  Irssi::settings_set_int('wkb_kicked', $kickcounter);
  Irssi::print("wkb: $nick\@$target: kicked!!!") if $debug;
}

Irssi::signal_add_last('message public', 'sig_public');
Irssi::settings_add_str('wkb', 'wkb_gods', 'znx');
Irssi::settings_add_str( 'wkb', 'wkb_words', 'test.example, working.example');
Irssi::settings_add_str('wkb', 'wkb_channels', '#channel');
Irssi::settings_add_str('wkb', 'wkb_reason', 'SPAMMER');
Irssi::settings_add_int('wkb', 'wkb_kicked', 0);
Irssi::settings_add_bool('wkb', 'wkb_verbose', 0);
