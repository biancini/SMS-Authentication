Summary:	The SMS Gateway program.
Name:		smsgateway
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
Requires:	perl sed gawk bash

%description
This package contains a the SMS Gateway program.
It is able to send and receive SMS messages through the GSM modem connected
to the serial port..

%prep
%setup -q

%build
%{__make}

%install
echo "%{_tmppath}/%{name}-%{version}-root" > curdir
%makeinstall
%{__rm} -rf curdir

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#%{__mv} -f /usr/share/smsgateway/bin/smsgateway /etc/init.d/smsgateway
chkconfig --add smsgateway
exit 0

%preun
chkconfig --del smsgateway
exit 0

%files
%defattr(-,root,root)
%doc README
%config /etc/modem/*
/usr/share/smsgateway/*
%attr(0755,root,root) /etc/init.d/smsgateway
%attr(0777,root,root) /usr/share/smsgateway/spool

%changelog
* Mon Jul 12 2004 Andrea Biancini <andrea.biancini@reti.it>
- Initial build for smsgateway
