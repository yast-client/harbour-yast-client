Name:       harbour-yast-client

%define __provides_exclude_from ^%{_datadir}/.*$
%define __requires_exclude ^libtdjson|libgstreamer.*$
%define _binary_payload w6.xzdio

Summary:    YAST Client is a yet another SailfishOS Telegram client
Version:    0.0.0.3
Release:    custom
Group:      Qt/Qt
License:    LICENSE
URL:        http://werkwolf.eu/
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-yast-client.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qml(org.nemomobile.contacts)
BuildRequires:  cmake
BuildRequires:  ninja
BuildRequires:  ccache
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
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  pkgconfig(gstreamer-pbutils-1.0)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  curl
BuildRequires:  gperf
BuildRequires:  desktop-file-utils

# Calls
BuildRequires:  pkgconfig(libpulse)
# Calls (incompatible with harbour)
BuildRequires:  opus-devel
BuildRequires:  libsrtp-devel
BuildRequires:  libvpx-devel
BuildRequires:  ffmpeg-devel

%description
YAST Client is a yet another SailfishOS Telegram client

%prep
%setup -q -n %{name}-%{version}

%build

%cmake -GNinja \
  -DHARBOUR_COMPLIANCE=off

%ninja_build

%install
rm -rf %{buildroot}
%ninja_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
