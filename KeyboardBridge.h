#pragma once
#include <QObject>
#include <QHash>
#include <QList>
#include <Qt>
#include <QStringList>

class ControllerBridge;
class MouseBridge;

class KeyboardBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isListening READ isListening WRITE setIsListening NOTIFY listeningChanged)
    Q_PROPERTY(int activeQtKey READ activeQtKey WRITE setActiveQtKey NOTIFY activeQtKeyChanged)
    Q_PROPERTY(QString currentProfileName READ currentProfileName NOTIFY currentProfileNameChanged)
    Q_PROPERTY(bool hasUnsavedChanges READ hasUnsavedChanges NOTIFY hasUnsavedChangesChanged)
    Q_PROPERTY(QStringList availableProfiles READ getAvailableProfiles NOTIFY availableProfilesChanged) // ADD THIS

public:
    explicit KeyboardBridge(QObject *parent = nullptr);
    ~KeyboardBridge();

    Q_INVOKABLE bool isKeyPressed(int qtKey) const;
    Q_INVOKABLE void setKeyMapping(int sourceQtKey, int mappedQtKey);
    Q_INVOKABLE int getKeyMapping(int sourceQtKey) const;

    Q_INVOKABLE void saveConfiguration(const QString &filename = QString());
    Q_INVOKABLE void restoreDefaults();
    void loadConfiguration(const QString &filename = QString());

    // Profile Management
    Q_INVOKABLE QString getProfilesDir() const;
    Q_INVOKABLE QStringList getAvailableProfiles() const;
    Q_INVOKABLE void createProfile(const QString &name);
    Q_INVOKABLE void loadProfile(const QString &name);
    Q_INVOKABLE void deleteProfile(const QString &name);
    Q_INVOKABLE void saveCurrentProfile();

    QString currentProfileName() const { return m_currentProfile; }
    bool hasUnsavedChanges() const { return m_hasUnsavedChanges; }
    Q_INVOKABLE void discardChanges();
    void setControllerBridge(ControllerBridge *bridge);
    void setMouseBridge(MouseBridge *mouseBridge);

    Q_INVOKABLE void setControllerKeyMapping(int qtKey, int controllerAction);
    Q_INVOKABLE int getControllerKeyMapping(int qtKey) const;

    bool isListening() const { return m_isListening; }
    void setIsListening(bool listening);
    int activeQtKey() const { return m_activeTargetKey; }
    void setActiveQtKey(int key) {
        if (m_activeTargetKey != key) {
            m_activeTargetKey = key;
            emit activeQtKeyChanged();
        }
    }
    void syncControllerKeyMappings();
signals:
    void keyboardUpdated();
    void keyPressedForRemap(int qtKey);
    void controllerButtonPressedForRemap(int controllerAction);
    void listeningChanged();
    void activeQtKeyChanged();
    void currentProfileNameChanged();
    void hasUnsavedChangesChanged();
    void profileLoadFailed(const QString &name);
    void availableProfilesChanged(); // ADD THIS

public:
    void setKeyboardKeyState(int qtKey, bool pressed);
    int qtKeyToWinVK(int qtKey) const;
    int winVKToQtKey(int vkCode, bool extended) const;
    void handleGlobalKey(int vkCode, bool pressed, bool extended);

private:
    QHash<int, bool> m_keyStates;
    QHash<int, int> m_keyMappings;
    QList<int> m_allVisualKeys;
    ControllerBridge *m_controllerBridge = nullptr;
    MouseBridge *m_mouseBridge = nullptr;
    QHash<int, int> m_controllerKeyMappings;
    bool m_isListening = false;
    int m_activeTargetKey = 0;
    QString m_currentProfile = "Default";
    bool m_hasUnsavedChanges = false;
    // Guards isKeyPressed() against infinite recursion: a key bound to a
    // controller action (m_controllerKeyMappings) asks ControllerBridge if
    // that action is pressed, which can itself be mapped back to a keyboard
    // key (ControllerBridge::m_keyboardMap) and call back into isKeyPressed().
    // If that ever forms a cycle, this stops it from recursing forever.
    mutable bool m_resolvingKeyPress = false;
};