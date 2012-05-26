#!/bin/bash

# html/webservices.xml
cat template/webservices.xml | sed "s/HOSTNAME/`hostname`/g" > html/webservices.xml

# html/StrongAuthenticator/disco.xml
cat template/disco.xml | sed "s/HOSTNAME/`hostname`/g" > html/StrongAuthenticator/disco.xml

# html/StrongAuthenticator/wsdl.wsdl
cat template/wsdl.wsdl | sed "s/HOSTNAME/`hostname`/g" > html/StrongAuthenticator/wsdl.wsdl

# cgi-bin/index.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > cgi-bin/index.pl
cat template/index.pl >> cgi-bin/index.pl

# cgi-bin/webservice.pl
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > cgi-bin/webservice.pl
cat template/webservice.pl >> cgi-bin/webservice.pl

# cgi-bin/StrongAuthentication.cgi
whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin > cgi-bin/StrongAuthentication.cgi
cat template/StrongAuthentication.cgi | sed "s/HOSTNAME/`hostname`/g" >> cgi-bin/StrongAuthentication.cgi
