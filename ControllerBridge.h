#ifndef CONTROLLERBRIDGE_H
#define CONTROLLERBRIDGE_H

#include "mousebridge.h"
#include <QObject>
#include <QMap>
#include <SDL3/SDL.h>
#include <QQuickWindow>
#include <QTimer>
class KeyboardBridge;
/**
 * This class is essentially a middle man between our SDL input extraction and QML for UI
 **/
class ControllerBridge : public QObject {
    Q_OBJECT

    /* The way Q_PROPERTY works is like this
    Q_PROPERTY(propertyType propertyName READ itsGetter WRITE itsSetter NOTIFY itsSignal

    All of these args arent necessary to be filled. For example:

    Read only
    Q_PROPERTY(int health READ health)

    QML can read it.

    Can't change it.
    ------

    Read + Write

    Q_PROPERTY(
    int health
    READ health
    WRITE setHealth
    )

    QML can change it.
    But if it changes later...
    QML won't know automatically.

    */
    // If we see here we have bool showBackground along with the getter being called showBackground. The property is what Qt thinks it is.
    // if we were to theoretically do controller.showBackground, we would get the getter and that would return m_showBackground which is a private member var

    Q_PROPERTY(bool showBackground READ showBackground WRITE setShowBackground NOTIFY showBackgroundChanged)
    Q_PROPERTY(bool showTitleBar READ showTitleBar WRITE setShowTitleBar NOTIFY showTitleBarChanged)
    Q_PROPERTY(bool clickThrough READ clickThrough WRITE setClickThrough NOTIFY clickThroughChanged)
    Q_PROPERTY(int mappingPreset READ mappingPreset WRITE setMappingPreset NOTIFY mappingPresetChanged)
    Q_PROPERTY(bool historyActive READ historyActive WRITE setHistoryActive NOTIFY historyActiveChanged)
    Q_PROPERTY(bool deviceConnected READ deviceConnected NOTIFY deviceConnectedChanged)
    Q_PROPERTY(QString currentProfileName READ currentProfileName NOTIFY currentProfileNameChanged)
    Q_PROPERTY(bool hasUnsavedChanges READ hasUnsavedChanges NOTIFY hasUnsavedChangesChanged)
public:
    /**
     * This enum is like a dictionary
     * These define every possible input "intent" the app cares about.
     * QML sees these as integers, allowing you to pass them to mapping functions.
     */
    enum ControllerAction {
        Action_A, Action_B, Action_X, Action_Y,
        Action_DPadUp, Action_DPadDown, Action_DPadLeft, Action_DPadRight,
        Action_L_Shoulder, Action_R_Shoulder,
        Action_LeftStickClick, Action_RightStickClick,
        Action_LeftStickX, Action_LeftStickY,
        Action_RightStickX, Action_RightStickY,
        Action_LeftTrigger, Action_RightTrigger,
        // Component actions (used to split axes into individual directions)
        Action_LeftStickY_Neg, Action_LeftStickX_Neg, Action_LeftStickX_Pos, Action_LeftStickY_Pos,
        Action_DPadCenter, Action_Home,
        Action_RightStickY_Neg, Action_RightStickX_Neg, Action_RightStickX_Pos, Action_RightStickY_Pos,
        Action_Count
    };
    Q_ENUM(ControllerAction) // Q_ENUM is a special macro. IT exposes this enum to QML so you can call ControllerBridge.Action_A

    explicit ControllerBridge(QObject *parent = nullptr);

    // --- General Core Logic ---

    // Reads the current value from a mapped hardware input.
    // Returns a float. Buttons : 0 or 1, axes : -1 to 1
    float getHardwareValue(int hardwareId) const;
    // Q_INVOKABLE exposes a function to QML
    // Remaps a logical controller action to a physical controller input.
    void remapAction(ControllerAction action, int sdlHardwareId, bool markAsChanged = true);
    // remaps a logical action to a keybaord key,
    void remapKeyboardAction(ControllerAction action, int qtKey, bool markAsChanged = true);

    // Returns whether the specified logical action is currently pressed.
    Q_INVOKABLE bool isActionPressed(ControllerAction action) const;

    // Returns the current analog value of a logical action.
    // Used for sticks and triggers.
    Q_INVOKABLE float getActionAxis(ControllerAction action) const;
    // helper function to clear
    void clearKeyboardMap() {
        m_keyboardMap.clear();
        emit controllerUpdated();
    }

    // -----------------
    QString getConfigFilePath() const;
    // Loads controller and keyboard mappings from a configuration file.
    Q_INVOKABLE void loadMappingConfig(const QString &filename);

    // Saves the current controller and keyboard mappings to a configuration file.
    Q_INVOKABLE void saveMappingConfig(const QString &filename);
    // For presets
    Q_INVOKABLE QStringList getAvailableProfiles() const;
    Q_INVOKABLE void createProfile(const QString &name);
    Q_INVOKABLE void saveCurrentProfile();
    Q_INVOKABLE void loadProfile(const QString &name);
    Q_INVOKABLE void deleteProfile(const QString &name);
    QString currentProfileName() const { return m_currentProfile; }
    bool hasUnsavedChanges() const { return m_hasUnsavedChanges; }
    // Stores a reference to the application's window.
    // used for keyboard focus and clickthrough related things
    Q_INVOKABLE void setWindow(QQuickWindow *window);

    // --- Remapping Interface ---
    // Begins listening for the next controller or keyboard input to assign
    // to the specified logical action.
    Q_INVOKABLE void beginRemap(int action);

    // Stops the current remapping without making any changes.
    Q_INVOKABLE void cancelRemap();

    // Returns a simple name for the action currently mapped eg 'Space'
    Q_INVOKABLE QString getActionMappingName(int action) const;

    // Restores all controller mappings to the default layout.
    Q_INVOKABLE void restoreDefaults();

    //
    Q_INVOKABLE void clearAction(int action);
    // Getters andSetters
    void setKeyboardBridge(KeyboardBridge *bridge);
    void setMouseBridge(MouseBridge* bridge);
    // Returns whether the controller background should be displayed.
    bool showBackground() const { return m_showBackground; }

    // Enables or disables the controller background.
    void setShowBackground(bool b) { if (m_showBackground != b) { m_showBackground = b; emit showBackgroundChanged(); } }

    // Returns whether the custom title bar is visible.
    bool showTitleBar() const { return m_showTitleBar; }

    // Enables or disables the custom title bar.
    void setShowTitleBar(bool b) { if (m_showTitleBar != b) { m_showTitleBar = b; emit showTitleBarChanged(); } }

    // Returns whether mouse clicks should pass through the overlay window.
    bool clickThrough() const { return m_clickThrough; }

    // Enables or disables click-through mode.
    // The implementation updates the operating system's window flags.
    void setClickThrough(bool b);

    // Returns the currently selected controller mapping preset.
    int mappingPreset() const { return m_mappingPreset; }

    // Changes the active controller mapping preset.
    void setMappingPreset(int p);
    //
    Q_INVOKABLE void discardChanges();
    Q_INVOKABLE QString getCurrentProfileFileName() const;

    // Returns whether input history logging is enabled.
    bool historyActive() const { return m_historyActive; }

    // Enables or disables input history logging.
    void setHistoryActive(bool active) {
        if (m_historyActive != active) {
            m_historyActive = active;
            emit historyActiveChanged();
        }
    }

    // Returns whether a controller is currently connected.
    bool deviceConnected() const { return m_deviceConnected; }

    // Returns the value of a single action component.
    // Used for individual stick directions, triggers, and keyboard mappings.
    float getActionValue(ControllerAction action) const;

signals:

    // Signals emitted to notify QML when controller state or settings change.

    // Emitted whenever controller input or mappings change.
    void controllerUpdated();

    // Emitted when the background visibility changes.
    void showBackgroundChanged();

    // Emitted when the title bar visibility changes.
    void showTitleBarChanged();

    // Emitted when click through mode changes.
    void clickThroughChanged();

    // Emitted when the active mapping preset changes.
    void mappingPresetChanged();
    // Emmitted when the actual profile for mapping changes
    void currentProfileNameChanged();

    // Emitted when a remapping operation finishes.
    void remapFinished();

    // Emitted when a grouped input history entry is ready.
    void historyInputTriggered(const QString &groupedInputs);

    // Emitted when input history is enabled or disabled.
    void historyActiveChanged();

    // Emitted when a controller is connected or disconnected.
    void deviceConnectedChanged();

    // Emitted when loadProfile() is asked to load a profile whose .ini
    // file doesn't actually exist on disk (e.g. stale/renamed profile).
    void profileLoadFailed(const QString &name);
    void hasUnsavedChangesChanged();

private slots:
    // The main loop for the app. Its called by QTimer every 16ms
    void updateInputLoop();
private:
    // --- Helper Methods ---

    // Calculates a blended axis (e.g., Left Stick X) by subtracting two component inputs
    // (Pos - Neg), which allows for smooth analog motion.
    float getCompoundAxis(ControllerAction posAction, ControllerAction negAction) const;

    // Determines if a specific hardware ID is currently "active" (pressed)
    bool isHardwareInputPressed(int hardwareId) const;

    void updateActionMapping(ControllerAction action, int sdlHardwareId, bool markAsChanged = true);

    // --- State Storage ---

    // The Master Mapping: Stores which SDL hardware ID is mapped to which internal Action.
    QMap<ControllerAction, int> m_actionMap;

    // ============================================================================
    // Input Mapping
    // ============================================================================

    // Maps logical actions (e.g. Action_A) to keyboard keys (Qt::Key_*).
    // ControllerBridge queries KeyboardBridge using this map to check if a key is pressed.
    // Also refer to : https://doc.qt.io/qt-6/qt.html#Key-enum
    QMap<ControllerAction, int> m_keyboardMap;

    // ============================================================================
    // Runtime Input State
    // ============================================================================
    // Stores the previous input state so changes can be detected efficiently.

    // Current analog values for each logical action.
    QMap<ControllerAction, float> m_axisStates;

    // Current pressed/released state for each physical controller button.
    QMap<int, bool> m_buttonStates;

    // UI Configuration
    // Overlay appearance and behaviour settings
    bool m_showBackground = true;
    bool m_showTitleBar = true;
    bool m_clickThrough = false;
    int m_mappingPreset = 0;

    // Whether a controller is currently connected
    bool m_deviceConnected = false;

    // Remapping State

    // True while waiting for the user to press the next input.
    bool m_isRemapping = false;

    // The logical action currently being remapped.
    ControllerAction m_remapAction;

    // Window Reference

    // Reference to the application's window.
    // Required for changing window properties such as click through.
    QQuickWindow *m_window = nullptr;
    // For keyboardBridge use in controllerbridge
    KeyboardBridge *m_keyboardBridge = nullptr;
    MouseBridge* m_mouseBridge = nullptr;
    // Timers

    // Main input polling loop (~60 Hz).
    QTimer *m_inputTimer = nullptr;

    // Groups inputs pressed within a short time window (e.g. A+B).
    QTimer *m_groupingTimer = nullptr;

    // Input History

    // Temporarily stores grouped inputs before they're emitted.
    QStringList m_groupedButtons;
    // profile
    QString m_currentProfile = "Default";
    QString getProfilesDir() const;
    // Enables or disables input history logging.
    bool m_historyActive = false;
    bool m_hasUnsavedChanges = false;

};

#endif // CONTROLLERBRIDGE_H