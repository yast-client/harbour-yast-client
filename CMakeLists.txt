cmake_minimum_required(VERSION 3.13)
project(harbour-yast-client CXX ASM)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

message(STATUS "Building ${CMAKE_PROJECT_NAME} for ${EDITION}")

find_package(Qt5 COMPONENTS Core Network DBus Multimedia Positioning Qml Gui Quick LinguistTools REQUIRED)

include(FindPkgConfig)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL aarch64)
    set(TARGET_ARCHITECTURE aarch64)
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES ^armv7)
    set(TARGET_ARCHITECTURE armv7hl)
elseif( CMAKE_SYSTEM_PROCESSOR STREQUAL i486)
    set(TARGET_ARCHITECTURE i486)
endif()

pkg_search_module(SAILFISH sailfishapp REQUIRED)

set(CMAKE_INSTALL_MESSAGE NEVER)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/share/${CMAKE_PROJECT_NAME}/lib")

# Configure Ccache if available
find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
    message(STATUS "Found ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
else()
    message(STATUS "Could NOT find ccache (this is NOT an error)")
endif()

add_subdirectory(libs/opal/sfpm)

option(HARBOUR_COMPLIANCE "Harbour compliance" OFF)

if(HARBOUR_COMPLIANCE)
    message(STATUS "Harbour compliance enabled")
    add_definitions(-DHARBOUR_COMPLIANCE)
    set(USE_CALLS OFF)
else()
    message(STATUS "Harbour compliance disabled")
    add_definitions(-DNO_HARBOUR_COMPLIANCE)
endif()


add_library(TDLib SHARED IMPORTED)
file(GLOB LIBTDJSON_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/tdlib/${TARGET_ARCHITECTURE}/lib/libtdjson.so.*")
list(GET LIBTDJSON_PATHS 0 LIBTDJSON_PATH)
set_target_properties(TDLib PROPERTIES
    IMPORTED_LOCATION ${LIBTDJSON_PATH}
)

add_subdirectory(yaqtlib)

add_executable(${CMAKE_PROJECT_NAME} src/${CMAKE_PROJECT_NAME}.cpp)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
    APP_VERSION="${APP_VERSION}"
    APP_RELEASE="${APP_RELEASE}"
)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE src)
target_link_libraries(yaqtlib TDLib)
target_link_libraries(${CMAKE_PROJECT_NAME}
    Qt5::Quick
    SortFilterProxyModel
    yaqtlib
)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    src/${CMAKE_PROJECT_NAME}.cpp
    src/voicenoterecorder.cpp
    src/mynotificationmanager.cpp
)

target_sources(yaqtlib PRIVATE
    src/platformapp.cpp
    src/tdlibsecrets.h
)
target_include_directories(yaqtlib PRIVATE src) # FIXME
target_include_directories(yaqtlib PRIVATE
    $<BUILD_INTERFACE:
    ${SAILFISH_INCLUDE_DIRS}>
)
target_link_libraries(yaqtlib ${SAILFISH_LDFLAGS})

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    $<BUILD_INTERFACE:
    ${SAILFISH_INCLUDE_DIRS}>
)
target_link_libraries(${CMAKE_PROJECT_NAME} ${SAILFISH_LDFLAGS})


if(NOT HARBOUR_COMPLIANCE)
    # Calls (TODO: for harbour we could package libraries such as opus in-app and it would work)
    include(libabsl.cmake)

    add_library(libtg_owt STATIC IMPORTED GLOBAL)
    set_target_properties(libtg_owt PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/tg_owt/${TARGET_ARCHITECTURE}/lib/libtg_owt.a"
    )
    set_target_properties(libtg_owt PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_link_libraries(libtg_owt INTERFACE
        ssl
        crypto
        opus
        libabsl
        ${CMAKE_CURRENT_SOURCE_DIR}/tg_owt/${TARGET_ARCHITECTURE}/lib/libvpx.a
        avcodec
        avutil
        pulse
        dl
    )
    target_link_libraries(tgcalls PUBLIC
        libtg_owt
        libabsl
    )
    target_link_libraries(${CMAKE_PROJECT_NAME} libtg_owt)

    target_sources(${CMAKE_PROJECT_NAME} PRIVATE
        src/gstaudiorecorder.cpp
        src/gstaudiorecorder.h
        src/quickavplayer.cpp
        src/quickavplayer.h
    )
    pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0 gstreamer-pbutils-1.0 glib-2.0)
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${GSTREAMER_INCLUDE_DIRS})
    target_link_libraries(${CMAKE_PROJECT_NAME} ${GSTREAMER_LIBRARIES})

    set(QT_AVPLAYER_MULTIMEDIA ON)
    set(QT_AVPLAYER_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/QtAVPlayer/src)
    set(QT_AVPLAYER_DIR ${QT_AVPLAYER_BASE_DIR}/QtAVPlayer)
    include(QtAVPlayer/src/QtAVPlayer/QtAVPlayer.cmake)
    include_directories(${QT_AVPLAYER_BASE_DIR})
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${QtAVPlayer_SOURCES})
    target_link_libraries(${CMAKE_PROJECT_NAME} ${QtAVPlayer_LIBS})
endif()

# Update the translations
# See https://doc.qt.io/archives/qt-5.15/cmake-manual.html
# See https://doc.qt.io/archives/qt-5.15/qtlinguist-cmake-qt5-create-translation.html
FILE(GLOB TsFiles "translations/*.ts")
set(TRANSLATIONS_OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/translations)
file(MAKE_DIRECTORY ${TRANSLATIONS_OUT_DIR})
set_source_files_properties(${TsFiles} PROPERTIES OUTPUT_LOCATION ${TRANSLATIONS_OUT_DIR})
set(Qt5_LUPDATE_EXECUTABLE Qt5::lupdate -no-obsolete)
qt5_create_translation(TRANSLATION_QM_FILES
    "qml/"
    "src/"
    "yaqtlib/src/"
    ${TsFiles})

add_custom_target(translations ALL DEPENDS ${TRANSLATION_QM_FILES})
add_dependencies(${CMAKE_PROJECT_NAME} translations)

install(TARGETS ${CMAKE_PROJECT_NAME}
    RUNTIME DESTINATION bin
)
install(DIRECTORY ${TRANSLATIONS_OUT_DIR}
    DESTINATION share/${CMAKE_PROJECT_NAME}
    FILES_MATCHING PATTERN "*.qm"
)
install(FILES ${CMAKE_PROJECT_NAME}.desktop
    DESTINATION share/applications
)
install(DIRECTORY images
    DESTINATION share/${CMAKE_PROJECT_NAME}
)
install(DIRECTORY assets
    DESTINATION share/${CMAKE_PROJECT_NAME}
)
install(DIRECTORY tdlib/${TARGET_ARCHITECTURE}/lib
    DESTINATION share/${CMAKE_PROJECT_NAME}
)

install(DIRECTORY qml
    DESTINATION share/${CMAKE_PROJECT_NAME}
)

install(FILES icons/86x86/${CMAKE_PROJECT_NAME}.png
    DESTINATION share/icons/hicolor/86x86/apps
)
install(FILES icons/108x108/${CMAKE_PROJECT_NAME}.png
    DESTINATION share/icons/hicolor/108x108/apps
)
install(FILES icons/128x128/${CMAKE_PROJECT_NAME}.png
    DESTINATION share/icons/hicolor/128x128/apps
)
install(FILES icons/172x172/${CMAKE_PROJECT_NAME}.png
    DESTINATION share/icons/hicolor/172x172/apps
)

# Get the other files reachable from the project tree in Qt Creator
# FIXME: this is broken and doesn't work (but files are still editable from qt creator so it's not as bad)
FILE(GLOB_RECURSE DistFiles
    images/*
    qml/*
    icons/*
    assets/*
)
add_custom_target(distfiles
    SOURCES
        ${CMAKE_PROJECT_NAME}.desktop
        rpm/${CMAKE_PROJECT_NAME}.changes.in
        rpm/${CMAKE_PROJECT_NAME}.changes.run.in
        rpm/${CMAKE_PROJECT_NAME}.spec
        ${TsFiles}
        ${DistFiles})

# Tell Qt Creator where the application executable(s) would be located on the
# device.
#
# It is not necessary to list other deployables than executables (runtime
# targets) here. The deployment process of Sailfish OS projects is opaque to
# Qt Creator and the information contained in QtCreatorDeployment.txt is only
# used to locate the executable associated with the active run configuration
# on the device in order to run it.
#
# Search the Qt Creator Manual to learn about the QtCreatorDeployment.txt file
# format.
file(WRITE "${CMAKE_BINARY_DIR}/QtCreatorDeployment.txt"
    "${CMAKE_INSTALL_PREFIX}\n${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}:bin\n")
