Name:       harbour-yast-client

%define __provides_exclude_from ^%{_datadir}/.*$
%define __requires_exclude ^libtdjson|libgstreamer.*$

Summary:    Telegram for Sailfish
Version:    0.3.3
Release:    custom
License:    LICENSE
URL:        http://yast-client.github.io/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qml(org.nemomobile.contacts)
BuildRequires:  cmake
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
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(python3)
BuildRequires:  curl
BuildRequires:  gperf
BuildRequires:  rust
BuildRequires:  cargo
BuildRequires:  desktop-file-utils

%define os_version %(grep -E '^\s*VERSION_ID=' /etc/sailfish-release | sed -E 's/^[^=]*=\s*//;s/\s*$//')
%if "%{?os_version}" == ""
%define os_version 5.1.0.11
%{warn:SailfishOS version could not be determined, assuming %{os_version}}
%endif

%if "%{release}" == "1"
%global is_harbour 1
%else
%global is_harbour 0
%endif

# If building for sfos 5.0
%if %(echo "%{os_version}" | grep -qE '^5\.0(\.|$)' && echo 1 || echo 0)
# Not needed for 5.0, but keep for some older versions just in case
%define _binary_payload w6.xzdio
BuildRequires:  pkgconfig(openssl) < 3.0
%if ! %{is_harbour}
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  pkgconfig(gstreamer-pbutils-1.0)
%endif
%else
BuildRequires:  pkgconfig(openssl) >= 3.0
%endif

%if ! %{is_harbour}
# Calls
BuildRequires:  pkgconfig(libpulse)
# Calls (incompatible with harbour)
BuildRequires:  opus-devel
BuildRequires:  libsrtp-devel
BuildRequires:  libvpx-devel
BuildRequires:  ffmpeg-devel
%endif

%description
YAST Client is a yet another SailfishOS Telegram client.

%prep
%setup -q -n %{name}-%{version}

%build

%cmake \
  -DAPP_VERSION="%{version}" \
  -DAPP_RELEASE="%{release}" \
  -DOS_VERSION="%{os_version}" \
%if %{is_harbour}
  -DHARBOUR_COMPLIANCE=on
%else
  -DHARBOUR_COMPLIANCE=off
%endif

%cmake_build

%install
rm -rf %{buildroot}
%cmake_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
