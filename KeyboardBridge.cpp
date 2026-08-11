#include "KeyboardBridge.h"
#include <QDebug>
#include <QSet>
#include <ControllerBridge.h>
#include <QSettings>
#include <QFileInfo>
#include <QTimer>
#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#define NOMINMAX
#ifdef Q_OS_WIN
#include <windows.h>
#endif

static KeyboardBridge *g_keyboardInstance = nullptr;

#ifdef Q_OS_WIN
static HHOOK hKeyboardHook = nullptr;
LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam);
#endif

KeyboardBridge::KeyboardBridge(QObject *parent) : QObject(parent) {
    g_keyboardInstance = this;

    // Pre-populate all standard visual keys at startup
    for (int k = Qt::Key_A; k <= Qt::Key_Z; ++k) m_allVisualKeys.append(k);
    for (int k = Qt::Key_0; k <= Qt::Key_9; ++k) m_allVisualKeys.append(k);
    for (int k = Qt::Key_F1; k <= Qt::Key_F24; ++k) m_allVisualKeys.append(k);

    QList<int> extraKeys = {
        Qt::Key_QuoteLeft, Qt::Key_Minus, Qt::Key_Equal, Qt::Key_Backspace,
        Qt::Key_Tab, Qt::Key_BracketLeft, Qt::Key_BracketRight, Qt::Key_Backslash,
        Qt::Key_CapsLock, Qt::Key_Semicolon, Qt::Key_Apostrophe, Qt::Key_Return,
        Qt::Key_Comma, Qt::Key_Period, Qt::Key_Slash,
        Qt::Key_Meta, Qt::Key_Space,
        Qt::Key_Escape, Qt::Key_Insert, Qt::Key_Delete, Qt::Key_Home,
        Qt::Key_End, Qt::Key_PageUp, Qt::Key_PageDown, Qt::Key_Left,
        Qt::Key_Up, Qt::Key_Right, Qt::Key_Down,
        // Independent custom codes matching QML:
        0x1101, 0x1102, // LeftShift, RightShift
        0x1103, 0x1104, // LeftCtrl, RightCtrl
        0x1105, 0x1106  // LeftAlt, RightAlt
    };

    for (int k : extraKeys) {
        if (!m_allVisualKeys.contains(k)) {
            m_allVisualKeys.append(k);
        }
    }

    QTimer *pollTimer = new QTimer(this);
    connect(pollTimer, &QTimer::timeout, this, [this]() {
        if (m_controllerBridge) {
            // Emit update so QML UI re-evaluates isKeyPressed() bindings at ~60fps
            emit keyboardUpdated();
        }
    });
    pollTimer->start(16); // ~60 FPS update rate for overlays

#ifdef Q_OS_WIN
    hKeyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, GetModuleHandle(nullptr), 0);
    if (!hKeyboardHook) {
        qDebug() << "Failed to install global keyboard hook!";
    }
#endif

    // Guarantee there's always a real file backing the active profile on fresh install
    QDir profileCheckDir(getProfilesDir());
    if (profileCheckDir.entryList(QStringList() << "*.ini", QDir::Files).isEmpty()) {
        restoreDefaults(); // populates default mappings and saves them as Default.ini
    } else {
        loadProfile("Default");
    }
}

KeyboardBridge::~KeyboardBridge() {
#ifdef Q_OS_WIN
    if (hKeyboardHook) {
        UnhookWindowsHookEx(hKeyboardHook);
    }
#endif
    if (g_keyboardInstance == this) {
        g_keyboardInstance = nullptr;
    }
}

bool KeyboardBridge::isKeyPressed(int qtKey) const {
    // If this key has a controller action bound to it (set via
    // setControllerKeyMapping(), used by the Keyboard Mapping page), it
    // should visually "light up" whenever that action is active - not just
    // on a real physical keypress. This was previously removed entirely to
    // avoid infinite recursion (ControllerBridge::isActionPressed() can call
    // back into this function for actions mapped to a keyboard key), which
    // fixed the crash but silently broke the light-up feature - a key with
    // a controller action bound to it would show its "Bound to: X" label
    // but never actually highlight. m_resolvingKeyPress breaks the cycle
    // instead of removing the check.
    if (m_controllerBridge && !m_resolvingKeyPress && m_controllerKeyMappings.contains(qtKey)) {
        m_resolvingKeyPress = true;
        int actionInt = m_controllerKeyMappings.value(qtKey);
        bool pressed = m_controllerBridge->isActionPressed(static_cast<ControllerBridge::ControllerAction>(actionInt));
        m_resolvingKeyPress = false;
        if (pressed) return true;
    }

    return m_keyStates.value(qtKey, false);
}
void KeyboardBridge::setIsListening(bool listening) {
    if (m_isListening == listening) return;
    m_isListening = listening;

    if (listening && m_mouseBridge) {
        m_mouseBridge->setIsListening(false);
    }

    emit listeningChanged();
}

void KeyboardBridge::setKeyboardKeyState(int qtKey, bool pressed) {
    if (m_keyStates.value(qtKey, false) != pressed) {
        m_keyStates[qtKey] = pressed;
        emit keyboardUpdated();
    }
}

int KeyboardBridge::qtKeyToWinVK(int qtKey) const {
    switch (qtKey) {
    case 0x1101: return VK_LSHIFT;
    case 0x1102: return VK_RSHIFT;
    case 0x1103: return VK_LCONTROL;
    case 0x1104: return VK_RCONTROL;
    case 0x1105: return VK_LMENU;
    case 0x1106: return VK_RMENU;
    default:     return qtKey;
    }
}

int KeyboardBridge::winVKToQtKey(int vkCode, bool extended) const {
    if (vkCode >= VK_F1 && vkCode <= VK_F24) {
        return Qt::Key_F1 + (vkCode - VK_F1);
    }
    const int Key_LeftShift  = 0x1101;
    const int Key_RightShift = 0x1102;
    const int Key_LeftCtrl   = 0x1103;
    const int Key_RightCtrl  = 0x1104;
    const int Key_LeftAlt    = 0x1105;
    const int Key_RightAlt   = 0x1106;
    switch (vkCode) {
    case VK_RETURN: return extended ? Qt::Key_Enter : Qt::Key_Return;
    case VK_ESCAPE: return Qt::Key_Escape;
    case VK_BACK:   return Qt::Key_Backspace;
    case VK_TAB:    return Qt::Key_Tab;
    case VK_SPACE:  return Qt::Key_Space;

    case VK_LSHIFT:  return Key_LeftShift;
    case VK_RSHIFT:  return Key_RightShift;
    case VK_SHIFT:   return Key_LeftShift;

    case VK_LCONTROL: return Key_LeftCtrl;
    case VK_RCONTROL: return Key_RightCtrl;
    case VK_CONTROL:  return Key_LeftCtrl;

    case VK_LMENU:    return Key_LeftAlt;
    case VK_RMENU:    return Key_RightAlt;
    case VK_MENU:     return Key_LeftAlt;

    case VK_LWIN:
    case VK_RWIN:   return Qt::Key_Meta;

    case VK_LEFT:   return Qt::Key_Left;
    case VK_UP:     return Qt::Key_Up;
    case VK_RIGHT:  return Qt::Key_Right;
    case VK_DOWN:   return Qt::Key_Down;
    case VK_INSERT: return Qt::Key_Insert;
    case VK_DELETE: return Qt::Key_Delete;
    case VK_HOME:   return Qt::Key_Home;
    case VK_END:    return Qt::Key_End;
    case VK_PRIOR:  return Qt::Key_PageUp;
    case VK_NEXT:   return Qt::Key_PageDown;
    case VK_CAPITAL: return Qt::Key_CapsLock;
    case VK_OEM_3:  return Qt::Key_QuoteLeft;
    case VK_OEM_MINUS: return Qt::Key_Minus;
    case VK_OEM_PLUS:  return Qt::Key_Equal;
    case VK_OEM_4:  return Qt::Key_BracketLeft;
    case VK_OEM_6:  return Qt::Key_BracketRight;
    case VK_OEM_5:  return Qt::Key_Backslash;
    case VK_OEM_1:  return Qt::Key_Semicolon;
    case VK_OEM_7:  return Qt::Key_Apostrophe;
    case VK_OEM_COMMA: return Qt::Key_Comma;
    case VK_OEM_PERIOD: return Qt::Key_Period;
    case VK_OEM_2:  return Qt::Key_Slash;

    case VK_NUMPAD0: return Qt::Key_0;
    case VK_NUMPAD1: return Qt::Key_1;
    case VK_NUMPAD2: return Qt::Key_2;
    case VK_NUMPAD3: return Qt::Key_3;
    case VK_NUMPAD4: return Qt::Key_4;
    case VK_NUMPAD5: return Qt::Key_5;
    case VK_NUMPAD6: return Qt::Key_6;
    case VK_NUMPAD7: return Qt::Key_7;
    case VK_NUMPAD8: return Qt::Key_8;
    case VK_NUMPAD9: return Qt::Key_9;
    case VK_DECIMAL: return Qt::Key_Period;
    case VK_MULTIPLY: return Qt::Key_Asterisk;
    case VK_ADD:      return Qt::Key_Plus;
    case VK_SUBTRACT: return Qt::Key_Minus;
    case VK_DIVIDE:   return Qt::Key_Slash;
    case VK_NUMLOCK:  return Qt::Key_NumLock;

    case VK_SNAPSHOT: return Qt::Key_Print;
    case VK_SCROLL:   return Qt::Key_ScrollLock;
    case VK_PAUSE:    return Qt::Key_Pause;

    default: {
        if ((vkCode >= 'A' && vkCode <= 'Z') || (vkCode >= '0' && vkCode <= '9')) {
            return vkCode;
        }
        return 0;
    }
    }
}

int KeyboardBridge::getKeyMapping(int sourceQtKey) const {
    return m_keyMappings.value(sourceQtKey, sourceQtKey);
}

void KeyboardBridge::setKeyMapping(int sourceQtKey, int mappedQtKey) {
    bool changed = false;
    if (sourceQtKey == mappedQtKey) {
        if (m_keyMappings.contains(sourceQtKey)) {
            m_keyMappings.remove(sourceQtKey);
            changed = true;
        }
    } else {
        if (m_keyMappings.value(sourceQtKey) != mappedQtKey) {
            m_keyMappings[sourceQtKey] = mappedQtKey;
            changed = true;
        }
    }

    if (changed) {
        m_keyStates.clear();
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
        emit keyboardUpdated();
    }

}

void KeyboardBridge::setControllerKeyMapping(int qtKey, int controllerAction) {
    bool changed = false;
    if (controllerAction == -1) {
        if (m_controllerKeyMappings.contains(qtKey)) {
            m_controllerKeyMappings.remove(qtKey);
            changed = true;
        }
    } else {
        // Remove this action from any other key it was bound to first
        auto it = m_controllerKeyMappings.begin();
        while (it != m_controllerKeyMappings.end()) {
            if (it.value() == controllerAction) {
                it = m_controllerKeyMappings.erase(it);
                changed = true; // <-- Crucial: mark as changed when clearing old binding
            } else {
                ++it;
            }
        }

        if (m_controllerKeyMappings.value(qtKey, -1) != controllerAction) {
            m_controllerKeyMappings[qtKey] = controllerAction;
            changed = true;
        }
    }

    if (changed) {
        syncControllerKeyMappings();
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
        emit keyboardUpdated();
    }
}

void KeyboardBridge::handleGlobalKey(int vkCode, bool pressed, bool extended) {
    int physicalQtKey = winVKToQtKey(vkCode, extended);
    if (physicalQtKey != 0) {
        QSet<int> visualKeysToUpdate;

        for (int visualKey : m_allVisualKeys) {
            int mappedPhysicalKey = m_keyMappings.value(visualKey, visualKey);
            if (mappedPhysicalKey == physicalQtKey) {
                visualKeysToUpdate.insert(visualKey);
            }
        }

        for (int visualKey : visualKeysToUpdate) {
            setKeyboardKeyState(visualKey, pressed);

            // FIX: Check if this visual key has a bound controller action and trigger it!
            int action = m_controllerKeyMappings.value(visualKey, -1);
            if (action == -1) {
                action = m_controllerKeyMappings.value(physicalQtKey, -1);
            }

            if (action != -1 && m_controllerBridge) {
                // If your ControllerBridge has a method to simulate/trigger actions, call it here:
                // m_controllerBridge->triggerAction(action, pressed);
            }
        }

        if (pressed) {
            emit keyPressedForRemap(physicalQtKey);
        }
    }
}
void KeyboardBridge::restoreDefaults() {
    m_keyMappings.clear();
    m_controllerKeyMappings.clear();
    if (m_mouseBridge) m_mouseBridge->clearAllMouseMappings();
    m_keyStates.clear();
    syncControllerKeyMappings(); // ADDED
    emit keyboardUpdated();
    saveCurrentProfile();
}

QString KeyboardBridge::getProfilesDir() const {
    // FIX: Isolate keyboard profiles into their own folder
    QString path = QCoreApplication::applicationDirPath() + "/profiles/keyboard";
    QDir dir(path);
    if (!dir.exists()) dir.mkpath(".");
    return path;
}
QStringList KeyboardBridge::getAvailableProfiles() const {
    QDir dir(getProfilesDir());
    QStringList filters;
    filters << "*.ini";
    QStringList files = dir.entryList(filters, QDir::Files);

    QStringList profiles;
    for (const QString &file : files) {
        profiles.append(file.section('.', 0, 0));
    }

    if (profiles.isEmpty()) {
        profiles.append("Default");
    }
    return profiles;
}

void KeyboardBridge::createProfile(const QString &name) {
    QString trimmed = name.trimmed();
    if (trimmed.isEmpty() || m_currentProfile == trimmed) return;

    saveCurrentProfile();
    m_currentProfile = trimmed;

    // Keep MouseBridge in lockstep when creating a new profile
    if (m_mouseBridge) {
        m_mouseBridge->createProfile(trimmed);
    }

    restoreDefaults();
    emit currentProfileNameChanged();
    emit keyboardUpdated();
    emit availableProfilesChanged();
}
void KeyboardBridge::deleteProfile(const QString &name) {
    if (name.compare("Default", Qt::CaseInsensitive) == 0) return;
    if (m_currentProfile == name) loadProfile("Default"); // Load default before deleting

    QString path = getProfilesDir() + "/" + name + ".ini";
    if (QFile::exists(path)) QFile::remove(path);

    emit availableProfilesChanged();
    emit keyboardUpdated();

}
void KeyboardBridge::saveCurrentProfile() {
    QString path = getProfilesDir() + "/" + m_currentProfile + ".ini";
    saveConfiguration(path);
}

void KeyboardBridge::loadProfile(const QString &name) {
    QString target = name.trimmed();
    if (target.isEmpty() || m_currentProfile == target) return;
    QString path = getProfilesDir() + "/" + target + ".ini";
    if (!QFile::exists(path)) return;

    m_currentProfile = target;

    // Load the matching profile on MouseBridge as well
    if (m_mouseBridge) {
        m_mouseBridge->loadProfile(target);
    }

    loadConfiguration(path);

    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();

    emit currentProfileNameChanged();
    emit keyboardUpdated();
}
void KeyboardBridge::discardChanges() {
    QString path = getProfilesDir() + "/" + m_currentProfile + ".ini";
    if (QFile::exists(path)) {
        loadConfiguration(path);
    }

    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    emit keyboardUpdated();
}
void KeyboardBridge::saveConfiguration(const QString &filename) {
    QString actualFilename = filename.isEmpty() ? (getProfilesDir() + "/" + m_currentProfile + ".ini") : filename;
    if (QFileInfo(actualFilename).isRelative()) {
        actualFilename = QCoreApplication::applicationDirPath() + "/" + actualFilename;
    }

    QSettings settings(actualFilename, QSettings::IniFormat);

    settings.beginGroup("Keyboard_Visual");
    settings.remove("");
    for (auto it = m_keyMappings.begin(); it != m_keyMappings.end(); ++it) {
        settings.setValue(QString::number(it.key()), it.value());
    }
    settings.endGroup();

    settings.beginGroup("Keyboard_Controller");
    settings.remove("");
    for (auto it = m_controllerKeyMappings.begin(); it != m_controllerKeyMappings.end(); ++it) {
        settings.setValue(QString::number(it.key()), it.value());
    }
    settings.endGroup();

    if (m_mouseBridge) {
        settings.beginGroup("Mouse_Visual");
        settings.remove("");
        for (int i = 0; i <= 4; ++i) {
            settings.setValue(QString::number(i), m_mouseBridge->getMouseMapping(i));
        }
        settings.endGroup();

        settings.beginGroup("Mouse_Controller");
        settings.remove("");
        for (int i = 0; i <= 4; ++i) {
            int action = m_mouseBridge->getMouseControllerMapping(i);
            if (action != -1) {
                settings.setValue(QString::number(i), action);
            }
        }
        settings.endGroup();
    }

    settings.sync();
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    if (m_mouseBridge) {
        m_mouseBridge->saveCurrentProfile();
        m_mouseBridge->clearUnsavedChanges();
    }
}

void KeyboardBridge::loadConfiguration(const QString &filename) {
    QString actualFilename = filename.isEmpty() ? (getProfilesDir() + "/" + m_currentProfile + ".ini") : filename;
    if (QFileInfo(actualFilename).isRelative()) {
        actualFilename = QCoreApplication::applicationDirPath() + "/" + actualFilename;
    }

    QSettings settings(actualFilename, QSettings::IniFormat);

    settings.beginGroup("Keyboard_Visual");
    m_keyMappings.clear();
    QStringList keys = settings.childKeys();
    for (const QString &keyStr : keys) {
        int sourceKey = keyStr.toInt();
        int mappedKey = settings.value(keyStr).toInt();
        m_keyMappings[sourceKey] = mappedKey;
    }
    settings.endGroup();

    // NOTE: Make sure your save function uses "Keyboard_Controller" as well!
    settings.beginGroup("Keyboard_Controller");
    m_controllerKeyMappings.clear();
    QStringList controllerKeys = settings.childKeys();
    for (const QString &keyStr : controllerKeys) {
        int qtKey = keyStr.toInt();
        int action = settings.value(keyStr).toInt();
        m_controllerKeyMappings[qtKey] = action;
    }
    settings.endGroup();

    if (m_mouseBridge) {
        m_mouseBridge->clearAllMouseMappings();

        settings.beginGroup("Mouse_Visual");
        QStringList mouseKeys = settings.childKeys();
        for (const QString &keyStr : mouseKeys) {
            int buttonId = keyStr.toInt();
            int mappedKey = settings.value(keyStr).toInt();
            m_mouseBridge->setMouseMapping(buttonId, mappedKey);
        }
        settings.endGroup();

        settings.beginGroup("Mouse_Controller");
        QStringList mouseControllerKeys = settings.childKeys();
        for (const QString &keyStr : mouseControllerKeys) {
            int buttonId = keyStr.toInt();
            int action = settings.value(keyStr).toInt();
            m_mouseBridge->setMouseControllerMapping(buttonId, action);
        }
        settings.endGroup();

       m_mouseBridge->clearUnsavedChanges();
    }

    m_keyStates.clear();
    emit keyboardUpdated();
    syncControllerKeyMappings();

    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
}
void KeyboardBridge::setControllerBridge(ControllerBridge *bridge) {
    m_controllerBridge = bridge;
}

void KeyboardBridge::setMouseBridge(MouseBridge *mouseBridge) {
    m_mouseBridge = mouseBridge;
}

int KeyboardBridge::getControllerKeyMapping(int qtKey) const {
    return m_controllerKeyMappings.value(qtKey, -1);
}
void KeyboardBridge::syncControllerKeyMappings() {
    // This used to call m_controllerBridge->clearKeyboardMap() and rebuild
    // it from m_controllerKeyMappings. That was wrong: the two tables are
    // NOT the same relationship in reverse.
    //
    //   ControllerBridge::m_keyboardMap   is "action -> qtKey": this
    //   controller action is DRIVEN BY that keyboard key. Set on the
    //   Controller Mapping page via remapKeyboardAction() (e.g.
    //   "Left Stick Up -> W"), and already saved/loaded on its own via
    //   ControllerBridge::saveMappingConfig()/loadMappingConfig().
    //
    //   KeyboardBridge::m_controllerKeyMappings is "qtKey -> action": this
    //   visual KEY lights up whenever that controller action fires. Set on
    //   the Keyboard Mapping page via setControllerKeyMapping().
    //
    // Forcibly overwriting the first table with the second, every time this
    // ran (setControllerKeyMapping(), restoreDefaults(), and every profile
    // load), meant any mapping made on the Controller page - like
    // "Left Stick Up -> W" - got silently wiped the moment you touched
    // anything on the Keyboard Mapping page.
    //
    // isKeyPressed() now reads m_controllerKeyMappings directly (with its
    // own recursion guard), so nothing needs to be pushed into
    // ControllerBridge for that to work. This function is intentionally a
    // no-op now; left in place (rather than removed) since it's still
    // called from a few places and callers shouldn't need to change.
}
#ifdef Q_OS_WIN
LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && g_keyboardInstance) {
        KBDLLHOOKSTRUCT *pKeyboard = (KBDLLHOOKSTRUCT*)lParam;
        int vkCode = pKeyboard->vkCode;
        bool extended = (pKeyboard->flags & LLKHF_EXTENDED) != 0;

        bool pressed = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
        bool released = (wParam == WM_KEYUP || wParam == WM_SYSKEYUP);

        if (pressed || released) {
            g_keyboardInstance->handleGlobalKey(vkCode, pressed, extended);
        }
    }
    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
}
#endif