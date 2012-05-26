package Procedures;

# Procedures module
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;
use Modem;
use Log;
use Time::localtime;

sub new {
	my $class = shift;
	my %params = @_;

	# Initializes the three script's path controlling if they are
	# relative or absolute
	my ($ini_scr, $sen_scr, $rec_scr, $nrec_scr, $segn_scr, $rec_act, $cred_act);

	if ($params{'initialize_script'} =~ /^\//) { $ini_scr = $params{'initialize_script'}; }
	else {$ini_scr = $params{'etc_path'} . $params{'initialize_script'}; }

	if ($params{'send_script'} =~ /^\//) { $sen_scr = $params{'send_script'}; }
	else {$sen_scr = $params{'etc_path'} . $params{'send_script'}; }

	if ($params{'receive_script'} =~ /^\//) { $rec_scr = $params{'reveice_script'}; }
	else {$rec_scr = $params{'etc_path'} . $params{'receive_script'}; }

	if ($params{'numreceived_script'} =~ /^\//) { $nrec_scr = $params{'numreveiced_script'}; }
	else {$nrec_scr = $params{'etc_path'} . $params{'numreceived_script'}; }

	if ($params{'segnale_script'} =~ /^\//) { $segn_scr = $params{'segnale_script'}; }
	else {$segn_scr = $params{'etc_path'} . $params{'segnale_script'}; }

	if ($params{'received_action'} =~ /^\//) { $rec_act = $params{'received_action'}; }
	else {$rec_act = $params{'etc_path'} . $params{'received_action'}; }

	if ($params{'credito_action'} =~ /^\//) { $cred_act = $params{'credito_action'}; }
	else {$cred_act = $params{'bin_path'} . $params{'credito_action'}; }

	my $modem = new Modem(
		'initialize_script' => $ini_scr,
		'modem_file' => $params{'modem_file'}
	);

	my $log = new Log(
		'log_dir' => $params{'log_dir'}
	);

	my $this = {
		'log' => $log,
		'modem' => $modem,
		'spool_dir' => $params{'spool_dir'},
		'sent_dir' => $params{'sent_dir'},
		'received_dir' => $params{'received_dir'},
		'failed_dir' => $params{'failed_dir'},
		'var_dir' => $params{'var_dir'},
		'initialize_script' => $ini_scr,
		'send_script' => $sen_scr,
		'receive_script' => $rec_scr,
		'numreceived_script' => $nrec_scr,
		'segnale_script' => $segn_scr,
		'received_action' => $rec_act,
		'credito_action' => $cred_act,
		'min_segnale' => $params{'min_segnale'},
		'max_segnale' => $params{'max_segnale'}
	};

	bless $this, $class;
	return $this;
}

sub check_status() {
	my Procedures $self = shift;
	bless ($self->{'log'}, "Log");

	$self->check_segnale();

	my $curtime;
	chomp($curtime = `date +"%Y%m%d%H%M"`);

	if (-e $self->{'var_dir'} . "/credito.txt") {
		eval {
			my ($firstline, $lastline) = ("", "");

			open(CREFILE, "<" . $self->{'var_dir'} . "/credito.txt");

			$/ = "\n";
			while(<CREFILE>) {
				if ($firstline eq "") {
					$firstline = $_;
				}

				$lastline = $_;
			}

			close CREFILE or
				warn "Error in closing " . $self->{'var_dir'} . "/credito.txt.";

			open(CREFILE, ">" . $self->{'var_dir'} . "/credito.txt");

                        print CREFILE "$firstline\n";
                        print CREFILE "$curtime";

                        close CREFILE or
                                warn "Error in closing " . $self->{'var_dir'} . "/credito.txt.";

			if (int($curtime) - 15 > int($lastline)) {
				$self->invia_richiesta_credito();
			}
		};

		if ($@) {
                        $self->{'log'}->write_log("W", "Unable to create " . $self->{'var_dir'} . "/credito.txt.");
                }
	}
	else {
		eval {
			open(CREFILE, ">" . $self->{'var_dir'} . "/credito.txt");

			print CREFILE "\n";
			print CREFILE "$curtime";

			close CREFILE or
				warn "Error in closing " . $self->{'var_dir'} . "/credito.txt.";
		};

		if ($@) {
			$self->{'log'}->write_log("W", "Unable to create " . $self->{'var_dir'} . "/credito.txt.");
		}

		$self->invia_richiesta_credito();
	}
}

sub invia_richiesta_credito() {
	my Procedures $self = shift;
	my $command = $self->{'credito_action'};

	`$command`
}

sub check_segnale() {
	my Procedures $self = shift;
        my %params = ();

        bless ($self->{'modem'}, "Modem");
        bless ($self->{'log'}, "Log");

        # Check the status of the line send_command_file with appropriate parameters
        my @ritorno;
        @ritorno = $self->{'modem'}->send_command_file($self->{'segnale_script'}, %params);

        # Log the success or insucecss of the operation
        if ($ritorno[0] eq "ok") {
		my ($min, $max, $val);

		if (int($self->{'min_segnale'}) <= int($self->{'max_segnale'})) {
			$min = 0;
			$max = int($self->{'max_segnale'}) - int($self->{'min_segnale'});
			$val = int($ritorno[1]) - int($self->{'min_segnale'});
		}
		else {
			$min = 0;
			$max = int($self->{'min_segnale'}) - int($self->{'max_segnale'});
			$val = int($ritorno[1]) - int($self->{'max_segnale'});
		}

		my $perc = $val * 100 / $max;

		eval {
			open(SEGFILE, ">" . $self->{'var_dir'} . "/segnale.txt");
			print SEGFILE "GSM Signal: " . $perc . "%.\n";
			close SEGFILE ||
				warn "Error in closing " . $self->{'var_dir'} . "/segnale.txt.";
		};

		if ($@) {
			warn "Error in writing " . $self->{'var_dir'} . "/segnale.txt..";
		}
		
		if ($perc < 5) {
	                $self->{'log'}->write_log("W", "Signal low.");
		}
        }
        else {
                $self->{'log'}->write_log("W", "Could not check signal.");
        }

        return @ritorno;
}

sub check_for_sending() {
	my Procedures $self = shift;
	bless ($self->{'log'}, "Log");

	my %params;
	my @cur_val;
	my @ritorno;

	my $newfilename;
	my $i;

	eval {
		opendir(DIRSPOOL, $self->{'spool_dir'});

		foreach my $filename (sort readdir(DIRSPOOL)) {
			%params = ();
			@cur_val = ();

			# Reads all the files in the spool directory and try to send them
			# as an SMS message
			if ($filename ne "." && $filename ne "..") {
				eval {
					# Open the files and populate the %params with all the values
					# contained in the file.

					my $ntry = 0;
					open(CURFILE, "<" . $self->{'spool_dir'} . "/" . $filename);

					$/ = "\n";
					while (<CURFILE>) {
						@cur_val = m/^(.+?)\s+(.+)/;
						$params{$cur_val[0]} = $cur_val[1];
						if ($cur_val[0] eq "NTRY") {
							$ntry = 1;
						}
					}
					if ($ntry != 1) {
						$params{'NTRY'} = "0";
					}

					close CURFILE;
				};

				# Logs eventual errors
				if ($@) {
					$self->{'log'}->write_log("W", "Error in reading file $self->{'spool_dir'}/$filename");
				}

				chomp($newfilename = `date +"%y-%m-%d,%H:%M:%S+01,"`);
				$i = 0;

				# Try to send the SMS message described by the file
				@ritorno = $self->send_message(%params);
				if ($ritorno[0] eq "ok") {
					# If the message was sent correctly save in $newname
					# the location of the file in sent folder
					while (-e $self->{'sent_dir'} . "/" . $newfilename . $i) {
						$i++;
					}
					$newfilename = $self->{'sent_dir'} . "/" . $newfilename . $i;
				}
				else {
					# If the message was NOT sent correctly watch if the message
					# was tried to be sent 5 times and act accordingly
					if (int($params{'NTRY'}) < 5) {
						# Add 1 to the NTRY option
						$self->add_num_try($self->{'spool_dir'} . "/" . $filename, %params);

						$newfilename = "";
					}
					else {
						# If the message was tried to be sent 5 times save in $newname
						# the location of the file in failed folder
						while (-e $self->{'failed_dir'} . "/" . $newfilename . $i) {
        		                                $i++;
                		                }
						$newfilename = $self->{'failed_dir'} . "/" . $newfilename . $i;
					}
				}

				# Move the file to the right location
				eval {
					if ($newfilename ne "") {
						rename $self->{'spool_dir'} . "/" . $filename, $newfilename;	
					}
				};

				# Logs eventual errors
				if ($@) {
					$self->{'log'}->write_log("W", "Error in renaming message file $self->{'spool_dir'}/$filename.");

					unlink $self->{'spool_dir'} . "/" . $filename or
						$self->{'log'}->write_log("W", "Error in deleting message file $self->{'spool_dir'}/$filename.");
				}
			}
		}

		closedir DIRSPOOL;
	};

	# Logs eventual errors
	if ($@) {
		$self->{'log'}->write_log("W", "Error in threating directory $self->{'spool_dir'}.");
	}
}

sub add_num_try() {
	my Procedures $self = shift;
	bless ($self->{'log'}, "Log");

	# Add 1 to the NTRY in the message to send
	my $filename = shift;
	my %params = @_;

	eval {
		open(CURMSG, ">$filename");

		foreach my $key (keys %params) {
			if ($key eq "NTRY") {
				# Adds one to the NTRY value in %params
				print CURMSG "NTRY\t";
				print CURMSG int($params{$key}) + 1;
			}
			else {
				# Copy all the other values in %params unaltered
				print CURMSG "$key\t";
				print CURMSG $params{$key};
			}

			print CURMSG "\n";
		}

		close CURMSG or
			$self->{'log'}->write_log("W", "Error in writing message file $filename.");
	};

	# Logs eventual errors
	if ($@) {
		$self->{'log'}->write_log("W", "Error in adding 1 to NTRY on message file $filename.");
	}
}

sub check_for_receiving() {
	my Procedures $self = shift;
	bless ($self->{'log'}, "Log");

	# Checks for received messages
	my @ritorno = $self->read_received();

	if (shift(@ritorno) eq "ok") {
		my ($da, $data, $testo);
		my $filename = $self->{'received_dir'} . "/";
		my $i;

		# Save the received messages in the received folder
		while (@ritorno) {
			($da, $data, $testo) = (shift(@ritorno), shift(@ritorno), shift(@ritorno));
			$i = 0;

			# Execute an action in response to received SMS
			$self->exec_action($da, $data, $testo);

			$data =~ s/\//-/g;
			while (-e $filename . $data . "," . $i) {
				$i++;
			}

			eval {
				open REC, ">" . $filename . $data . "," . $i;

				print REC "DA:\t$da\n";
				print REC "DATA:\t$data\n";
				print REC "TESTO:\t$testo\n";

				close REC or
					warn "Error in closing file $filename$data,$i.";
			};

			# Log eventual errors
			if ($@) {
				$self->{'log'}->write_log("W", "Error in reading file $filename$data,$i.");
			}
		}
	}
}

sub exec_action() {
	my Procedures $self = shift;
	bless ($self->{'log'}, "Log");

	my ($da, $data, $testo) = (shift, shift, shift);
	my @rows;

	$testo =~ s/"/\\"/g;

	eval {
		open ACT, "<" . $self->{'received_action'};

		$/ ="\n\n";
		while (<ACT>) {
			chomp($_);
			@rows = split("\n", $_);

			if ($da =~ m/^$rows[0]$/ && $data =~ m/^$rows[1]$/ && $testo =~ m/^$rows[2]$/) {
				`$rows[3] \"$da\" \"$data\" \"$testo\"`;
			}
		}

		close ACT or
			warn "Error in closing file $self->{'received_action'}.";
	};

	# Log eventual errors
	if ($@) {
		$self->{'log'}->write_log("W", "Error in executing operation on received message.");
	}
}

sub one_loop() {
	my Procedures $self = shift;

	$self->check_status();
	$self->check_for_sending();
	$self->check_for_receiving();
}

sub infinite_loop() {
	my Procedures $self = shift;
	bless ($self->{'modem'}, "Modem");

	$self->{'modem'}->open_modem();

	while (1) {
		$self->one_loop();
		sleep(10);
	}

	$self->{'modem'}->close_modem();
}

sub send_message() {
	my Procedures $self = shift;
	my %params = @_;

	bless ($self->{'modem'}, "Modem");
	bless ($self->{'log'}, "Log");

	# Send the message calling send_command_file with appropriate parameters
	my @ritorno;
	@ritorno = $self->{'modem'}->send_command_file($self->{'send_script'}, %params);

	# Log the success or insucecss of the operation
	if ($ritorno[0] eq "ok") {
		$self->{'log'}->write_log("I", "Message sent to: $params{'A'}.");
	}
	else {
		$self->{'log'}->write_log("E", "Message not sent to: $params{'A'}.");
	}

	return @ritorno;
}

sub read_received() {
	my Procedures $self = shift;
	bless ($self->{'modem'}, "Modem");
	bless ($self->{'log'}, "Log");

	# Read the number of the received messages and the total number of spaces in SIM memory
	my @ritorno = ("ok");
	my @resp;
	my %params;
	@resp = $self->{'modem'}->send_command_file($self->{'numreceived_script'}, %params);

	if ($resp[0] ne "ok") {
		@ritorno = ("no");
		return @ritorno;
	}

	my ($num_rec, $num_tot) = ($resp[1], $resp[2]);
	my $i = 1;
	my $read = 0;

	# Reads all the spaces in the SIM memory to get the received message until the total number
	# of received messages is not reached
	while ($i <= $num_tot && $read < $num_rec) {
		%params = (
			'I' => $i
		);
		@resp = $self->{'modem'}->send_command_file($self->{'receive_script'}, %params);

		if (shift(@resp) eq "ok") {
			$self->{'log'}->write_log("I", "Message received from: $resp[0].");
			@ritorno = (@ritorno, @resp);

			$read++;
		}
		$i++;
	}

	return @ritorno;
}

1;
