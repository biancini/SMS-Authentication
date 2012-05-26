
# getcredito.pl
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

use strict;

my $DIRSPOOL = `PREFIX/smsgateway/bin/getConfig.pl spool_dir`;

my $argc = @ARGV;
my $filename = "$DIRSPOOL/credito";

open MSGFILE, ">$filename" or die;

print MSGFILE "A\t4916\n";
print MSGFILE "TESTO\tPRE CRE SIN\n";

close MSGFILE;
