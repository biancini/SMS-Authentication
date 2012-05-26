#!/usr/bin/perl -w

# getConfig.pl
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;
use lib "/usr/share/smsgateway/modules";
use Configure;

my $conf = new Configure();
my $arg = "";

foreach $arg (@ARGV) {
	print $conf->property($arg) . "\n";
}
