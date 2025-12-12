cmake_minimum_required(VERSION 3.5)

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

# rlottie
# rlottie/CMakeLists.txt is too hard to adapt
add_library(rlottie STATIC)

set(RLOTTIE_CONFIG_PATH ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/config.h)
# we could do file(TOUCH filename), but that requires CMake 3.12
if (NOT EXISTS ${RLOTTIE_CONFIG_PATH})
    file(WRITE ${RLOTTIE_CONFIG_PATH} "")
endif()

add_definitions(-DLOTTIE_THREAD_SUPPORT)
target_include_directories(SortFilterProxyModel PUBLIC # FIXME: should be rlottie?
    rlottie/inc
    rlottie/src/vector
    rlottie/src/vector/freetype
)
target_sources(SortFilterProxyModel # FIXME: should be rlottie?
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottieanimation.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottieitem.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottieitem_capi.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottiekeypath.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottieloader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottiemodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/lottieparser.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/lottie/zip/zip.cpp

    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/freetype/v_ft_math.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/freetype/v_ft_raster.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/freetype/v_ft_stroker.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/stb/stb_image.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/varenaalloc.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vbezier.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vbitmap.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vbrush.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdasher.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdrawable.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdrawhelper.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdrawhelper_common.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdrawhelper_neon.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vdrawhelper_sse2.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vmatrix.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vimageloader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vinterpolator.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vpainter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vpath.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vpathmesure.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vraster.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/vrle.cpp
)

include(CheckCXXSourceCompiles)
check_cxx_source_compiles("#ifdef __ARM_NEON__
int main() { return 0; }
#else
#error \"NEON not available\"
#endif
" HAVE_NEON)
if (HAVE_NEON)
    message("Using NEON render functions")
    SET(CMAKE_ASM_FLAGS "${CFLAGS} -x assembler-with-cpp")
    target_sources(rlottie PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/rlottie/src/vector/pixman/pixman-arm-neon-asm.S
    )
else()
    message("Using default render functions")
endif()


add_executable(${CMAKE_PROJECT_NAME} src/${CMAKE_PROJECT_NAME}.cpp)
# target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
#     $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
# )
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
    QT_STATICPLUGIN
)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${NEMONOTIFICATIONS_INCLUDE_DIRS}
    ${ZLIB_INCLUDE_DIRS}
    tdlib/include
    src
)
target_link_libraries(${CMAKE_PROJECT_NAME}
    Qt5::Quick
    Qt5::DBus
    Qt5::Multimedia
    Qt5::Positioning
    ${NEMONOTIFICATIONS_LIBRARIES}
    ${ZLIB_LIBRARIES}
    SortFilterProxyModel
    TDLib
    rlottie
)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    src/${CMAKE_PROJECT_NAME}.cpp
    src/appsettings.cpp
    src/boolfiltermodel.cpp
    src/chat/jumpablemessagesmodel.cpp
    src/chatdata.cpp
    src/chatfoldersmodel.cpp
    src/chat/chatmanager.cpp
    src/chatpermissionfiltermodel.cpp
    src/chatlistmodel.cpp
    src/contactsmodel.cpp
    src/dbusadaptor.cpp
    src/dbusinterface.cpp
    src/folderchatlistmodel.cpp
    src/forumtopicsmodel.cpp
    src/chat/invertedmessagesmodel.cpp
    src/chat/mediamessagesmodel.cpp
    src/chat/messagedata.cpp
    src/chat/messagesmodel.cpp
    src/chat/readablemessagesmodel.cpp
    src/invertedproxymodel.cpp
    src/movieitem.cpp
    src/suggestedactionsmanager.cpp
    src/utilities.cpp
    src/knownusersmodel.cpp
    src/mceinterface.cpp
    src/notificationmanager.cpp
    src/processlauncher.cpp
    src/platformapp.cpp
    src/stickermanager.cpp
    src/tdlib/tdlibfile.cpp
    src/tdlib/tdlibreceiver.cpp
    src/tdlib/tdlibwrapper.cpp
    src/textfiltermodel.cpp
    src/tgsplugin.cpp
    src/waveformmanager.cpp
    
    src/mainshared.h
    src/appsettings.h
    src/boolfiltermodel.h
    src/chat/jumpablemessagesmodel.h
    src/chatdata.h
    src/chatfoldersmodel.h
    src/chat/chatmanager.h
    src/chatpermissionfiltermodel.h
    src/chatlistmodel.h
    src/contactsmodel.h
    src/dbusadaptor.h
    src/dbusinterface.h
    src/debuglog.h
    src/debuglogjs.h
    src/folderchatlistmodel.h
    src/forumtopicsmodel.h
    src/chat/invertedmessagesmodel.h
    src/chat/mediamessagesmodel.h
    src/chat/messagedata.h
    src/chat/messagesmodel.h
    src/chat/readablemessagesmodel.h
    src/invertedproxymodel.h
    src/movieitem.h
    src/suggestedactionsmanager.h
    src/utilities.h
    src/knownusersmodel.h
    src/mceinterface.h
    src/notificationmanager.h
    src/processlauncher.h
    src/platformapp.h
    src/stickermanager.h
    src/tdlib/tdlibfile.h
    src/tdlib/tdlibreceiver.h
    src/tdlibsecrets.h
    src/tdlib/tdlibwrapper.h
    src/textfiltermodel.h
    src/tgsplugin.h
    src/waveformmanager.h
)

if (EDITION_SAILFISH)
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

