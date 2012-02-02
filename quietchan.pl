#
# Thanks to aitch@efnet for the idea and with testing/bug finding.
#
# Resend messages at a lower level to assist with hiding them from activity.
# For instance you can silence !top10 from bots.
#
# The masks are like this:
# /set qcmasks nick!user@host#channel%%text to find%%, nick2!*@*#chan2%%this%%
#
# 0.01 (12 Jun 07) - original 
# 0.02 (13 Jun 07) - addition of %%text%%
# 0.03 (14 Jun 07) - fixing an issue with multiple masks " *!*@*", stray space
#
# TODO: Using , or # inside the %%text%% will not work, need to fix that.
# Separate the mask et al into a file and use commands to write to that file
# too.
#

use strict;
use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI);

%IRSSI = (
	authors		=> 'Mark Sangster / znx',
	contact		=> 'mark@linux-noob.com',
	name		=> 'quietchan',
	description	=> 'This will catch and resend messages at a lower level to'.
					'assist with hiding from activity',
	license		=> 'GPLv2 or later',
	url			=> 'http://ircterrorist.org.uk/',
	changed		=> 'Thu Jun 14 15:40:44 BST 2007'
);

$VERSION = '0.04';

#
# map the current pubmsg to my qcpubmsg
# TODO make it look like a proper message. note the excess spaces are for
# alignment, you might need to tweak it to look ok.
#
Irssi::theme_register([
	'qcpubmsg', '%_[%n$0%_]%n <$1> $2',
]);

#
# The routine to check that the mask, channel and text all match, if it does
# then resend the message to the channel but at a different level.
#
sub quietchan {
	my($server, $msg, $nick, $address, $target) = @_;

	# return if this is a server
	return if $nick eq $server->{nick};

	# Right split all the masks at ',' and then at '#'
	my @chanmask = split(',', Irssi::settings_get_str('qcmasks'));
	my $react = 0;

	# test if channel and mask match otherwise return
	foreach(@chanmask) {
		my $text = '';
		my($mask,$chan) = split('#',$_);

		$mask =~ s/ //g;
		$chan =~ s/ //g;

		# do we have a selected text?
		if($chan =~ m/(.*?)\%\%(.*?)\%\%/) {
			$chan = $1;
			$text = $2;
			next if($msg !~ m/$text/);
		}
				
		if(lc($target) eq lc("#$chan")
			&& $server->mask_match_address($mask,$nick,$address)) {
			$react = 1;
			last;
		}
	}
	return unless $react;
	
	# now print the message but switch it to a different level
	# stop the signal to ignore the other at the higher level.
	Irssi::signal_stop();
	$server->window_item_find($target)->printformat(
		MSGLEVEL_NO_ACT,
		'qcpubmsg',
		strftime('%H:%M:%S',localtime),
		$nick,
		$msg
	);
}

Irssi::signal_add('message public','quietchan');
Irssi::settings_add_str('qchan','qcmasks','*!*fabio@*#linux-noob');

# vim:set ts=4 sw=4:
