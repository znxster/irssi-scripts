# first up, major thanks go to Roeland 'Trancer' Nieuwenhuis for his nickban
# script. really this script is more a modification of his to work with a
# regex compare and a whip list.
#
# Thanks go to kitchen for suggestions to improve the script, namely the
# kick counter and ability to alter settings with /set
#
# One flaw exists, the script works globally with the nicks, thus if the
# same nick joins several channels at the same time it will only kick in one

$VERSION = '1.51';
%IRSSI = (
	authors	=> 'Mark Sangster "znx"',
	contact	=> 'znxster@gmail.com',
	name	=> 'wotnotbot',
	description	=> 'A simple nick kicker. Kicks based on a simple regex.',
	license	=> 'GPL v2 or later',
	url	=> 'http://kutzooi.co.uk/?p=irssi'
);

use strict;
use Irssi;


# cleans the recent list
sub clean_recent {
	Irssi::settings_set_str('wotnotbot_recent', 'znx');
	return;
}


# main subroutine that handles the actual kicking of the nicks
sub wotnotbot {
	my($server, $channel, $nick, $address) = @_;
	my $react = 0;
	my $verbose = Irssi::settings_get_bool('wotnotbot_verbose');
	
	# are we op'd (therefore capable of kicking)
	# if the nick is a server then plainly we wont kick!
	return unless $server->channel_find($channel)->{chanop};
	return if $nick eq $server->{nick};
	
	# are we on the right chan?
	my @channels = split(',', Irssi::settings_get_str('wotnotbot_channels'));
	foreach(@channels) {
		s/ //g;
		$react = 1 if lc($channel) eq lc($_);
	}
	return unless $react;

	$react = 0;
	# does the nick match a whippable user nick? 
	if($nick =~ /^[A-Z][a-z]+[0-9][0-9]$/) {
		$react = 1;
		Irssi::print("wnb: $nick is kickable") if($verbose);
	}

	# it this user on the accept list? or recently kicked?
	my $safe = Irssi::settings_get_str('wotnotbot_safe');
	my $recent = Irssi::settings_get_str('wotnotbot_recent');
	my @dkick = split(',', $safe.','.$recent);
	foreach(@dkick) {
		s/ //g;
		if($nick eq $_) {
			$react = 0;
			Irssi::print("wnb: $nick is found to be safe/recent") if($verbose);
		}
	}
	return unless $react;

	my $kickreason = Irssi::settings_get_str('wotnotbot_reason');
	my $kickcounter = Irssi::settings_get_int('wotnotbot_kicked') + 1;
	$server->command("kick $channel $nick $kickreason #$kickcounter");
	Irssi::settings_set_str('wotnotbot_recent', $recent.','.$nick);
	Irssi::settings_set_int('wotnotbot_kicked', $kickcounter);
	Irssi::print("wnb: Kicked $nick on $channel") if($verbose);
}

# install default settings, link subs to signals
Irssi::signal_add_first('message join', 'wotnotbot');
Irssi::signal_add('setup saved', 'clean_recent');

# Recent kicks to ensure that only one kick occurs
# Known safe nicks not to kick
# Channels to watch on
# Total number of kicks!
Irssi::settings_add_str('wotnotbot', 'wotnotbot_recent', 'znx');
Irssi::settings_add_str('wotnotbot', 'wotnotbot_safe', 'znx');
Irssi::settings_add_str('wotnotbot', 'wotnotbot_channels', '#linux-noob, #redhat, #fedora');
Irssi::settings_add_str('wotnotbot', 'wotnotbot_reason', 'wot not bot?');
Irssi::settings_add_int('wotnotbot', 'wotnotbot_kicked', 0);
Irssi::settings_add_bool('wotnotbot', 'wotnotbot_verbose', 0);
