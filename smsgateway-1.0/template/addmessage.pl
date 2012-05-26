
# addmessage.pl
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;

my $DIRSPOOL = `PREFIX/smsgateway/bin/getConfig.pl spool_dir`;

my $argc = @ARGV;
my $filename = "$DIRSPOOL/" . `date`;
chomp($filename);

my $i = 0;
while (-e "$filename $i") {
	$i++;
}
$filename = "$filename $i";

if ($argc >= 2) {
	open MSGFILE, ">$filename" or die;

	print MSGFILE "A\t$ARGV[0]\n";
	print MSGFILE "TESTO\t$ARGV[1]\n";

	close MSGFILE;
}
