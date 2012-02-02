#
# A simple script for Irssi that will stop you from sending messages to a
# selected channel.
#
# Copyright (C) 2011 Mark Sangster <znxster@gmail.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
# v0.1 - First bash at it.
# v0.2 - Babar added caching
# v0.3 - Was only hiding from client, now actually stopping the message.
# v0.4 - Optional message to indicate the suppressed messages
# v0.5 - Refresh when setup changes
#
# Thanks to shabble, Babar and t-8ch on #irssi@freenode for ideas, testing and
# assistance. Also thanks to the various script authors who release their stuff
# on http://scripts.irssi.org/
#

use Irssi;
use strict;
use warnings;
use 5.009004;
use feature 'state';
use vars qw($VERSION %IRSSI);

$VERSION = '0.5';
%IRSSI = (
	authors		=>	'Mark \'znx\' Sangster',
	contact		=>	'znxster@gmail.com',
	name		=>	'stopmsg.pl',
	description	=>	'Stop messages from sending to a particular channel',
	license		=>	'GPLv3',
	url			=>	'http://znx.no/'
);

# Sort out theme for various messages
Irssi::theme_register([
	'stopmsg_loaded', '%R>>%n %_stopmsg:%_ Version $0 by $1.',
	'stopmsg_warn', '%R>>%n %_stopmsg:%_ Suppressed message to $0',
]);

# Actually stop the message
sub stopmsg_signal {
	my ($server, $target, $msg) = @_;
	if(stopmsg_channel_blocked($target)) {
		Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'stopmsg_warn', $target) if(Irssi::settings_get_bool('stopmsg_warn'));
		Irssi::signal_stop();
	}
}

# Hide the messge from self
sub stopmsg_hide_signal {
	my ($server, $msg, $target) = @_;
	if(stopmsg_channel_blocked($target)) {
		Irssi::signal_stop();
	}
}

# From Babar
sub stopmsg_channel_blocked {
	my ($msgtarget) = @_;
	# should only happen when refresing
	$msgtarget = '' if(!defined($msgtarget));
	state $oldtargets = '';
	state %blockedtargets;
	$msgtarget = lc $msgtarget;
	if((my $list = lc Irssi::settings_get_str("stopmsg_channels")) ne $oldtargets) {
		$oldtargets = lc Irssi::settings_get_str("stopmsg_channels");
		%blockedtargets = map { $_ => 1 } split /,/, $list;
	}
	return exists $blockedtargets{$msgtarget};
}

Irssi::signal_add('server sendmsg', 'stopmsg_signal');
Irssi::signal_add('message own_public', 'stopmsg_hide_signal');
Irssi::signal_add('setup changed', 'stopmsg_channel_blocked');
Irssi::settings_add_str('stopmsg', 'stopmsg_channels', '');
Irssi::settings_add_bool('stopmsg', 'stopmsg_warn', 1);
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'stopmsg_loaded', $VERSION, $IRSSI{authors});
