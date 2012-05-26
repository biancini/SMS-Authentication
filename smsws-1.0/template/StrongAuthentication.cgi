
# StronAuth web service
# Written by Andrea Biancini <andrea.biancini@reti.it> 2004/06/28

use strict;
use SOAP::Transport::HTTP;

# Dispatches the SOAP messages to the module StrongAuth
SOAP::Transport::HTTP::CGI
	-> dispatch_to('StrongAuth')
	-> handle;

# Package StrongAuth which implements the web-service
package StrongAuth;

# This method is invoked to start the authentication process
sub startAuth {
	my StrongAuth $self = shift;
	my $username = shift;

	# Generate the sessionID which identifies uniquely the current authentication session
	my $key = int(rand(1000000));
	my $sessionID = "$username" . "$key";
	$sessionID = crypt($sessionID, $key);
	$sessionID =~ s/\//_/g;

	my $pid = fork();
	if ($pid == 0) {
		# The child-process starts the pamwrap module which works in background
		# and tryies to authenticate the user.
		# The method to comunicate with this process is via the named pipes which it creates.
		my $status = system("/usr/bin/pamwrap $sessionID $username");

		while (-e "/tmp/${sessionID}" && -e "/tmp/${sessionID}_tipo" && -e "/tmp/${sessionID}_testo") {
			sleep(1);
		}

		# When the process exits write in the named pipes the outcome of the authentication
		`echo -n "$username" > /tmp/${sessionID}`;
		`echo -n "ENDAUTH" > /tmp/${sessionID}_tipo`;

		if ($status == 0) {
			`echo -n "ok" > /tmp/${sessionID}_testo`;
		}
		else {
			`echo -n "no" > /tmp/${sessionID}_testo`;
		}

		# Whait two minutes and then deletes the files used to comunicate with the webservice.
		sleep(120);

		unlink("/tmp/${sessionID}");
		unlink("/tmp/${sessionID}_tipo");
		unlink("/tmp/${sessionID}_testo");
		unlink("/tmp/${sessionID}_risposta");

		exit(0);
	}

	sleep(1);
	return $sessionID;
}

# This method is invoked to check if the authentication process have to comunicate a question
# to the user in order to proceed in the process.
sub getDomanda {
	my StrongAuth $self = shift;
	my $username = shift;
	my $sessionID = shift;

	while (!(-e "/tmp/${sessionID}" && -e "/tmp/${sessionID}_tipo" && -e "/tmp/${sessionID}_testo")) {
		sleep(1);
	}
	sleep(1);

	if ("$username" ne `cat /tmp/${sessionID}`) {
		return ("ERROR", "You are not allowed to interact with this session.");
	}

	# Read the type and the text of the question and returns these values
	my $tipo = `cat /tmp/${sessionID}_tipo`;
	my $testo = `cat /tmp/${sessionID}_testo`;

	unlink("/tmp/${sessionID}_tipo");
	unlink("/tmp/${sessionID}_testo");

	my %ritorno = (
		"tipo" => $tipo,
		"testo" => $testo
	);
	return \%ritorno;
}

# This method is invoked to comunicate the answer to the last question read.
sub sendRisposta {
	my StrongAuth $self = shift;
	my $username = shift;
	my $sessionID = shift;
	my $risposta = shift;

	if ("$username" ne `cat /tmp/${sessionID}`) {
		return ("ERROR", "You are not allowed to interact with this session.");
	}

	while (!(-e "/tmp/${sessionID}_risposta")) {
		sleep(1);
	}
	sleep(1);

	`echo "$risposta" > /tmp/${sessionID}_risposta`;
}
