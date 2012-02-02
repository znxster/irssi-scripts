# Print hilighted messages & private messages to window named "hilight"
# for irssi 0.7.99 by Timo Sirainen
#
# Modded a tiny tiny tiny bit by znx to stop private messages entering
# the hilighted window. Incremented to 0.01a
# Modded another tiny bit to print a timestamp. 0.01b
use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 
$VERSION = "0.01b";
%IRSSI = (
    authors	=> "Timo \'cras\' Sirainen",
    contact	=> "tss\@iki.fi", 
    name	=> "hilightwin",
    description	=> "Print hilighted messages to window named \"hilight\"",
    license	=> "Public Domain",
    url		=> "http://irssi.org/",
    changed	=> "Thu Oct 26 22:34:15 BST 2006"
);

sub sig_printtext {
	my ($dest, $text, $stripped) = @_;
	
	if(
		($dest->{level} & (MSGLEVEL_HILIGHT)) &&
		($dest->{level} & MSGLEVEL_NOHILIGHT) == 0
	) {
		$window = Irssi::window_find_name('hilight');

		if ($dest->{level} & MSGLEVEL_PUBLIC) {
			$text = $dest->{target}.": ".$text;
		}
		$text = strftime(
			Irssi::settings_get_str('timestamp_format')." ",
			localtime
		).$text;
		$text =~ s/  //g;
		$window->print($text, MSGLEVEL_NEVER) if ($window);
	}
}

$window = Irssi::window_find_name('hilight');
Irssi::print("Create a window named 'hilight'") if (!$window);

Irssi::signal_add('print text', 'sig_printtext');

# vim:set ts=4 sw=4 noet:
