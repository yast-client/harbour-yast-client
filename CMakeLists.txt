cmake_minimum_required(VERSION 3.13)

set(EDITION "sailfish" CACHE STRING "The version of the app to build. Must be one of: sailfish, asteroid.")

if (EDITION STREQUAL "sailfish")
    project(harbour-fernschreiber2 CXX ASM)
    set(EDITION_SAILFISH TRUE)
elseif (EDITION STREQUAL "asteroid")
    project(asteroid-fernschreiber2 CXX ASM)
    set(EDITION_ASTEROID TRUE)
else()
    message(FATAL_ERROR "Invalid edition '${EDITION}'. Must be one of: sailfish, asteroid.")
endif()

message(STATUS "Building ${CMAKE_PROJECT_NAME} for ${EDITION}")

find_package(Qt5 COMPONENTS Core Network DBus Multimedia Positioning Qml Gui Quick LinguistTools REQUIRED)

include(FindPkgConfig)
pkg_search_module(NEMONOTIFICATIONS nemonotifications-qt5 REQUIRED)
pkg_search_module(ZLIB zlib REQUIRED)

if (EDITION_SAILFISH)
    pkg_search_module(SAILFISH sailfishapp REQUIRED)
elseif (EDITION_ASTEROID)
    # FIXME: surely something from this large list isn't needed
    find_package(ECM REQUIRED NO_MODULE)
    find_package(AsteroidApp REQUIRED)

    set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

    include(FeatureSummary)
    include(GNUInstallDirs)
    include(ECMFindQmlModule)
    include(AsteroidCMakeSettings)
    include(AsteroidTranslations)
endif()

if (EDITION_ASTEROID)
    # TODO: add other asteroidos architectures
    set(TARGET_ARCHITECTURE asteroid)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL aarch64)
    set(TARGET_ARCHITECTURE aarch64)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES ^armv7)
    set(TARGET_ARCHITECTURE armv7hl)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL i486)
    set(TARGET_ARCHITECTURE i486)
endif()

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

add_library(TDLib SHARED IMPORTED)
file(GLOB LIBTDJSON_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/tdlib/${TARGET_ARCHITECTURE}/lib/libtdjson.so.*")
list(GET LIBTDJSON_PATHS 0 LIBTDJSON_PATH)
set_target_properties(TDLib PROPERTIES
    IMPORTED_LOCATION ${LIBTDJSON_PATH}
)

add_subdirectory(libfernie)

add_executable(${CMAKE_PROJECT_NAME} src/${CMAKE_PROJECT_NAME}.cpp)
# target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
#     $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
# )
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE src)
target_link_libraries(libfernie TDLib)
target_link_libraries(${CMAKE_PROJECT_NAME}
    Qt5::Quick
    SortFilterProxyModel
    libfernie
)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    src/${CMAKE_PROJECT_NAME}.cpp
    src/mainshared.h
    src/voicenoterecorder.cpp
)

if (EDITION_SAILFISH)
    target_sources(libfernie PRIVATE
        src/sailfishplatformapp.cpp
        src/tdlibsecrets.h
    )
    target_include_directories(libfernie PRIVATE
        $<BUILD_INTERFACE:
        ${SAILFISH_INCLUDE_DIRS}>
    )
    target_link_libraries(libfernie ${SAILFISH_LDFLAGS})

    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
        $<BUILD_INTERFACE:
        ${SAILFISH_INCLUDE_DIRS}>
    )
    target_link_libraries(${CMAKE_PROJECT_NAME} ${SAILFISH_LDFLAGS})

    add_definitions(-DEDITION_SAILFISH)

    option(HARBOUR_COMPLIANCE "Harbour compliance" OFF)

    if(HARBOUR_COMPLIANCE)
        message(STATUS "Harbour compliance enabled")
        add_definitions(-DHARBOUR_COMPLIANCE)
    else()
        message(STATUS "Harbour compliance disabled")
        add_definitions(-DNO_HARBOUR_COMPLIANCE)

        target_sources(${CMAKE_PROJECT_NAME} PRIVATE
            src/gstaudiorecorder.cpp
            src/gstaudiorecorder.h
        )
        pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0 gstreamer-pbutils-1.0 glib-2.0)
        target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${GSTREAMER_INCLUDE_DIRS})
        target_link_libraries(${CMAKE_PROJECT_NAME} ${GSTREAMER_LIBRARIES})
    endif()

elseif (EDITION_ASTEROID)
    target_sources(libfernie PRIVATE
        src/asteroidplatformapp.cpp
        src/sailfishyasteroidapp.h
        src/sailfishyasteroidapp.cpp
    )
    target_link_libraries(libfernie AsteroidApp)
    target_link_libraries(${CMAKE_PROJECT_NAME} AsteroidApp)

    add_definitions(-DEDITION_ASTEROID)

    message(STATUS "Harbour compliance always enabled on AsteroidOS")
    add_definitions(-DHARBOUR_COMPLIANCE)
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
    ${TsFiles})

add_custom_target(translations ALL DEPENDS ${TRANSLATION_QM_FILES})
add_dependencies(${CMAKE_PROJECT_NAME} translations)

install(TARGETS ${CMAKE_PROJECT_NAME}
    RUNTIME DESTINATION bin
)
install(DIRECTORY qml/shared/
    DESTINATION share/${CMAKE_PROJECT_NAME}/qml
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
install(DIRECTORY tdlib/${TARGET_ARCHITECTURE}/lib
    DESTINATION share/${CMAKE_PROJECT_NAME}
)

if (EDITION_SAILFISH)
    install(DIRECTORY qml/harbour/
        DESTINATION share/${CMAKE_PROJECT_NAME}/qml
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
elseif (EDITION_ASTEROID)
    # install(TARGETS ${CMAKE_PROJECT_NAME}
	#     DESTINATION ${CMAKE_INSTALL_LIBDIR}
    # )

    install(DIRECTORY qml/asteroid/
        DESTINATION share/${CMAKE_PROJECT_NAME}/qml
    )

    install(FILES images/fernschreiber2.svg
        DESTINATION share/icons/asteroid
        RENAME ${CMAKE_PROJECT_NAME}.svg
    )
endif()

# Get the other files reachable from the project tree in Qt Creator
# FIXME: this is broken and doesn't work (but files are still editable from qt creator so it's not as bad)
FILE(GLOB_RECURSE DistFiles
    images/*
    qml/*
    icons/*
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

