Summary:	The SMS Web-Service program.
Name:		smsws
Version:	1.0
Release:	1
License:	Owned by Gruppo Reti S.p.A.
Group:		Applications/Communications
Source0:	%{name}-%{version}.tar.gz
URL:		http://www.reti.it/
Vendor:		Gruppo Reti S.p.A.
Packager:	Andrea Biancini <andrea.biancini@reti.it>
Distribution:	Red Hat Linux or Fedora Linux
ExclusiveOS:	Linux
BuildRoot:	%{_tmppath}/%{name}-%{version}-root
BuildRequires:	make
Requires:	pamsms smsgateway perl httpd

%description
This package contains a the SMS Web-Service program.
It is a web-service which creates an interface via web-service to the PAM authentication mechanism,
In particular it permit to authenticate via GSM phone.

%prep
%setup -q

%build
%{__make}

%install
%makeinstall

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# Adjust the files with the right values for hostname and perl parser path
BASE="/var/www"

# html/webservices.xml
cat $BASE/html/webservices.xml | (
        sed "s/HOSTNAME/`hostname`/g"
) > $BASE/html/webservices.xml

# html/StrongAuthenticator/disco.xml
cat $BASE/html/StrongAuthenticator/disco.xml | (
        sed "s/HOSTNAME/`hostname`/g"
) > $BASE/html/StrongAuthenticator/disco.xml

# html/StrongAuthenticator/wsdl.wsdl
cat $BASE/html/StrongAuthenticator/wsdl.wsdl | (
        sed "s/HOSTNAME/`hostname`/g"
) > $BASE/html/StrongAuthenticator/wsdl.wsdl

# cgi-bin/index.pl
cat $BASE/cgi-bin/index.pl | (
        whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin
        sed "s/^//g"
) > $BASE/cgi-bin/index.pl

# cgi-bin/webservice.pl
cat $BASE/cgi-bin/webservice.pl | (
        whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin
        sed "s/^//g"
) > $BASE/cgi-bin/webservice.pl

# cgi-bin/StrongAuthentication.cgi
cat $BASE/cgi-bin/StrongAuthentication.cgi | (
        whereis perl | awk -- '{ print "#!" $2 " -w" }' /dev/stdin
        sed "s/HOSTNAME/`hostname`/g"
) > $BASE/cgi-bin/StrongAuthentication.cgi

# Adjust the httpd.conf file with the lines needed to enable perl CGI
CONFFILE="/etc/httpd/conf/httpd.conf"

if ( cat $CONFFILE | grep '^LoadModule cgi_module' > /dev/null )
then
	echo "CGI-module already loaded."
else
	echo >> $CONFFILE
	echo "LoadModule cgi_module modules/mod_cgi.so" >> $CONFFILE
	echo "Added CGI-module."
fi

if ( cat $CONFFILE | grep '^ScriptAlias /cgi-bin/' > /dev/null )
then
	echo "ScriptAlias /cgi-bin/ already present."
else
	echo >> $CONFFILE
	(
		echo "#"
		echo "# ScriptAlias: This controls which directories contain server scripts."
		echo "# ScriptAliases are essentially the same as Aliases, except that"
		echo "# documents in the realname directory are treated as applications and"
		echo "# run by the server when requested rather than as documents sent to the client."
		echo "# The same rules about trailing \"/\" apply to ScriptAlias directives as to"
		echo "# Alias."
		echo "#"
		echo "ScriptAlias /cgi-bin/ \"/var/www/cgi-bin/\""
	) >> $CONFFILE
	echo "Added ScriptAlias /cgi-bin/."
fi

if ( cat $CONFFILE | grep '^<Directory "/var/www/cgi-bin">' > /dev/null )
then
	echo "Directory /var/www/cgi-bin already present."
else
	echo >> $CONFFILE
	(
		echo "#"
		echo "# \"/var/www/cgi-bin\" should be changed to whatever your ScriptAliased"
		echo "# CGI directory exists, if you have that configured."
		echo "#"
		echo "<Directory \"/var/www/cgi-bin\">"
		echo "    AllowOverride None"
		echo "    Options None"
		echo "    Order allow,deny"
		echo "    Allow from all"
		echo "</Directory>"
	) >> $CONFFILE
	echo "Added directory /var/www/cgi-bin."
fi
exit 0


%files
%defattr(-,root,root)
%doc README
/var/www/html/*
/var/www/cgi-bin/*

%changelog
* Mon Jul 12 2004 Andrea Biancini <andrea.biancini@reti.it>
- Initial build for smsws
