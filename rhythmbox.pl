#
# A simple script for Irssi that will allow the user to control and display the
# current playing song.
#
# Copyright (C) 2010 Mark Sangster <znxster@gmail.com>
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
# Thanks go to the various scripts on http://scripts.irssi.org/, in particular
# Geert Hauwaerts and Shawn Fogle.
#
# It should be noted that the DBUS check is ugly and that this will only play
# enqueued music. So if the queue is empty you will play nothing. Next step is
# to produce a method of enqueuing music.
#

use Irssi;
use Irssi::TextUI;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.2';
%IRSSI = (
	authors		=>	'Mark \'znx\' Sangster',
	contact		=>	'znxster@gmail.com',
	name		=>	'rhythmbox.pl',
	description	=>	'Controls and retrieves song information from rhythmbox',
	license		=>	'GPLv3',
	commands	=>	'rb',
	url			=>	'http://znx.no/'
);

# Sort out theme for various messages
Irssi::theme_register([
	'rb_loaded', '%R>>%n %_Rhythmbox:%_ Version $0 by $1.',
	'rb_printplaying', '%R>>%n %_Rhythmbox:%_ $0',
	'rb_printvolume', '%R>>%n %_Rhythmbox:%_ $0',
	'rb_unkcmd', '%R>>%n %_Rhythmbox:%_ Unknown command',
	'rb_noprev', '%R>>%n %_Rhythmbox:%_ No previous song',
	'rb_volwrong', '%R>>%n %_Rhythmbox:%_ Incorrect volume, please select between 0 and 1.',
	'rb_notrunning', '%R>>%n %_Rhythmbox:%_ Not running! Please start Rhythmbox',
]);

# Sort out some defaults
Irssi::settings_add_str('rhythmbox','rhythmbox_format','\'%ta - %at - %tt - "(%td)"\'');

# Hrmm must be a better way
my $is_running = 0;

## 'rhythmbox-client' comands not used by script.
# --no-start   (Don't start a new instance of Rhythmbox)
# --no-present (Don't present an existing Rhythmbox window)
# --hide       (Hide the Rhythmbox window)
# --notify     (Show notification of the playing song)
# --set-rating               Set the rating of the current song
# --play-uri=URI to play     Play a specified URI, importing it if necessary
# --enqueue                  Add specified tracks to the play queue

#
# These are send and forget commands first, no error handling though.
#

# --clear-queue (Empty the play queue before adding new tracks)
sub ClearQueue { Irssi::command("exec - rhythmbox-client --clear-queue"); }

# --quit (Quit Rhythmbox)
sub Quit { Irssi::command("exec - rhythmbox-client --quit"); }

# --play-pause (Toggle play/pause mode)
sub PlayPause {
	Irssi::command("exec - rhythmbox-client --play-pause");
	&PrintPlaying;
}

# --play (Resume playback if currently paused)
sub Play {
	Irssi::command("exec - rhythmbox-client --play");
	&PrintPlaying;
}

# --pause (Pause playback if currently playing)
sub Pause { Irssi::command("exec - rhythmbox-client --pause"); }

# --volume-up (Increase the playback volume)
sub VolumeUp {
	Irssi::command("exec - rhythmbox-client --volume-up");
	&PrintVolume;
}

# --volume-down (Decrease the playback volume)
sub VolumeDown {
	Irssi::command("exec - rhythmbox-client --volume-down");
	&PrintVolume;
}

# --mute (Mute playback)
sub Mute { Irssi::command("exec - rhythmbox-client --mute"); }

# --unmute (Unmute playback)
# TODO: Doesn't seem to work?
sub UnMute {
	Irssi::command("exec - rhythmbox-client --unmute");
}

# --next (Jump to next song)
sub Next {
	Irssi::command("exec - rhythmbox-client --next");
	&PrintPlaying;
}

# --previous (Jump to previous song)
sub Previous {
	# Need to capture this because previous cannot always go back
	my $out = `rhythmbox-client --previous 2>&1`;
	chop $out;
	if($out =~ /No previous song/) {
		Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_noprev');
	}
	else {
		&PrintPlaying;
	}
}

# --print-playing (Print the title and artist of the playing song)
# --print-playing-format (Print formatted details of the song)
sub PrintPlaying {
	my $fmt = Irssi::settings_get_str('rhythmbox_format');
	my $out = `rhythmbox-client --print-playing-format $fmt`;
	chop $out;
	Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_printplaying', $out);
}

# --print-volume (Print the current playback volume)
sub PrintVolume {
	my $out = `rhythmbox-client --print-volume`;
	chop $out;
	Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_printvolume', $out);
}

# --set-volume (Set the playback volume)
sub SetVolume {
	my $data = $_[0];
	if($data gt 0) {
		Irssi::command("exec - rhythmbox-client --set-volume $data");
	}
	else {
		Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_volwrong');
	}
}

# If wrong command called
sub default {
	Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_unkcmd');
}

# Get and set the DBUS environmental variable.
sub DBUS {
	my $pidof = `pidof rhythmbox`;
	chomp $pidof;
	local $/ = "\0";
	open FILE, "/proc/$pidof/environ";
	while(<FILE>) {
		if($_ =~ /DBUS/) {
			$_ =~ s/^.*?=//;
			$ENV{'DBUS_SESSION_BUS_ADDRESS'}=$_;
			$is_running = 1;
			return;
		}
	}
	close FILE;
	# If we get this far Rhythmbox isn't playing?
	Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_notrunning');
	$is_running = 0;
}

# Sorts out which command we want
sub MainHandler {
	if(!$is_running) {
		&DBUS();
		return;
	}
	my ($data, $server, $witem) = @_;
	my @data = split / /, $data;
	if($data[0] eq 'pvol') { &PrintVolume(); }
	elsif($data[0] eq 'pp') { &PlayPause(); }
	elsif($data[0] eq 'now') { &PrintPlaying(); }
	elsif($data[0] eq 'prev') { &Previous(); }
	elsif($data[0] eq 'next') { &Next(); }
	elsif($data[0] eq 'mute') { &Mute(); }
	elsif($data[0] eq 'unmute') { &UnMute(); }
	elsif($data[0] eq 'pause') { &Pause(); }
	elsif($data[0] eq 'play') { &Play(); }
	elsif($data[0] eq 'volup') { &VolumeUp(); }
	elsif($data[0] eq 'voldown') { &VolumeDown(); }
	elsif($data[0] eq 'quit') { &Quit(); }
	elsif($data[0] eq 'clrq') { &ClearQueue(); }
	elsif($data[0] eq 'dbus') { &DBUS(); }
	else { &default(); }
}

# The two main commands
Irssi::command_bind('rb', 'MainHandler');
Irssi::command_bind('rhythmbox', 'MainHandler');

Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'rb_loaded', $VERSION, $IRSSI{authors});
