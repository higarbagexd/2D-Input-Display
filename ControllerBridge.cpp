#include "ControllerBridge.h"
#include <QDebug>
#include <QQuickWindow>
#include <cmath>
#include <QSettings>
#include <QFileInfo>
#include "KeyboardBridge.h" // because we need a m_keyboardbridge
#include "mousebridge.h"    // because we need a m_mouseBridge
#include <QDir>
#include <QStandardPaths>
// Centralized axis & input thresholds for consistent sensitivity and detection
constexpr float kDeadzone = 0.2f;
constexpr float kAxisPressThreshold = 0.5f;
constexpr float kTriggerPressThreshold = 0.15f;
constexpr float kRemapThreshold = 0.6f;

// This is a pointer to a struct to represent the gamepad
// We init it to nullptr to indicate that no controller is currently linked.
static SDL_Gamepad* g_gamepad = nullptr;

/*
 Helper function that checks whether the action being remapped is a trigger

 Triggers are mapped as a full analog axis, whereas stick directions are
 mapped individually (left, right, up, down)

 Example:
     isTriggerAction(Action_LeftTrigger)  -> true
     isTriggerAction(Action_RightTrigger) -> true
     isTriggerAction(Action_A)            -> false
     isTriggerAction(Action_DPadUp)       -> false
*/
static bool isTriggerAction(ControllerBridge::ControllerAction action) {
    return (
        action == ControllerBridge::Action_LeftTrigger ||
        action == ControllerBridge::Action_RightTrigger);
}

ControllerBridge::ControllerBridge(QObject *parent) : QObject(parent) {

    // initialize SDL
    if (SDL_Init(SDL_INIT_GAMEPAD) < 0) {
        qDebug() << "SDL3 Init Failed: " << SDL_GetError();
    }

    // MAIN TIMER FOR POLLING AT 60Hz
    m_inputTimer = new QTimer(this);
    connect(m_inputTimer, &QTimer::timeout, this, &ControllerBridge::updateInputLoop);
    m_inputTimer->start(16);
    m_groupingTimer = new QTimer(this);
    m_groupingTimer->setSingleShot(true);
    m_groupingTimer->setInterval(25);
    connect(m_groupingTimer, &QTimer::timeout, this, [this]() {
        if (!m_groupedButtons.isEmpty()) {
            m_groupedButtons.sort();
            QString combined = m_groupedButtons.join("+");
            emit historyInputTriggered(combined);
        }
    });

    // getAvailableProfiles() falls back to reporting "Default" even when no
    // profile .ini has ever been written, which meant a fresh install could
    // show "Default" in the profile dropdown while loadProfile("Default")
    // silently failed because profiles/Default.ini didn't exist yet.
    // Guarantee there's always a real file backing the active profile.
    QDir profileCheckDir(getProfilesDir());
    if (profileCheckDir.entryList(QStringList() << "*.ini", QDir::Files).isEmpty()) {
        restoreDefaults(); // populates m_actionMap with the standard layout and saves it as the active ("Default") profile
    }
}

void ControllerBridge::setKeyboardBridge(KeyboardBridge *bridge) {
    m_keyboardBridge = bridge;

    // Connect keyboard updates and remapping triggers
    connect(m_keyboardBridge, &KeyboardBridge::keyboardUpdated, this, [this]() {
        emit controllerUpdated();
    });
    connect(m_keyboardBridge, &KeyboardBridge::keyPressedForRemap, this, [this](int qtKey) {
        if (m_isRemapping) {
            remapKeyboardAction(m_remapAction, qtKey);
            m_isRemapping = false;
            emit remapFinished();
            emit controllerUpdated();
        }
    });
}
void ControllerBridge::setMouseBridge(MouseBridge *bridge) {
    m_mouseBridge = bridge;
}
/*
Reads the current value of a physical controller input.

Every controller mapping is stored as an integer (hardwareId). The range of
that integer tells us what type of input it represents:

 0-99   -> Controller buttons

100-199 -> Positive axis directions (e.g. Right, Down)
200-299 -> Negative axis directions (e.g. Left, Up)
300+    -> Full analog axes (e.g. Triggers)

Based on that range, we read the correct SDL input and return a normalized
value.
*/
float ControllerBridge::getHardwareValue(int hardwareId) const {

    if (!g_gamepad || hardwareId < 0) return 0.0f; // if no controller connected or passed invalid hardware id

    // Physical Buttons (0 to 99)
    // returns either 0 (released) or 1 (pressed)
    if (hardwareId < 100) {
        bool pressed = SDL_GetGamepadButton(g_gamepad, static_cast<SDL_GamepadButton>(hardwareId)); // bool for whether its pressed or not
        return pressed ? 1.0f : 0.0f; // if its pressed return 1 else return 0
    }

    // Positive Axis (100 to 199)
    // reads the axis and ignores movement in the opposite direction. So only right for the x axis and down for the y axis
    if (hardwareId >= 100 && hardwareId < 200) {
        int axisId = hardwareId - 100;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            float rawValue = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
            return std::max(0.0f, rawValue); // basically ignore negative values
        }
    }

    // Negative Axis  (200 to 299)
    // reads the axis and ignores movement in the opposite direction. So only left for the x axis and up for the y axis
    if (hardwareId >= 200 && hardwareId < 300) {
        int axisId = hardwareId - 200;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            float rawValue = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
            return std::max(0.0f, -rawValue); // basically ignore positive values
        }
    }

    // Full Analog Axes (300 and above)
    // Returns the complete axis value without splitting it into positive or negative directions. Used for analog triggers.
    if (hardwareId >= 300) {
        int axisId = hardwareId - 300;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            return SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
        }
    }
    // unknown hardware id or unsupported.
    return 0.0f;
}
void ControllerBridge::updateActionMapping(ControllerAction action, int sdlHardwareId, bool markAsChanged) {
    if (sdlHardwareId == -1) {
        m_actionMap[action] = -1;
        m_keyboardMap.remove(action); // <-- FIX: Also clear the keyboard map so it's truly unmapped
    } else {
        m_actionMap[action] = sdlHardwareId;
        m_keyboardMap.remove(action);
    }

    emit controllerUpdated();

    if (markAsChanged) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }
}
bool ControllerBridge::isHardwareInputPressed(int hardwareId) const {
    if (!g_gamepad || hardwareId < 0) return false;

    // Normal Buttons
    if (hardwareId < 100) {
        return SDL_GetGamepadButton(g_gamepad, static_cast<SDL_GamepadButton>(hardwareId));
    }

    // Positive Axis (using centralized threshold)
    if (hardwareId >= 100 && hardwareId < 200) {
        int axisId = hardwareId - 100;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            float rawValue = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
            return rawValue > kAxisPressThreshold;
        }
    }

    // Negative Axis (using centralized threshold)
    if (hardwareId >= 200 && hardwareId < 300) {
        int axisId = hardwareId - 200;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            float rawValue = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
            return rawValue < -kAxisPressThreshold;
        }
    }

    // Full Analog Axes (using centralized threshold)
    if (hardwareId >= 300) {
        int axisId = hardwareId - 300;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            float rawValue = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(axisId)) / 32767.0f;
            return std::abs(rawValue) > kAxisPressThreshold;
        }
    }

    return false;
}



bool ControllerBridge::isActionPressed(ControllerAction action) const {
    // getActionValue handles buttons, stick directions (pos/neg axes),
    // triggers, and keyboard mappings automatically and returns a float value.
    float value = getActionValue(action);

    // Treat any input with a value passing the threshold as "pressed"
    return std::abs(value) > kTriggerPressThreshold;
}

/* Returns the current analog value of a logical action.
 */
float ControllerBridge::getActionAxis(ControllerAction action) const
{
    // Calculate the left sticks horizontal value from its left and right mappings.
    if (action == Action_LeftStickX) {
        // Calls compound axis helper for left stick x position minus negative
        return getCompoundAxis(Action_LeftStickX_Pos, Action_LeftStickX_Neg);
    }
    // Calculate the left sticks vertical value from its up and down mappings.
    if (action == Action_LeftStickY) {
        // Calls compound axis helper for left stick y position minus negative
        return getCompoundAxis(Action_LeftStickY_Pos, Action_LeftStickY_Neg);
    }
    // Calculate the right sticks horizontal value from its left and right mappings.
    if (action == Action_RightStickX) {
        // Calls compound axis helper for right stick x position minus negative
        return getCompoundAxis(Action_RightStickX_Pos, Action_RightStickX_Neg);
    }
    // Calculate the right sticks vertical value from its up and down mappings.
    if (action == Action_RightStickY) {
        // Calls compound axis helper for right stick y position minus negative
        return getCompoundAxis(Action_RightStickY_Pos, Action_RightStickY_Neg);
    }

    // All remaining analog actions (e.g. triggers) are read directly
    // from the controller mapping.
    if (m_actionMap.contains(action)) {
        // Extracts the raw hardware ID integer mapped to this action
        int hardwareId = m_actionMap.value(action);
        // Checks if the hardware ID is valid and non negative
        if (hardwareId >= 0) {
            // Fetches and returns the analog value from SDL
            return getHardwareValue(hardwareId);
        }
    }
    // Keyboard mappings act like digital inputs, so return either
    // 0.0 (released) or 1.0 (pressed).
    if (m_keyboardMap.contains(action)) {
        // Grabs the mapped Qt key code for this action
        int qtKey = m_keyboardMap.value(action);
        // Asks KeyboardBridge if the key is pressed, returning 1.0f if yes or 0.0f if no
        return m_keyboardBridge->isKeyPressed(qtKey) ? 1.0f : 0.0f;
    }
    // no mapping exists for this action
    // Returns default neutral axis value
    return 0.0f;
}

/*
 Returns the current value of a single mapped stick direction or button.

 The function first checks for a controller mapping, then a keyboard
 mapping. If neither is active, it returns 0.0f.

 Examples:
     Action_LeftStickX_Pos -> Right direction
     Action_LeftStickX_Neg -> Left direction
     Action_A              -> A button
*/
float ControllerBridge::getActionValue(ControllerAction action) const {
    // Check if this action is mapped to a controller input.
    if (m_actionMap.contains(action)) {
        int hardwareId = m_actionMap.value(action);
        if (hardwareId >= 0) {
            return getHardwareValue(hardwareId);
        }
    }

    // Ensure m_keyboardBridge is valid before calling methods on it
    if (m_keyboardBridge && m_keyboardMap.contains(action)) {
        int qtKey = m_keyboardMap.value(action);
        if (m_keyboardBridge->isKeyPressed(qtKey)) {
            return 1.0f;
        }
    }

    return 0.0f;
}

/*
 Combines two opposite stick directions into a single analog value.

 For example, the left stick's X axis is calculated by subtracting the
 left value from the right value, producing a final value between
 -1.0 and 1.0.
*/
float ControllerBridge::getCompoundAxis(ControllerAction posAction, ControllerAction negAction) const
{
    float posVal = getActionValue(posAction);
    float negVal = getActionValue(negAction);

    // Positive - Negative gives the final analog axis value.
    return posVal - negVal;
}

void ControllerBridge::updateInputLoop() {
    // this is the main program loop as we see in the timer in the constructor
    // Here we process SDL events like connection disconnection and stuff
    bool changed = false;
    SDL_Event event;
    while (SDL_PollEvent(&event)) {

        if (event.type == SDL_EVENT_GAMEPAD_REMOVED) {
            // here it checks is that the controller that disconnected the correct one?

            if (g_gamepad && event.gdevice.which == SDL_GetGamepadID(g_gamepad)) {
                SDL_CloseGamepad(g_gamepad); // clean up
                g_gamepad = nullptr; // we no longer have a controller

                m_buttonStates.clear(); // these two fix freezing of inputs in the ui
                m_axisStates.clear();
                // Update connection state
                if (m_deviceConnected) {
                    m_deviceConnected = false;
                    emit deviceConnectedChanged();
                }
                qDebug() << "Controller disconnected! Inputs reset to neutral.";
                emit controllerUpdated(); // emit controllerupdated signal
            }
        }
        else if (event.type == SDL_EVENT_GAMEPAD_ADDED) { // now if one is ADDED
            if (!g_gamepad) { // do we already have one if yes ignore it if no open it
                g_gamepad = SDL_OpenGamepad(event.gdevice.which);
                if (g_gamepad) {
                    qDebug() << "Controller connected:" << SDL_GetGamepadName(g_gamepad);
                    if (!m_deviceConnected) {
                        m_deviceConnected = true;
                        emit deviceConnectedChanged();
                    }
                    emit controllerUpdated();
                }
            }
        }
    }

    // this happens because like what if the controller was connected before the app started? No add event happened during runtime
    if (!g_gamepad) {
        int count = 0;
        SDL_JoystickID* ids = SDL_GetGamepads(&count); // give me every gamepad
        if (count > 0 && ids) {
            g_gamepad = SDL_OpenGamepad(ids[0]); // open the first one
            SDL_free(ids);
            if (g_gamepad) {
                qDebug() << "Found controller on fallback check:" << SDL_GetGamepadName(g_gamepad);
                if (!m_deviceConnected) {
                    m_deviceConnected = true;
                    emit deviceConnectedChanged();
                }
                emit controllerUpdated();
            }
        }
    }

    // listening and remapping
    if (m_isRemapping && g_gamepad) { // if remapping is happening and theres a gamepad
        // Check buttons first
        // WE start at SDL_GAMEPAD_BUTTON_SOUTH because in the enum its like index 0
        for (int b = SDL_GAMEPAD_BUTTON_SOUTH; b < SDL_GAMEPAD_BUTTON_COUNT; ++b) { // loops thru every sdl button to see if thats what they clicked
            if (SDL_GetGamepadButton(g_gamepad, static_cast<SDL_GamepadButton>(b))) { // suppose we clicked right shoulder then it would map to that
                remapAction(m_remapAction, b);
                m_isRemapping = false;
                emit remapFinished();
                emit controllerUpdated();
                return; // stop the function dont check other sticks and all that
            }
        }

        // Check standard axes deflections (detect pushing a stick or trigger using kRemapThreshold)
        for (int a = SDL_GAMEPAD_AXIS_LEFTX; a < SDL_GAMEPAD_AXIS_COUNT; ++a) {
            float value = SDL_GetGamepadAxis(g_gamepad, static_cast<SDL_GamepadAxis>(a)) / 32767.0f;
            // the way this works is this:
            // we loop through all the axes and get their value
            // we wanna see if the user moved that stick enough, as in thats the intended movement.
            // Like if im moving the right stick to the right, itll keep looping and during that itll see
            // that no other value is > 0.6, theyll probably be 0 because they arent the ones im moving.
            if (std::abs(value) > kRemapThreshold) {
                if (isTriggerAction(m_remapAction)) {
                    remapAction(m_remapAction, 300 + a);
                }
                else if (value > kRemapThreshold) { // positive
                    remapAction(m_remapAction, 100 + a);
                }
                else { // negative
                    remapAction(m_remapAction, 200 + a);
                }
                m_isRemapping = false;
                emit remapFinished();
                emit controllerUpdated();
                return;
            }
        }
    }


    // Check if KeyboardBridge is waiting for a controller action
    if (m_keyboardBridge && m_keyboardBridge->isListening() && m_keyboardBridge->activeQtKey() != 0) {
        // Loop through ALL controller actions
        for (int i = 0; i < Action_Count; ++i) {
            ControllerAction action = static_cast<ControllerAction>(i);
            if (isActionPressed(action)) {
                // Map this controller action to the active Qt key
                m_keyboardBridge->setControllerKeyMapping(m_keyboardBridge->activeQtKey(), action);

                // Stop listening and reset state
                m_keyboardBridge->setIsListening(false);
                m_keyboardBridge->setActiveQtKey(0);
                // m_keyboardBridge->saveConfiguration();
                break;
            }
        }
    }

    // Only process physical gamepad button checks if a gamepad is active
    if (g_gamepad) {
        // Update physical button tracking states for change detection & visual history queues
        for (int b = SDL_GAMEPAD_BUTTON_SOUTH; b < SDL_GAMEPAD_BUTTON_COUNT; ++b) {
            bool pressed = SDL_GetGamepadButton(g_gamepad, static_cast<SDL_GamepadButton>(b));
            if (m_buttonStates.value(b, false) != pressed) {
                m_buttonStates[b] = pressed;
                changed = true;

                if (m_historyActive && pressed) {
                    ControllerAction action = Action_Home; // placeholder
                    bool foundAction = false;
                    for (auto it = m_actionMap.begin(); it != m_actionMap.end(); ++it) {
                        if (it.value() == b) {
                            action = it.key();
                            foundAction = true;
                            break;
                        }
                    }

                    if (foundAction) {
                        QString btnName = "";
                        if (action == Action_A) btnName = "A";
                        else if (action == Action_B) btnName = "B";
                        else if (action == Action_X) btnName = "X";
                        else if (action == Action_Y) btnName = "Y";
                        else if (action == Action_L_Shoulder) btnName = "L";
                        else if (action == Action_R_Shoulder) btnName = "R";
                        else if (action == Action_DPadUp) btnName = "D-UP";
                        else if (action == Action_DPadDown) btnName = "D-DOWN";
                        else if (action == Action_DPadLeft) btnName = "D-LEFT";
                        else if (action == Action_DPadRight) btnName = "D-RIGHT";
                        else if (action == Action_LeftStickClick) btnName = "L3";
                        else if (action == Action_RightStickClick) btnName = "R3";
                        else if (action == Action_Home) btnName = "Home";

                        if (!btnName.isEmpty() && !m_groupedButtons.contains(btnName)) {
                            m_groupedButtons.append(btnName);
                            m_groupingTimer->start();
                        }
                    }
                }
            }
        }
    }

    float lX = getActionAxis(Action_LeftStickX);
    float lY = getActionAxis(Action_LeftStickY);
    float rX = getActionAxis(Action_RightStickX);
    float rY = getActionAxis(Action_RightStickY);
    float lT = getActionAxis(Action_LeftTrigger);
    float rT = getActionAxis(Action_RightTrigger);

    // Apply Deadzones to sticks using centralized kDeadzone
    if (std::abs(lX) < kDeadzone) lX = 0.0f;
    if (std::abs(lY) < kDeadzone) lY = 0.0f;
    if (std::abs(rX) < kDeadzone) rX = 0.0f;
    if (std::abs(rY) < kDeadzone) rY = 0.0f;

    // here we're basically comparing the last frame's value of these axes with the current one
    auto updateAxisState = [&](ControllerAction act, float newVal) {
        if (m_axisStates.value(act, 0.0f) != newVal) {
            m_axisStates[act] = newVal;
            changed = true;
        }
    };

    updateAxisState(Action_LeftStickX, lX);
    updateAxisState(Action_LeftStickY, lY);
    updateAxisState(Action_RightStickX, rX);
    updateAxisState(Action_RightStickY, rY);
    updateAxisState(Action_LeftTrigger, lT);
    updateAxisState(Action_RightTrigger, rT);

    // Track historical input events for trigger & directional deflection changes
    if (m_historyActive) {
        bool currentLT = (lT > kAxisPressThreshold);
        static bool lastLT = false;
        if (currentLT != lastLT) {
            lastLT = currentLT;
            changed = true;
            if (currentLT && !m_groupedButtons.contains("ZL")) {
                m_groupedButtons.append("ZL");
                m_groupingTimer->start();
            }
        }

        bool currentRT = (rT > kAxisPressThreshold);
        static bool lastRT = false;
        if (currentRT != lastRT) {
            lastRT = currentRT;
            changed = true;
            if (currentRT && !m_groupedButtons.contains("ZR")) {
                m_groupedButtons.append("ZR");
                m_groupingTimer->start();
            }
        }

        auto checkStickDir = [this](float value, float threshold, const QString& dirName, bool& lastState) {
            bool pressed = (threshold > 0 ? value > threshold : value < threshold);
            if (pressed != lastState) {
                lastState = pressed;
                if (pressed && !m_groupedButtons.contains(dirName)) {
                    m_groupedButtons.append(dirName);
                    m_groupingTimer->start();
                }
            }
        };

        static bool lUp = false, lDown = false, lLeft = false, lRight = false;
        checkStickDir(lY, -kAxisPressThreshold, "UP", lUp);
        checkStickDir(lY, kAxisPressThreshold, "DOWN", lDown);
        checkStickDir(lX, -kAxisPressThreshold, "LEFT", lLeft);
        checkStickDir(lX, kAxisPressThreshold, "RIGHT", lRight);

        static bool rUp = false, rDown = false, rLeft = false, rRight = false;
        checkStickDir(rY, -kAxisPressThreshold, "C-UP", rUp);
        checkStickDir(rY, kAxisPressThreshold, "C-DOWN", rDown);
        checkStickDir(rX, -kAxisPressThreshold, "C-LEFT", rLeft);
        checkStickDir(rX, kAxisPressThreshold, "C-RIGHT", rRight);
    }

    if (changed) {
        emit controllerUpdated();
    }

    if (!m_groupingTimer->isActive() && !m_groupedButtons.isEmpty()) {
        m_groupedButtons.clear();
    }
}

QString ControllerBridge::getConfigFilePath() const {
    return QCoreApplication::applicationDirPath() + "/controls.ini";
}
// In ControllerBridge, add a helper getter if you don't have one yet:
Q_INVOKABLE QString ControllerBridge::getCurrentProfileFileName() const {
    return m_currentProfile + ".ini";
}
QString ControllerBridge::getProfilesDir() const {
    // FIX: Isolate controller profiles into their own folder
    QString path = QCoreApplication::applicationDirPath() + "/profiles/controller";
    QDir dir(path);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    return path;
}
QStringList ControllerBridge::getAvailableProfiles() const {
    QDir dir(getProfilesDir());
    QStringList filters;
    filters << "*.ini";
    QStringList files = dir.entryList(filters, QDir::Files);

    QStringList profiles;
    for (const QString &file : files) {
        profiles.append(file.section('.', 0, 0));
    }

    // Fallback if completely empty
    if (profiles.isEmpty()) {
        profiles.append("Default");
    }
    return profiles;
}

void ControllerBridge::saveCurrentProfile() {
    QString path = getProfilesDir() + "/" + m_currentProfile + ".ini";
    saveMappingConfig(path);
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
}

void ControllerBridge::loadProfile(const QString &name) {
    if (m_currentProfile == name) return;
    QString path = getProfilesDir() + "/" + name + ".ini";
    if (QFile::exists(path)) {
        loadMappingConfig(path);
        m_currentProfile = name;
        emit currentProfileNameChanged();
        emit controllerUpdated();
        m_hasUnsavedChanges = false;
        emit hasUnsavedChangesChanged();
        // Previously this also called m_keyboardBridge->loadProfile(name),
        // cascading into the keyboard side's own profile switch. Removed:
        // the two profile systems are intentionally independent. This,
        // paired with the equivalent call on the KeyboardBridge side,
        // was also the source of an infinite mutual recursion when
        // deleting a profile (KeyboardBridge::deleteProfile() <->
        // ControllerBridge::deleteProfile() had no matching guard and
        // called each other forever, crashing the app).
    } else {
        qDebug() << "loadProfile: no profile file found for" << name;
        emit profileLoadFailed(name);
    }
}
void ControllerBridge::discardChanges() {
    if (m_currentProfile.isEmpty()) return;
    QString path = getProfilesDir() + "/" + m_currentProfile + ".ini";
    if (QFile::exists(path)) {
        loadMappingConfig(path);
        m_hasUnsavedChanges = false;
        emit hasUnsavedChangesChanged();
        emit controllerUpdated();
    }
}
void ControllerBridge::createProfile(const QString &name) {
    if (name.trimmed().isEmpty() || m_currentProfile == name.trimmed()) return;
    saveCurrentProfile();
    m_currentProfile = name.trimmed();
    restoreDefaults();
    saveCurrentProfile();
    emit currentProfileNameChanged();
    emit controllerUpdated();
    // Previously this also called m_keyboardBridge->createProfile(...).
    // Removed for the same reason as loadProfile() above.
}

void ControllerBridge::deleteProfile(const QString &name) {
    QString path = getProfilesDir() + "/" + name + ".ini";
    if (QFile::exists(path)) QFile::remove(path);

    if (m_currentProfile == name) {
        QStringList remaining = getAvailableProfiles();
        if (!remaining.isEmpty()) loadProfile(remaining.first());
        else createProfile("Default");
    }
    emit controllerUpdated();
    // Previously this also unconditionally called m_keyboardBridge->deleteProfile(name),
    // with no guard - and KeyboardBridge::deleteProfile() unconditionally called
    // right back into this function, so deleting any profile recursed between
    // the two forever until the stack overflowed and the app crashed. Removed:
    // the two profile systems are independent, so this side no longer needs to
    // touch KeyboardBridge at all.
}

void ControllerBridge::saveMappingConfig(const QString &filename) {
    // If no filename or a relative filename is given, anchor it right next to the executable
    QString actualFilename = filename.isEmpty() ? "controls.ini" : filename;
    if (QFileInfo(actualFilename).isRelative()) {
        actualFilename = QCoreApplication::applicationDirPath() + "/" + actualFilename;
    }
    qDebug() << "SAVING CONFIG TO:" << actualFilename;
    QSettings settings(actualFilename, QSettings::IniFormat); // create a QSettings object
    settings.beginGroup("Controller_Gamepad"); // This is for organization. Qt writes it under [Gamepadmappings]
    settings.remove(""); // Clears old keys so deleted/changed mappings don't linger

    for (auto it = m_actionMap.begin(); it != m_actionMap.end(); ++it) { // go through every key value in this map
        settings.setValue(QString::number(it.key()), it.value()); // stores them
    }
    settings.endGroup(); // essentially says "finished writing this section"

    // Now we do the exact same thing for keyboard mappings so they don't get lost on restart
    settings.beginGroup("Controller_Keyboard"); // goes into [ControllerKeyboardmappings] section in the ini file
    settings.remove(""); // Clears old keyboard keys
    for (auto it = m_keyboardMap.begin(); it != m_keyboardMap.end(); ++it) { // go through every mapped keyboard action
        settings.setValue(QString::number(it.key()), it.value()); // stores action -> qtKey pair just like before
    }
    settings.endGroup(); // finished writing keyboard section
    settings.sync();
    qDebug() << "Configuration successfully saved to:" << actualFilename; //logging
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
}
void ControllerBridge::loadMappingConfig(const QString &filename) {
    QString actualFilename = filename;

    // If empty, point straight to the default profile in the profiles folder
    if (actualFilename.isEmpty()) {
        actualFilename = getProfilesDir() + "/Default.ini";
    } else {
        QFileInfo fi(actualFilename);
        // If it's just a profile name without slashes (e.g., "Default" or "Custom"), map it to the profiles directory
        if (fi.isRelative() && !actualFilename.contains('/') && !actualFilename.contains('\\')) {
            if (!actualFilename.endsWith(".ini", Qt::CaseInsensitive)) {
                actualFilename += ".ini";
            }
            actualFilename = getProfilesDir() + "/" + actualFilename;
        } else if (fi.isRelative()) {
            actualFilename = QCoreApplication::applicationDirPath() + "/" + actualFilename;
        }
    }

    qDebug() << "LOADING CONFIG FROM:" << actualFilename;

    // Clear old maps so previous profiles don't bleed over!
    m_actionMap.clear();
    m_keyboardMap.clear();

    QSettings settings(actualFilename, QSettings::IniFormat);
    settings.beginGroup("Controller_Gamepad");
    QStringList keys = settings.childKeys();
    for (const QString &keyString : keys) {
        int actionInt = keyString.toInt();
        int sdlButtonId = settings.value(keyString).toInt();
        ControllerAction action = static_cast<ControllerAction>(actionInt);
        updateActionMapping(action, sdlButtonId, false);
    }
    settings.endGroup();

    settings.beginGroup("Controller_Keyboard");
    QStringList kbKeys = settings.childKeys();
    for (const QString &keyString : kbKeys) {
        int actionInt = keyString.toInt();
        int qtKey = settings.value(keyString).toInt();
        ControllerAction action = static_cast<ControllerAction>(actionInt);
        remapKeyboardAction(action, qtKey, false);
    }
    settings.endGroup();

    qDebug() << "Configuration successfully loaded from:" << actualFilename;
    m_hasUnsavedChanges = false;
    emit hasUnsavedChangesChanged();
    emit controllerUpdated();
}

void ControllerBridge::setWindow(QQuickWindow *window) {
    if (m_window != window) {
        m_window = window;
        setClickThrough(m_clickThrough);
    }
}

void ControllerBridge::setClickThrough(bool b) {
    if (m_clickThrough != b) {
        m_clickThrough = b;
        if (m_window) {
            auto flags = m_window->flags();
            m_window->setFlags(m_clickThrough ? (flags | Qt::WindowTransparentForInput) : (flags & ~Qt::WindowTransparentForInput));
        }
        emit clickThroughChanged();
    }
}

void ControllerBridge::setMappingPreset(int p) {
    if (m_mappingPreset != p) { // if the preset changes save the new preset tell qml it changed
        m_mappingPreset = p;
        emit mappingPresetChanged();
    }
}

void ControllerBridge::beginRemap(int action) {
    m_isRemapping = true;   // Now we're saying that the user is remapping. In updateinputloop() we can see how theres the if statement for this.
    m_remapAction = static_cast<ControllerAction>(action);
    qDebug() << "Started remapping for action:" << action;
}

void ControllerBridge::cancelRemap() {
    m_isRemapping = false; // stop waiting
    qDebug() << "Remap cancelled";
}

QString ControllerBridge::getActionMappingName(int action) const { // the point of this func is essentially to have a good representation of the actions in the remapping menu
    ControllerAction act = static_cast<ControllerAction>(action); // qml passes an int, our map uses controllerAction so we just convert

    if (m_keyboardMap.contains(act)) {
        int qtKey = m_keyboardMap.value(act);
        QString keyName = QKeySequence(qtKey).toString();
        return keyName.isEmpty() ? "Key" : keyName.toUpper();
    }
    if (!m_actionMap.contains(act)) { // suppose the user never mapped eg. action_b, then it shows none
        return "None";
    }

    int hardwareId = m_actionMap.value(act); // suppose Action_A -> 1, then hardwareId = 1
    if (hardwareId < 0) { // if smhow the hardware id is negative like -1 or something then display none
        return "None";
    }

    // Physical Buttons
    if (hardwareId < 100) {
        const char* name = SDL_GetGamepadStringForButton(static_cast<SDL_GamepadButton>(hardwareId));

        if (name) {
            QString nameStr = QString::fromUtf8(name);
            if (nameStr == "south") return "A";
            if (nameStr == "east") return "B";
            if (nameStr == "west") return "X";
            if (nameStr == "north") return "Y";
            if (nameStr == "leftshoulder") return "L";
            if (nameStr == "rightshoulder") return "R";
            if (nameStr == "dpup") return "D-Up";
            if (nameStr == "dpdown") return "D-Down";
            if (nameStr == "dpleft") return "D-Left";
            if (nameStr == "dpright") return "D-Right";
            if (nameStr == "leftstick") return "L3";
            if (nameStr == "rightstick") return "R3";
            if (nameStr == "guide") return "Home";

            return nameStr.toUpper();
        }
        return QString("Btn %1").arg(hardwareId);
    }

    // Positive Axis Deflections (QML Name Parsing & Mapping)
    if (hardwareId >= 100 && hardwareId < 200) {
        int axisId = hardwareId - 100;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            const char* name = SDL_GetGamepadStringForAxis(static_cast<SDL_GamepadAxis>(axisId));
            if (name) {
                QString nameStr = QString::fromUtf8(name);
                if (nameStr == "leftx") return "L-Right";
                if (nameStr == "lefty") return "L-Down";
                if (nameStr == "rightx") return "R-Right";
                if (nameStr == "righty") return "R-Down";
                if (nameStr == "lefttrigger") return "ZL";
                if (nameStr == "righttrigger") return "ZR";
                return nameStr.toUpper() + "+";
            }
            return QString("Axis %1+").arg(axisId);
        }
    }

    // Negative Axis Deflections (QML Name Parsing & Mapping)
    if (hardwareId >= 200 && hardwareId < 300) {
        int axisId = hardwareId - 200;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            const char* name = SDL_GetGamepadStringForAxis(static_cast<SDL_GamepadAxis>(axisId));
            if (name) {
                QString nameStr = QString::fromUtf8(name);
                if (nameStr == "leftx") return "L-Left";
                if (nameStr == "lefty") return "L-Up";
                if (nameStr == "rightx") return "R-Left";
                if (nameStr == "righty") return "R-Up";
                if (nameStr == "lefttrigger") return "ZL-";
                if (nameStr == "righttrigger") return "ZR-";
                return nameStr.toUpper() + "-";
            }
            return QString("Axis %1-").arg(axisId);
        }
    }

    // Full Analog Axes (QML Name Parsing & Mapping)
    if (hardwareId >= 300) {
        int axisId = hardwareId - 300;
        if (axisId >= 0 && axisId < SDL_GAMEPAD_AXIS_COUNT) {
            const char* name = SDL_GetGamepadStringForAxis(static_cast<SDL_GamepadAxis>(axisId));
            if (name) {
                QString nameStr = QString::fromUtf8(name);
                if (nameStr == "leftx") return "L-Stick X";
                if (nameStr == "lefty") return "L-Stick Y";
                if (nameStr == "rightx") return "R-Stick X";
                if (nameStr == "righty") return "R-Stick Y";
                if (nameStr == "lefttrigger") return "ZL Axis";
                if (nameStr == "righttrigger") return "ZR Axis";
                return nameStr.toUpper();
            }
            return QString("Axis %1").arg(axisId);
        }
    }

    return "None";
}

// For physical gamepad buttons
void ControllerBridge::remapAction(ControllerAction action, int sdlHardwareId, bool markAsChanged) {
    if (sdlHardwareId == -1) {
        m_actionMap[action] = -1;
    } else {
        m_actionMap[action] = sdlHardwareId;
        m_keyboardMap.remove(action); // Clear conflicting keyboard mapping if physical button is bound
    }

    m_isRemapping = false;
    emit remapFinished();
    emit controllerUpdated();

    if (markAsChanged) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }
}

// For keyboard keys bound to controller actions
void ControllerBridge::remapKeyboardAction(ControllerAction action, int qtKey, bool markAsChanged) {
    bool changed = false;

    if (qtKey == 0 || qtKey == -1) {
        if (m_keyboardMap.contains(action)) {
            m_keyboardMap.remove(action);
            changed = true;
        }
    } else {
        // Check if it's already mapped to this exact key
        if (m_keyboardMap.value(action) != qtKey) {
            m_keyboardMap[action] = qtKey;
            changed = true;
        }

        // Remove any *other* action previously bound to this exact qtKey
        auto it = m_keyboardMap.begin();
        while (it != m_keyboardMap.end()) {
            if (it.key() != action && it.value() == qtKey) {
                it = m_keyboardMap.erase(it);
                changed = true;
            } else {
                ++it;
            }
        }

        if (m_actionMap.contains(action)) {
            m_actionMap.remove(action);
            changed = true;
        }
    }

    m_isRemapping = false;
    emit remapFinished();
    emit controllerUpdated();

    // Only flag as unsaved if something actually changed AND markAsChanged is allowed
    if (changed && markAsChanged) {
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }
}
void ControllerBridge::restoreDefaults() {
    m_actionMap.clear();
    m_keyboardMap.clear();

    // Face Buttons
    remapAction(Action_A, SDL_GAMEPAD_BUTTON_SOUTH);
    remapAction(Action_B, SDL_GAMEPAD_BUTTON_EAST);
    remapAction(Action_X, SDL_GAMEPAD_BUTTON_WEST);
    remapAction(Action_Y, SDL_GAMEPAD_BUTTON_NORTH);

    // D-Pad & Controls
    remapAction(Action_DPadUp, SDL_GAMEPAD_BUTTON_DPAD_UP);
    remapAction(Action_DPadDown, SDL_GAMEPAD_BUTTON_DPAD_DOWN);
    remapAction(Action_DPadLeft, SDL_GAMEPAD_BUTTON_DPAD_LEFT);
    remapAction(Action_DPadRight, SDL_GAMEPAD_BUTTON_DPAD_RIGHT);
    remapAction(Action_L_Shoulder, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER);
    remapAction(Action_R_Shoulder, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
    remapAction(Action_LeftStickClick, SDL_GAMEPAD_BUTTON_LEFT_STICK);
    remapAction(Action_RightStickClick, SDL_GAMEPAD_BUTTON_RIGHT_STICK);
    remapAction(Action_Home, SDL_GAMEPAD_BUTTON_GUIDE);
    remapAction(Action_DPadCenter, -1);

    // Analog sticks
    remapAction(Action_LeftStickY_Neg, 200 + SDL_GAMEPAD_AXIS_LEFTY);
    remapAction(Action_LeftStickY_Pos, 100 + SDL_GAMEPAD_AXIS_LEFTY);
    remapAction(Action_LeftStickX_Neg, 200 + SDL_GAMEPAD_AXIS_LEFTX);
    remapAction(Action_LeftStickX_Pos, 100 + SDL_GAMEPAD_AXIS_LEFTX);

    remapAction(Action_RightStickY_Neg, 200 + SDL_GAMEPAD_AXIS_RIGHTY);
    remapAction(Action_RightStickY_Pos, 100 + SDL_GAMEPAD_AXIS_RIGHTY);
    remapAction(Action_RightStickX_Neg, 200 + SDL_GAMEPAD_AXIS_RIGHTX);
    remapAction(Action_RightStickX_Pos, 100 + SDL_GAMEPAD_AXIS_RIGHTX);

    // Full Analog axis defaults
    remapAction(Action_LeftTrigger, 300 + SDL_GAMEPAD_AXIS_LEFT_TRIGGER);
    remapAction(Action_RightTrigger, 300 + SDL_GAMEPAD_AXIS_RIGHT_TRIGGER);

    // Save into the active profile only
    saveCurrentProfile();
    // REMOVED: saveMappingConfig("controls.ini"); -> Deleted because controls.ini is gone.

    emit controllerUpdated();
    qDebug() << "Mappings restored to standard layout and saved to active profile.";
}

void ControllerBridge::clearAction(int action) {
    ControllerAction act = static_cast<ControllerAction>(action);
    bool modified = false;

    // Instead of removing from m_actionMap entirely, set it to -1 (None)
    // Assuming -1 represents an unmapped / "None" state
    updateActionMapping(act, -1, true);

    // Do the same for keyboard map if applicable
    if (m_keyboardMap.contains(act) && m_keyboardMap[act] != 0) {
        m_keyboardMap[act] = 0; // or -1 depending on your keyboard unmapped value
        modified = true;
    }

    if (modified) {
        emit controllerUpdated();
        m_hasUnsavedChanges = true;
        emit hasUnsavedChangesChanged();
    }
}