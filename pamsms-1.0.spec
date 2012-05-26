Summary:	The PAM module for the Strong Authentication via SMS.
Name:		pamsms
Version:	1.0
Release:	1
License:	Owned by Gruppo Reti S.p.A.
Group:		System Environment/Base
Source0:	%{name}-%{version}.tar.gz
URL:		http://www.reti.it/
Vendor:		Gruppo Reti S.p.A.
Packager:	Andrea Biancini <andrea.biancini@reti.it>
Distribution:	Red Hat Linux or Fedora Linux
ExclusiveOS:	Linux
BuildRoot:	%{_tmppath}/%{name}-%{version}-root
BuildRequires:	make, gcc, glibc, pam, pam-devel
Requires:	smsgateway, pam

%description
This package contains a PAM module that is able to authenticate a user
using his personal cellular phone.
It sends a unique random token to the user's cell-phone and waits for the
user to write it back.

%prep
%setup -q

%build
%{__make}

%install
%makeinstall

%preun
%{__rm} -f /etc/pam.d/retisms

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README
%config /etc/pam.d/retisms
/usr/lib/security/pam_retisms.so
/usr/bin/pamwrap

%changelog
* Mon Jul 12 2004 Andrea Biancini <andrea.biancini@reti.it>
- Initial build for pamsms
