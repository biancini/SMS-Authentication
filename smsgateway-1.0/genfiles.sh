#!/bin/bash

#Generate the prefix path for the substitution
cat curdir | sed 's/\//\\\//g' > del
subst="`cat del`"
echo -n "$1" | sed "s/$subst//g" | sed 's/\//\\\//g' > del
subst="`cat del`"
rm -rf del

#Changes the relative path in all files

# bin/smsgateway
whereis bash | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/smsgateway
cat template/smsgateway | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/smsgateway

# bin/daemon.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/daemon.pl
cat template/daemon.pl | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/daemon.pl

# bin/addmessage.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/addmessage.pl
cat template/addmessage.pl | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/addmessage.pl

# bin/getcredito.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/getcredito.pl
cat template/getcredito.pl | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/getcredito.pl

# bin/getConfig.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/getConfig.pl
cat template/getConfig.pl | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/getConfig.pl

# etc/modem.conf
cat template/modem.conf | sed "s/PREFIX/${subst}/g" > smsgateway/etc/modem.conf

# etc/recact.conf
cat template/recact.conf | sed "s/PREFIX/${subst}/g" > smsgateway/etc/recact.conf

# bin/salvacredito.sh
whereis bash | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > smsgateway/bin/salvacredito.sh
cat template/salvacredito.sh | sed "s/PREFIX/${subst}/g" >> smsgateway/bin/salvacredito.sh
