#pragma once

#include <QObject>
#include <QMap>
#include <QString>
#include <QStringList>

class KeyboardBridge;
class ControllerBridge;

class MouseBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(double dotX READ dotX NOTIFY mouseUpdated)
    Q_PROPERTY(double dotY READ dotY NOTIFY mouseUpdated)
    Q_PROPERTY(double maxRadius READ maxRadius WRITE setMaxRadius NOTIFY maxRadiusChanged)

    // Raw hardware state: is the physical button literally down right now.
    Q_PROPERTY(bool leftPressed READ isLeftPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool rightPressed READ isRightPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool middlePressed READ isMiddlePressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool upperPressed READ isUpperPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool lowerPressed READ isLowerPressed NOTIFY mouseUpdated)

    Q_PROPERTY(bool isListening READ isListening WRITE setIsListening NOTIFY listeningChanged)
    Q_PROPERTY(int activePseudoKey READ activePseudoKey WRITE setActivePseudoKey NOTIFY activePseudoKeyChanged)

    // Effective/visual state: accounts for keyboard-key, controller-action, or other-mouse-button mappings.
    Q_PROPERTY(bool effectiveLeftPressed READ isEffectiveLeftPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool effectiveRightPressed READ isEffectiveRightPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool effectiveMiddlePressed READ isEffectiveMiddlePressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool effectiveUpperPressed READ isEffectiveUpperPressed NOTIFY mouseUpdated)
    Q_PROPERTY(bool effectiveLowerPressed READ isEffectiveLowerPressed NOTIFY mouseUpdated)

    Q_PROPERTY(int activeRemapButtonId READ activeRemapButtonId WRITE setActiveRemapButtonId NOTIFY activeRemapButtonIdChanged)

    Q_PROPERTY(bool hasUnsavedChanges READ hasUnsavedChanges NOTIFY hasUnsavedChangesChanged)
    Q_PROPERTY(QString currentProfileName READ currentProfileName WRITE setCurrentProfileName NOTIFY currentProfileNameChanged)

public:
    explicit MouseBridge(QObject *parent = nullptr);
    ~MouseBridge();

    double dotX() const { return m_dotX; }
    double dotY() const { return m_dotY; }

    double maxRadius() const { return m_maxRadius; }
    void setMaxRadius(double radius);

    int activeRemapButtonId() const { return m_activeRemapButtonId; }
    void setActiveRemapButtonId(int id);

    bool isLeftPressed() const { return m_leftPressed; }
    bool isRightPressed() const { return m_rightPressed; }
    bool isMiddlePressed() const { return m_middlePressed; }
    bool isUpperPressed() const { return m_upperPressed; }
    bool isLowerPressed() const { return m_lowerPressed; }

    bool isEffectiveLeftPressed() const { return isEffectivelyPressed(0); }
    bool isEffectiveRightPressed() const { return isEffectivelyPressed(1); }
    bool isEffectiveMiddlePressed() const { return isEffectivelyPressed(2); }
    bool isEffectiveLowerPressed() const { return isEffectivelyPressed(3); }
    bool isEffectiveUpperPressed() const { return isEffectivelyPressed(4); }

    bool isListening() const { return m_isListening; }
    void setIsListening(bool listening);

    bool hasUnsavedChanges() const { return m_hasUnsavedChanges; }
    Q_INVOKABLE void discardChanges();
    Q_INVOKABLE void saveCurrentProfile();
    Q_INVOKABLE void loadProfile(const QString &profileName);
    Q_INVOKABLE QStringList getAvailableProfiles() const;
    Q_INVOKABLE void createProfile(const QString &profileName);
    Q_INVOKABLE void deleteProfile(const QString &profileName);
    QString getProfilesDir() const;

    QString currentProfileName() const { return m_currentProfileName; }
    void setCurrentProfileName(const QString &name);

    int activePseudoKey() const { return m_activePseudoKey; }
    void setActivePseudoKey(int key) {
        if (m_activePseudoKey != key) {
            m_activePseudoKey = key;
            emit activePseudoKeyChanged();
        }
    }
    Q_INVOKABLE void clearUnsavedChanges();

    // Helpers for QML to check press states by button ID string.
    Q_INVOKABLE bool isButtonPressed(const QString &btnId) const;
    Q_INVOKABLE bool isButtonEffectivelyPressed(const QString &btnId) const;

    // --- Keyboard-key or mouse-button source mapping ---
    Q_INVOKABLE int getMouseMapping(int buttonId) const;
    Q_INVOKABLE void setMouseMapping(int buttonId, int mappedKey);

    // --- Controller-action source mapping ---
    Q_INVOKABLE int getMouseControllerMapping(int buttonId) const;
    Q_INVOKABLE void setMouseControllerMapping(int buttonId, int controllerAction);

    // Clears mappings on a single button or all buttons
    Q_INVOKABLE void clearMouseMapping(int buttonId);
    Q_INVOKABLE void clearAllMouseMappings();

    void handleMouseMovement(int dx, int dy);
    void setButtonState(int buttonId, bool pressed);

    // Wiring
    void setKeyboardBridge(KeyboardBridge *bridge);
    void setControllerBridge(ControllerBridge *bridge);

signals:
    void mouseUpdated();
    void maxRadiusChanged();
    void mappingChanged();
    void mouseButtonPressedForRemap(int pseudoQtKey);
    void activeRemapButtonIdChanged();
    void listeningChanged();
    void activePseudoKeyChanged();
    void hasUnsavedChangesChanged();
    void currentProfileNameChanged();

private:
    bool isEffectivelyPressed(int buttonId) const;
    bool isEffectivelyPressedInternal(int buttonId, QSet<int> &visited) const;
    bool rawStateForButtonId(int buttonId) const;
    static bool isMousePseudoKey(int code);
    static int pseudoKeyForButtonId(int buttonId);
    static int buttonIdForPseudoKey(int pseudoKey);

    double m_dotX = 0.0;
    double m_dotY = 0.0;
    double m_maxRadius = 50.0;

    double m_accumulatedDx = 0.0;
    double m_accumulatedDy = 0.0;

    bool m_leftPressed = false;
    bool m_rightPressed = false;
    bool m_middlePressed = false;
    bool m_upperPressed = false;
    bool m_lowerPressed = false;

    int m_activeRemapButtonId = -1;
    QMap<int, int> m_mouseMappings;             // buttonId -> Qt key / mouse pseudo-key
    QMap<int, int> m_mouseControllerMappings;   // buttonId -> ControllerAction

    KeyboardBridge *m_keyboardBridge = nullptr;
    ControllerBridge *m_controllerBridge = nullptr;

    bool m_isListening = false;
    int m_activePseudoKey = 0;
    QString m_currentProfileName = "Default";
    bool m_hasUnsavedChanges = false;
};