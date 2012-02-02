#
# This script will print hilighted messages into a window called 'hilight'.
# 
# Originally written by Timo Sirainen <tss@iki.fi>
# - Places all hilighted messages into a window called "hilight"
# Amended by Mark Sangster <znxster@gmail.com>
# - Prints a timestamp with the messages
# - Now allows toggling private messages to show or not.
# - Using formats to print (allows basic theme adjustment)
#
# This script is released in the Public Domain.
#
# Basic Usage:
# /window new split
# /window name hilight
# /script load hilightwin.pl
# 
# Suggested usage:
# /window new split
# /window name hilight
# /window size 10
# /statusbar topic type window
# /statusbar topic visible active
# /statusbar window_inact disable
# /script load hilightwin.pl
# 
# Toggle private messages with:
# /toggle hilightwin_showprivmsg
# 

use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 

$VERSION = "0.03";
%IRSSI = (
	authors		=> "Timo \'cras\' Sirainen and Mark \'znx\' Sangster",
    contact		=> "tss\@iki.fi, znxster\@gmail.com", 
    name		=> "hilightwin",
    description	=> "Print hilighted messages to window named \"hilight\"",
    license		=> "Public Domain",
    url			=> "http://irssi.org/",
    changed		=> "Sat Apr  9 18:18:54 BST 2011",
);

# Setup the theme for the script
Irssi::theme_register([
	'hilightwin_loaded', '%R>>%n %_hilightwin:%_ Version $0 by $1.',
	'hilightwin_missing', '%R>>%n %_hilightwin:%_ No window named "hilight" was found, please create it',
	'hilightwin_output', '$0 $1',
	'hilightwin_public_output', '$0 $1: $2',
]);

# Main
sub hilightwin_signal {
	my ($dest, $text, $ignored) = @_;
	$window = Irssi::window_find_name('hilight');

	# Skip if the named window doesn't exist
	if($window) {
		my $opt = MSGLEVEL_HILIGHT;
		$opt = MSGLEVEL_HILIGHT|MSGLEVEL_MSGS if(Irssi::settings_get_bool('hilightwin_showprivmsg'));
		
		if( ($dest->{level} & ($opt)) && ($dest->{level} & MSGLEVEL_NOHILIGHT) == 0 ) {
			$time = strftime( Irssi::settings_get_str('timestamp_format')." ", localtime );
			if($dest->{level} & MSGLEVEL_PUBLIC) {
				$window->printformat(MSGLEVEL_NEVER, 'hilightwin_public_output', $time, $dest->{target}, $text);
			}
			else {
				$window->printformat(MSGLEVEL_NEVER, 'hilightwin_output', $time, $text);
			}
		}
	}
}

# Settings
Irssi::settings_add_bool('hilightwin','hilightwin_showprivmsg',1);

# Signals
Irssi::signal_add('print text', 'hilightwin_signal');

# On load
$window = Irssi::window_find_name('hilight');
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'hilightwin_missing') if (!$window);
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'hilightwin_loaded', $VERSION, $IRSSI{authors});

# vim:set ts=4 sw=4 noet:
