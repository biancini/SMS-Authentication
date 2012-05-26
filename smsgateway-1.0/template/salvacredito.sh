#!/bin/bash

NOMEFILE="`PREFIX/smsgateway/bin/getConfig.pl var_dir`/credito.txt";

echo $3 > $NOMEFILE
date +"%Y%m%d%H%M" >> $NOMEFILE
