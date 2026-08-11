#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <SDL3/SDL.h>
#include <QDebug>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QQuickWindow>
#include "ControllerBridge.h"
#include "UpdateChecker.h"
#include "KeyboardBridge.h"
#include "mousebridge.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QApplication app(argc, argv);


    QQmlApplicationEngine engine;

    // Instantiate and expose UpdateChecker to QML
    UpdateChecker updateChecker;
    engine.rootContext()->setContextProperty("updateChecker", &updateChecker);

    app.setQuitOnLastWindowClosed(false);

    // Class instances
    KeyboardBridge *keyboardBridge = new KeyboardBridge(&app);
    ControllerBridge *controllerBridge = new ControllerBridge(&app);
    MouseBridge *mouseBridge = new MouseBridge(&app);

    controllerBridge->setKeyboardBridge(keyboardBridge);
    controllerBridge->setMouseBridge(mouseBridge);
    keyboardBridge->setMouseBridge(mouseBridge);
    keyboardBridge->setControllerBridge(controllerBridge);
    keyboardBridge->loadConfiguration();
    mouseBridge->setKeyboardBridge(keyboardBridge);
    mouseBridge->setControllerBridge(controllerBridge);

    // QML Singletons
    qmlRegisterSingletonInstance("com.overlay.controls", 1, 0, "ControllerBridge", controllerBridge);
    qmlRegisterSingletonInstance("com.overlay.controls", 1, 0, "KeyboardBridge", keyboardBridge);
    qmlRegisterSingletonInstance("com.overlay.controls", 1, 0, "MouseBridge", mouseBridge);

    // System Tray Setup
    QSystemTrayIcon trayIcon(QIcon(":/qt/qml/InputOverlay/icons/app_icon.png"), &app);
    QMenu trayMenu;
    QAction *configAction = trayMenu.addAction("Control Panel");
    QAction *quitAction = trayMenu.addAction("Exit");

    QObject::connect(quitAction, &QAction::triggered, &app, &QCoreApplication::quit);

    trayIcon.setContextMenu(&trayMenu);
    trayIcon.show();

    QObject::connect(configAction, &QAction::triggered, [&engine]() {
        engine.loadFromModule("InputOverlay", "ControlPanel");
    });

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("InputOverlay", "Main");

    QObject *rootObj = engine.rootObjects().first();
    QQuickWindow *window = qobject_cast<QQuickWindow*>(rootObj);
    if (window) {
        controllerBridge->setWindow(window);
    }

    //  Trigger the update check on startup (passes current version "0.1")
    updateChecker.checkForUpdates("0.1");

    return app.exec();
}