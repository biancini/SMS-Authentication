package Modem;

# Modem module
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;
use Log;
use Device::SerialPort;
require Time::HiRes;
Time::HiRes->import(qw(gettimeofday tv_interval usleep));

sub new {
        my $class = shift;
        my %params = @_;

	my $log = new Log(
		'log_dir' => $params{'log_dir'}
	);

        my $this = {
		'log' => $log,
		'initialize_script' => $params{'initialize_script'},
		'modem_file' => $params{'modem_file'},
		'modem_fd' => undef
        };

        bless $this, $class;
        return $this;
}

sub waitfor {
	my $mdm = shift;

	my $timeout = gettimeofday() + shift;
	$mdm->lookclear; # clear buffers
	my $gotit = "";

	# For-cicle to wait for the entire answer from the modem
	for (;;) {
		return unless (defined ($gotit = $mdm->lookfor));
		if ($gotit ne "") {
			my ($found, $end) = $mdm->lastlook;
			return $gotit.$found;
		}
		return if ($mdm->reset_error);
		return if (gettimeofday() > $timeout);
	}
}

sub open_modem {
	my Modem $self = shift;
	bless ($self->{'log'}, "Log");

	$self->{'modem_fd'} = Device::SerialPort->new($self->{'modem_file'}) or
		die "Unable to open modem: $self->{'modem_file'}";

	# Defines the words that terminates the answers of the modem
	$self->{'modem_fd'}->are_match("BUSY","CONNECT",
		       "OK","NO DIALTONE",
		       "ERROR","RING",
		       "NO CARRIER","NO ANSWER");

        my %params;
	my @ritorno = $self->send_command_file($self->{'initialize_script'}, %params);

	($ritorno[0] eq "ok") or
		$self->{'log'}->write_log("W", "Error in initializing modem.");
}

sub close_modem {
	my Modem $self = shift;
	bless ($self->{'modem_fd'}, "Device::SerialPort");

	$self->{'modem_fd'}->close();
	undef $self->{'modem_fd'};
}

sub send_comando {
	my Modem $self = shift;
	bless ($self->{'modem_fd'}, "Device::SerialPort");

	my ($com, $resp) = (shift, shift);
	my @ret_vals = ();
	my @ritorno = ();

	$/ = "\n\n";

	# Deletes trailing \r and \n
	$com =~ s/^[\r\n]+//g; $com =~ s/[\r\n]+$//g;
	$resp =~ s/^[\r\n]+//g; $resp =~ s/[\r\n]+$//g;

	print ("$com\n");
	# Sends the command and reads the answer
	$self->{'modem_fd'}->write("$com\r");
	my $real_resp = waitfor($self->{'modem_fd'}, 4);

	$real_resp =~ s/^[\r\n]+//g; $real_resp =~ s/[\r\n]+$//g;
	$real_resp =~ s/\r\n/\n/g; $real_resp =~ s/\n\n/\n/g;

	# Match the answer with the regular expression defining
	# the expected one and populate @ritorno
	if (@ret_vals = $real_resp =~ m/^($resp)$/) {
		push @ritorno, "ok";

		shift(@ret_vals);
		for (@ret_vals) {
			push @ritorno, $_;
		}
	}
	else {
		print "$real_resp\n";
		push @ritorno, "no";
	}

	return @ritorno;
}

sub send_command_file {
	my Modem $self = shift;
	bless ($self->{'log'}, "Log");

	my $file_template = shift;
	my %params = @_;

	my @ritorno = ("ok");
	my @cmd_ret = ();
	my @rows;
	my ($comm, $rec);

	eval {
		open(CFG, "< " . $file_template);

		# Read the file with the commands.
		# Every command consists of 2 parts:
		# 1. the first row contains the command to be sent to the modem
		# 2. the other lines contain the regular expression with the expected answer
		# Two commands are separated by an empty line
		$/ = "\n\n";
		while (<CFG>) {
			chomp($_);
			@rows = split("\n", $_);
			($comm, $rec) = ("", "");

			# Saves the command in $comm and the expected response in $rec
			foreach (@rows) {
				s/(.*)\#\n/$1\n/;
				if (!/^\#/ && !/^$/) {
					if ($comm eq "") { $comm = $_; }
					else { $rec .= "$_\n"; }
				}
			}
			$rec =~ s/\n$//;
	
			if ($comm ne "") {
				# Replaces the values in symbols within the command
				$comm =~ s/\<\<(.+?)\>\>/$params{$1}/g;
				$comm =~ s/\@\-([0-9]+?)\-\@/chr($1)/eg;

				# Sends the command and reads the answer
				@cmd_ret = $self->send_comando($comm, $rec);
	
				if (shift(@cmd_ret) ne "ok") {
					@ritorno = ("no");
					return @ritorno;
				}

				@ritorno = (@ritorno, @cmd_ret);
			}
		}

		close CFG or
			warn "Error in closing $file_template.";
	};

	if ($@) {
		$self->{'log'}->write_log("W", "Error in reading file $file_template.");
		@ritorno = ("no");
	}

	return @ritorno;
}

1;
