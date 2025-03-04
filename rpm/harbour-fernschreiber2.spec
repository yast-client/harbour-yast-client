Name:       harbour-fernschreiber2

%define __provides_exclude_from ^%{_datadir}/.*$
%define __requires_exclude ^libtdjson.*$
%define _binary_payload w6.xzdio

Summary:    Fernschreiber is a Telegram client for Sailfish OS
Version:    0.1
Release:    12
Group:      Qt/Qt
License:    LICENSE
URL:        http://werkwolf.eu/
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-fernschreiber2.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   nemo-qml-plugin-contacts-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5DBus)
BuildRequires:  pkgconfig(Qt5Sql)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(Qt5Positioning)
BuildRequires:  pkgconfig(nemonotifications-qt5)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  gperf
BuildRequires:  desktop-file-utils
BuildRequires: make

%description
Fernschreiber is a Telegram client for Sailfish OS

%prep
%setup -q -n %{name}-%{version}

%build

%qmake5

%make_build

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
