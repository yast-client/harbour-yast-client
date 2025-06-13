# !!!! FIXME: Right now to build you need to open projects panel in Qt Creator (or do it directly in CMakeLists.txt.user) and replace `-GNinja` with `-GUnix Makefiles` in every build configuration and then select "Re-configure with initial parameters"

cmake_minimum_required(VERSION 3.5)
project(harbour-fernschreiber2 CXX)

find_package (Qt5 COMPONENTS Core Network Qml Gui Quick DBus Sql Multimedia Positioning REQUIRED)
find_package(ZLIB REQUIRED)

find_package(PkgConfig)

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp REQUIRED)

include(ECMFindQmlModule)
include(AsteroidCMakeSettings)
include(AsteroidTranslations)

pkg_check_modules(NEMO_NOTIFICATIONS REQUIRED nemonotifications-qt5)
include_directories(${NEMO_NOTIFICATIONS_INCLUDE_DIRS})

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")

add_definitions(-DQT_STATICPLUGIN)

set(SOURCES
    src/${CMAKE_PROJECT_NAME}.cpp
    src/appsettings.cpp
    src/boolfiltermodel.cpp
    src/chatpermissionfiltermodel.cpp
    src/chatlistmodel.cpp
    src/chatmodel.cpp
    src/contactsmodel.cpp
    src/dbusadaptor.cpp
    src/dbusinterface.cpp
    src/emojisearchworker.cpp
    src/fernschreiberutils.cpp
    src/knownusersmodel.cpp
    src/mceinterface.cpp
    src/namedaction.cpp
    src/notificationmanager.cpp
    src/processlauncher.cpp
    src/stickermanager.cpp
    src/tdlibfile.cpp
    src/tdlibreceiver.cpp
    src/tdlibwrapper.cpp
    src/textfiltermodel.cpp
    src/tgsplugin.cpp

    src/debuglog.h
    src/debuglogjs.h
    src/tdlibsecrets.h
)

# list(APPEND CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_LIBDIR})

add_library(${CMAKE_PROJECT_NAME} ${SOURCES})
target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC
	AsteroidApp)
install(TARGETS ${CMAKE_PROJECT_NAME}
	DESTINATION ${CMAKE_INSTALL_LIBDIR})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/runscript.inc
	${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}
	@ONLY)

generate_desktop(${CMAKE_SOURCE_DIR} ${CMAKE_PROJECT_NAME})

target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC
    Qt5::Quick
    Qt5::DBus
    Qt5::Sql
    Qt5::Multimedia
    Qt5::Positioning
    ZLIB::ZLIB
    ${NEMO_NOTIFICATIONS_LIBRARIES}
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/tdlib/include)
link_directories(${CMAKE_CURRENT_SOURCE_DIR}/tdlib/asteroid/lib)
find_library(TDJSON tdjson HINTS ${CMAKE_CURRENT_SOURCE_DIR}/tdlib/asteroid/lib)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${TDJSON})

install(TARGETS ${CMAKE_PROJECT_NAME}
    RUNTIME DESTINATION bin
)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/tdlib/asteroid/lib/libtdjson.so
    DESTINATION share/${CMAKE_PROJECT_NAME}/lib
)
install(DIRECTORY qml
    DESTINATION share/${CMAKE_PROJECT_NAME}
)
install(DIRECTORY images
    DESTINATION share/${CMAKE_PROJECT_NAME}
)
install(DIRECTORY db
    DESTINATION share/${CMAKE_PROJECT_NAME}
)

set(CMAKE_INSTALL_SO_NO_EXE 0 CACHE INTERNAL "Install .so files with execute permission.")
set(CPACK_GENERATOR "DEB")
string(TOLOWER "${CMAKE_PROJECT_NAME}" lcproject_name)
set(CPACK_DEBIAN_FILE_NAME "${lcproject_name}-${CMAKE_PROJECT_VERSION}.ipk")
set(CPACK_STRIP_FILES TRUE)
if ($ENV{OECORE_TARGET_ARCH} MATCHES "i686")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "qemux86")
else()
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "armv7vehf-neon")
endif()
if (NOT CPACK_PACKAGE_CONTACT) 
    set(CPACK_PACKAGE_CONTACT bogus@example.org)
    message(WARNING "No package contact specified: using ${CPACK_PACKAGE_CONTACT}")
endif()
include(CPack)