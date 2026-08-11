cmake_minimum_required(VERSION 3.16)

project(InputOverlay VERSION 0.1 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Tell MSVC to generate debug symbols even in Release Mode
if(MSVC)
    add_compile_options("$<$<CONFIG:RELEASE>:/Zi>")
    add_link_options("$<$<CONFIG:RELEASE>:/DEBUG>")
endif()

# 1. Added Network component here
find_package(Qt6 REQUIRED COMPONENTS Quick Widgets Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appInputOverlay
    main.cpp
)

# 2. Cleaned up QML_FILES and SOURCES lists
qt_add_qml_module(appInputOverlay
    URI InputOverlay
    VERSION 1.0
    QML_FILES
        Main.qml
        ControlPanel.qml
        Preset1.qml
        Preset2.qml
        Preset3.qml
        Preset4.qml
        Preset5.qml
        Preset6.qml
        Preset7.qml
        Preset8.qml
        Preset9.qml
        MousePreset.qml
        MappingPage.qml
        KeyboardMappingPage.qml
        ControllerPreview.qml
        MousePreview.qml
    RESOURCES
        icons/app_icon.png
        icons/file.svg
    SOURCES
        ControllerBridge.h ControllerBridge.cpp
        KeyboardBridge.h KeyboardBridge.cpp
        mousebridge.h mousebridge.cpp
        UpdateChecker.h UpdateChecker.cpp
        SOURCES updatechecker.h updatechecker.cpp
)

set_target_properties(appInputOverlay PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# SDL3 Paths
set(SDL3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/SDL3/cmake")
set(SDL3_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/SDL3/include")
set(SDL3_LIB_FILE "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/SDL3/lib/x64/SDL3.lib")

find_package(SDL3 REQUIRED CONFIG HINTS "${SDL3_DIR}")

target_include_directories(appInputOverlay PRIVATE "${SDL3_INCLUDE_DIR}")

# 3. Added Qt6::Network here
target_link_libraries(appInputOverlay
    PRIVATE
    Qt6::Quick
    Qt6::Widgets
    Qt6::Network
    "${SDL3_LIB_FILE}"
)

include(GNUInstallDirs)

install(TARGETS appInputOverlay
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)