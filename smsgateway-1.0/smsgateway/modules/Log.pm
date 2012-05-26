package Log;

# Log module
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;
use POSIX qw(strftime);

sub new {
	my $class = shift;
	my %params = @_;

	my $this = {
		'log_dir' => $params{'log_dir'}
	};

	bless $this, $class;
	return $this;
}

sub write_log {
	my Log $self = shift;
	my $date; my $time;

	$date = strftime "%Y%m%d", localtime;
	$time = strftime "%H:%M:%S", localtime;

	my $logfile = "$self->{'log_dir'}/$date.log";
	my ($type, $message);
	eval {
		# Open the log file and writes the log string to it
		open(LOG, ">> " . $logfile);
		($type, $message) = (shift, shift);

		#print LOG "$time [$type] " . caller() . " $message\n";
		print LOG "$time [$type] $message\n";

		close LOG or warn "Error in closing $logfile.";
	};

	if ($@) {
		# If there where some error on opening or writing log files
		# echo a warning and print the log line on stderr
		warn "Error on log file $logfile.";
		warn "$time [$type] $message";
	}
}

1;
