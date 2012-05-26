package Configure;

# Configure module
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;

sub new {
	my $class = shift;
	my $this = {};
	$this->{'config_array'} = {read_configs()};

	bless $this, $class;
	return $this;
}

sub find_config_path {
	# Search the configuration file (modem.conf) in the path list
	# contained in @search_path
	my @search_path = qw(. ./etc /etc/modem);

	foreach (@search_path) {
		if ( -e "$_/modem.conf" ) {
			return "$_/";
		}
	}

	warn "Could not find configuration file.";
}

sub read_configs {
	# Open the config file and populate an associative array
	# with the values in the file

        my %local_array;

	eval {
		open(CFG, "< " . find_config_path() . "modem.conf");
		$local_array{'etc_path'} = find_config_path();

		while (<CFG>) {
			next if /^#/; # Discard comments
			next unless /^(\w+)\s*=\s*\"(.*)\".*/; # Ignore bad syntax, empty lines
			$local_array{$1} = $2;
		}
		
		close CFG or warn "Error in closing " . find_config_path() . "modem.conf";
	};

	if ($@) {
		die "Error in opening configuration file. Could not continue without parameters."
	}

        return %local_array;
}

sub property {
	my Configure $self = shift;
	my %local_array = %{$self->{'config_array'}};
	my ($property_name) = shift;

	return $local_array{$property_name};
}

1;
