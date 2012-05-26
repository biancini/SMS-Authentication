#!/usr/bin/perl -w

# daemon.pl
# Author: Andrea Biancini <andrea.biancini@reti.it> (2004/07/11)
#         Gruppo Reti S.p.A.

# Include needed modules
use lib "/usr/share/smsgateway/modules";
use strict;
use Fatal qw(:void open close opendir readdir);
use Linux::Pid;

use Procedures;
use Configure;

# Do not bufferize input
$| = 1;

# Start the program
my $conf = new Configure();

# Writes PID to pidfile
my $pid = Linux::Pid::_getpid();
my $pidfile = $conf->property("lock_dir") . "/pid";
`echo $pid > $pidfile`;

my $engine = new Procedures(
	'log_dir' => $conf->property("log_dir"),
	'spool_dir' => $conf->property("spool_dir"),
	'sent_dir' => $conf->property("sent_dir"),
	'received_dir' => $conf->property("received_dir"),
	'failed_dir' => $conf->property("failed_dir"),
	'var_dir' => $conf->property("var_dir"),
	'modem_file' => $conf->property("modem_file"),
	'etc_path' => $conf->property("etc_path"),
	'initialize_script' => $conf->property("initialize_script"),
	'send_script' => $conf->property("send_script"),
	'receive_script' => $conf->property("receive_script"),
	'numreceived_script' => $conf->property("numreceived_script"),
	'segnale_script' => $conf->property("segnale_script"),
	'received_action' => $conf->property("received_action"),
	'credito_action' => $conf->property("credito_action"),
	'min_segnale' => $conf->property("min_segnale"),
	'max_segnale' => $conf->property("max_segnale")
);

$engine->infinite_loop();
