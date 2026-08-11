#include "mousebridge.h"
#include "KeyboardBridge.h"
#include "ControllerBridge.h"
#include <QDebug>
#include <QTimer>
#include <QtMath>
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QSettings>

#define NOMINMAX
#ifdef Q_OS_WIN
#include <windows.h>
#endif

static MouseBridge *g_mouseInstance = nullptr;

#ifdef Q_OS_WIN
static HHOOK hMouseHook = nullptr;
LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam);
#endif

MouseBridge::MouseBridge(QObject *parent) : QObject(parent) {
    g_mouseInstance = this;

    QTimer *updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, [this]() {
        // --- Controller Remap Capture Check ---
        if (m_activeRemapButtonId != -1 && m_controllerBridge) {
            for (int i = 0; i < ControllerBridge::Action_Count; ++i) {
                auto action = static_cast<ControllerBridge::ControllerAction>(i);

                // Check both buttons and analog axes (sticks/triggers) past threshold
                if (m_controllerBridge->isActionPressed(action) || std::abs(m_controllerBridge->getActionAxis(action)) > 0.6f) {
                    setMouseControllerMapping(m_activeRemapButtonId, i);

                    m_activeRemapButtonId = -1;
                    m_isListening = false;
                    emit activeRemapButtonIdChanged();
                    emit listeningChanged();
                    break;
                }
            }
        }
        // --------------------------------------

        if (m_accumulatedDx != 0.0 || m_accumulatedDy != 0.0) {
            m_dotX += m_accumulatedDx;
            m_dotY += m_accumulatedDy;
            m_accumulatedDx = 0.0;
            m_accumulatedDy = 0.0;
        } else {
            m_dotX *= 0.80;
            m_dotY *= 0.80;

            if (qAbs(m_dotX) < 0.1) m_dotX = 0.0;
            if (qAbs(m_dotY) < 0.1) m_dotY = 0.0;
        }

        double distance = qSqrt(m_dotX * m_dotX + m_dotY * m_dotY);
        if (distance > m_maxRadius) {
            m_dotX = (m_dotX / distance) * m_maxRadius;
            m_dotY = (m_dotY / distance) * m_maxRadius;
        }

        emit mouseUpdated();
    });
    updateTimer->start(16); // ~60 FPS

#ifdef Q_OS_WIN
    hMouseHook = SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc, GetModuleHandle(nullptr), 0);
    if (!hMouseHook) {
        qDebug() << "Failed to install global mouse hook!";
    }
#endif
}

MouseBridge::~MouseBridge() {
#ifdef Q_OS_WIN
    if (hMouseHook) {
        UnhookWindowsHookEx(hMouseHook);
    }
#endif
    if (g_mouseInstance == this) {
        g_mouseInstance = nullptr;
    }
}

void MouseBridge::setIsListening(bool listening) {
    if (m_isListening == listening) return;
    m_isListening = listening;

    // If we started listening, cancel keyboard listening immediately
    if (listening && m_keyboardBridge) {
        m_keyboardBridge->setIsListening(false);
    }

    emit listeningChanged();
    emit mouseUpdated();
}

void MouseBridge::setMaxRadius(double radius) {
    if (m_maxRadius != radius) {
        m_maxRadius = radius;
        emit maxRadiusChanged();
    }
}

void MouseBridge::setKeyboardBridge(KeyboardBridge *bridge) {
    m_keyboardBridge = bridge;
}

void MouseBridge::setControllerBridge(ControllerBridge *bridge) {
    m_controllerBridge = bridge;
}

bool MouseBridge::isButtonPressed(const QString &btnId) const {
    if (btnId == "LMB") return m_leftPressed;
    if (btnId == "RMB") return m_rightPressed;
    if (btnId == "Mouse 3") return m_middlePressed;
    if (btnId == "Mouse 4") return m_upperPressed; // Upper side button
    if (btnId == "Mouse 5") return m_lowerPressed; // Lower side button
    return false;
}

bool MouseBridge::isButtonEffectivelyPressed(const QString &btnId) const {
    if (btnId == "LMB") return isEffectivelyPressed(0);
    if (btnId == "RMB") return isEffectivelyPressed(1);
    if (btnId == "Mouse 3") return isEffectivelyPressed(2);
    if (btnId == "Mouse 4") return isEffectivelyPressed(4);
    if (btnId == "Mouse 5") return isEffectivelyPressed(3);
    return false;
}

bool MouseBridge::isMousePseudoKey(int code) {
    return code >= 0x0201 && code <= 0x0205;
}

int MouseBridge::pseudoKeyForButtonId(int buttonId) {
    switch (buttonId) {
    case 0: return 0x0201; // LMB
    case 1: return 0x0202; // RMB
    case 2: return 0x0203; // Mouse 3
    case 3: return 0x0205; // Mouse 5 (lower / XBUTTON1)
    case 4: return 0x0204; // Mouse 4 (upper / XBUTTON2)
    default: return 0;
    }
}

int MouseBridge::buttonIdForPseudoKey(int pseudoKey) {
    switch (pseudoKey) {
    case 0x0201: return 0;
    case 0x0202: return 1;
    case 0x0203: return 2;
    case 0x0205: return 3;
    case 0x0204: return 4;
    default: return -1;
    }
}

bool MouseBridge::rawStateForButtonId(int buttonId) const {
    switch (buttonId) {
    case 0: return m_leftPressed;
    case 1: return m_rightPressed;
    case 2: return m_middlePressed;
    case 3: return m_lowerPressed;
    case 4: return m_upperPressed;
    default: return false;
    }
}

bool MouseBridge::isEffectivelyPressed(int buttonId) const {
    QSet<int> visited;
    return isEffectivelyPressedInternal(buttonId, visited);
}

int MouseBridge::getMouseMapping(int buttonId) const {
    return m_mouseMappings.value(buttonId, pseudoKeyForButtonId(buttonId));
}

// mousebridge.cpp (around line 148)
void MouseBridge::setMouseMapping(int sourceButton, int mappedButton) {
    bool changed = false;
    int defaultKey = pseudoKeyForButtonId(sourceButton);

    // If mapped to itself (by index or pseudo-key), treat as standard unmapped state
    if (sourceButton == mappedButton || mappedButton == defaultKey) {
        if (m_mouseMappings.contains(sourceButton)) {
            m_mouseMappings.remove(sourceButton);
            changed = true; // Only dirty if it was previously custom-mapped
        }
    } else {
        // Pass defaultKey so an unmapped button compares against 0x0201 instead of 0
        if (m_mouseMappings.value(sourceButton, defaultKey) != mappedButton) {
            m_mouseMappings[sourceButton] = mappedButton;
            changed = true; // Only dirty if the mapping actually changed
        }
    }

    if (changed) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
        emit mouseUpdated();
    }
}
void MouseBridge::clearUnsavedChanges() {

        if (m_hasUnsavedChanges) {
            m_hasUnsavedChanges = false;
            emit hasUnsavedChangesChanged();
        }
}
void MouseBridge::setMouseControllerMapping(int buttonId, int controllerAction) {
    bool changed = false;

    if (controllerAction == -1) {
        if (m_mouseControllerMappings.contains(buttonId)) {
            m_mouseControllerMappings.remove(buttonId);
            changed = true;
        }
    } else {
        if (m_mouseControllerMappings.value(buttonId, -1) != controllerAction) {
            m_mouseControllerMappings[buttonId] = controllerAction;
            changed = true;
        }
        if (m_mouseMappings.contains(buttonId)) {
            m_mouseMappings.remove(buttonId);
            changed = true;
        }
    }

    if (changed) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
        emit mappingChanged();
        emit mouseUpdated();
    }
}
void MouseBridge::clearMouseMapping(int buttonId) {
    m_mouseMappings.remove(buttonId);
    m_mouseControllerMappings.remove(buttonId);

    if (!m_hasUnsavedChanges) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }

    emit mappingChanged();
    emit mouseUpdated();
}

void MouseBridge::clearAllMouseMappings() {
    m_mouseMappings.clear();
    m_mouseControllerMappings.clear();

    if (!m_hasUnsavedChanges) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }

    emit mappingChanged();
    emit mouseUpdated();
}

void MouseBridge::discardChanges() {
    loadProfile(m_currentProfileName);
}

bool MouseBridge::isEffectivelyPressedInternal(int buttonId, QSet<int> &visited) const {
    if (visited.contains(buttonId)) return false;
    visited.insert(buttonId);

    // 1. Controller action mapping takes top priority
    if (m_controllerBridge && m_mouseControllerMappings.contains(buttonId)) {
        int actionInt = m_mouseControllerMappings.value(buttonId);
        return m_controllerBridge->isActionPressed(static_cast<ControllerBridge::ControllerAction>(actionInt));
    }

    // 2. Mapped source
    int mappedSource = m_mouseMappings.value(buttonId, pseudoKeyForButtonId(buttonId));

    if (mappedSource == -1 || mappedSource == 0) {
        return false;
    }

    if (mappedSource != pseudoKeyForButtonId(buttonId)) {
        if (isMousePseudoKey(mappedSource)) {
            int otherButtonId = buttonIdForPseudoKey(mappedSource);
            if (otherButtonId >= 0) {
                return isEffectivelyPressedInternal(otherButtonId, visited);
            }
        } else if (m_keyboardBridge) {
            return m_keyboardBridge->isKeyPressed(mappedSource);
        }
    }

    // 3. Fall back to physical hardware state
    return rawStateForButtonId(buttonId);
}

int MouseBridge::getMouseControllerMapping(int buttonId) const {
    return m_mouseControllerMappings.value(buttonId, -1);
}

QString MouseBridge::getProfilesDir() const {
    QString path = QCoreApplication::applicationDirPath() + "/profiles/mouse";
    QDir dir(path);
    if (!dir.exists()) dir.mkpath(".");
    return path;
}

void MouseBridge::setCurrentProfileName(const QString &name) {
    if (m_currentProfileName != name) {
        m_currentProfileName = name;
        emit currentProfileNameChanged();
    }
}

void MouseBridge::saveCurrentProfile() {
    QString filePath = getProfilesDir() + "/" + m_currentProfileName + ".ini";
    QSettings settings(filePath, QSettings::IniFormat);

    settings.clear();

    settings.beginGroup("MouseMappings");
    for (auto it = m_mouseMappings.begin(); it != m_mouseMappings.end(); ++it) {
        settings.setValue(QString::number(it.key()), it.value());
    }
    settings.endGroup();

    settings.beginGroup("MouseControllerMappings");
    for (auto it = m_mouseControllerMappings.begin(); it != m_mouseControllerMappings.end(); ++it) {
        settings.setValue(QString::number(it.key()), it.value());
    }
    settings.endGroup();

    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    emit mouseUpdated();
}

void MouseBridge::loadProfile(const QString &profileName) {
    setCurrentProfileName(profileName);

    m_mouseMappings.clear();
    m_mouseControllerMappings.clear();

    QString filePath = getProfilesDir() + "/" + profileName + ".ini";
    QSettings settings(filePath, QSettings::IniFormat);

    settings.beginGroup("MouseMappings");
    for (const QString &key : settings.childKeys()) {
        m_mouseMappings[key.toInt()] = settings.value(key).toInt();
    }
    settings.endGroup();

    settings.beginGroup("MouseControllerMappings");
    for (const QString &key : settings.childKeys()) {
        m_mouseControllerMappings[key.toInt()] = settings.value(key).toInt();
    }
    settings.endGroup();

    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    emit mappingChanged();
    emit mouseUpdated();
}

QStringList MouseBridge::getAvailableProfiles() const {
    QDir dir(getProfilesDir());
    QStringList files = dir.entryList(QStringList() << "*.ini", QDir::Files);
    QStringList profiles;
    for (const QString &file : files) {
        profiles.append(file.section('.', 0, -2));
    }
    if (profiles.isEmpty()) {
        profiles.append("Default");
    }
    return profiles;
}

void MouseBridge::createProfile(const QString &profileName) {
    QString filePath = getProfilesDir() + "/" + profileName + ".ini";
    if (!QFile::exists(filePath)) {
        m_mouseMappings.clear();
        m_mouseControllerMappings.clear();
        m_currentProfileName = profileName;
        saveCurrentProfile();
        emit mouseUpdated();
    }
    loadProfile(profileName);
}

void MouseBridge::deleteProfile(const QString &profileName) {
    if (profileName == "Default") return;
    QString filePath = getProfilesDir() + "/" + profileName + ".ini";
    if (QFile::exists(filePath)) {
        QFile::remove(filePath);
    }
    QStringList profiles = getAvailableProfiles();
    if (!profiles.isEmpty()) {
        loadProfile(profiles.first());
    }
}

void MouseBridge::handleMouseMovement(int dx, int dy) {
    m_accumulatedDx += dx;
    m_accumulatedDy += dy;
}

void MouseBridge::setButtonState(int buttonId, bool pressed) {
    bool changed = false;
    switch (buttonId) {
    case 0: if (m_leftPressed != pressed) { m_leftPressed = pressed; changed = true; } break;
    case 1: if (m_rightPressed != pressed) { m_rightPressed = pressed; changed = true; } break;
    case 2: if (m_middlePressed != pressed) { m_middlePressed = pressed; changed = true; } break;
    case 3: if (m_lowerPressed != pressed) { m_lowerPressed = pressed; changed = true; } break;
    case 4: if (m_upperPressed != pressed) { m_upperPressed = pressed; changed = true; } break;
    }

    if (changed) {
        emit mouseUpdated();
        if (pressed) {
            int pseudoKey = pseudoKeyForButtonId(buttonId);
            emit mouseButtonPressedForRemap(pseudoKey);

            if (m_activeRemapButtonId != -1) {
                qDebug() << "Captured mouse button" << pseudoKey << "for remapping button ID" << m_activeRemapButtonId;
            }
        }
    }
}

void MouseBridge::setActiveRemapButtonId(int id) {
    if (m_activeRemapButtonId != id) {
        m_activeRemapButtonId = id;
        emit activeRemapButtonIdChanged();
    }
}

#ifdef Q_OS_WIN
LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && g_mouseInstance) {
        MSLLHOOKSTRUCT *pMouse = (MSLLHOOKSTRUCT*)lParam;

        if (wParam == WM_MOUSEMOVE) {
            static bool initialized = false;
            static int lastX = 0;
            static int lastY = 0;

            int currentX = pMouse->pt.x;
            int currentY = pMouse->pt.y;

            if (!initialized) {
                lastX = currentX;
                lastY = currentY;
                initialized = true;
            }

            int dx = currentX - lastX;
            int dy = currentY - lastY;

            if (dx != 0 || dy != 0) {
                g_mouseInstance->handleMouseMovement(dx, dy);
                lastX = currentX;
                lastY = currentY;
            }
        }
        else if (wParam == WM_LBUTTONDOWN) {
            g_mouseInstance->setButtonState(0, true);
        }
        else if (wParam == WM_LBUTTONUP) {
            g_mouseInstance->setButtonState(0, false);
        }
        else if (wParam == WM_RBUTTONDOWN) {
            g_mouseInstance->setButtonState(1, true);
        }
        else if (wParam == WM_RBUTTONUP) {
            g_mouseInstance->setButtonState(1, false);
        }
        else if (wParam == WM_MBUTTONDOWN) {
            g_mouseInstance->setButtonState(2, true);
        }
        else if (wParam == WM_MBUTTONUP) {
            g_mouseInstance->setButtonState(2, false);
        }
        else if (wParam == WM_XBUTTONDOWN) {
            WORD xButton = HIWORD(pMouse->mouseData);
            if (xButton == XBUTTON1) g_mouseInstance->setButtonState(3, true);
            else if (xButton == XBUTTON2) g_mouseInstance->setButtonState(4, true);
        }
        else if (wParam == WM_XBUTTONUP) {
            WORD xButton = HIWORD(pMouse->mouseData);
            if (xButton == XBUTTON1) g_mouseInstance->setButtonState(3, false);
            else if (xButton == XBUTTON2) g_mouseInstance->setButtonState(4, false);
        }
    }
    return CallNextHookEx(hMouseHook, nCode, wParam, lParam);
}
#endif