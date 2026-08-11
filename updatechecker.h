#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>

class UpdateChecker : public QObject {
    Q_OBJECT
public:
    explicit UpdateChecker(QObject *parent = nullptr);

    // Call this from QML or C++ to check GitHub
    Q_INVOKABLE void checkForUpdates(const QString &currentVersion);

signals:
    void updateAvailable(const QString &latestVersion, const QString &downloadUrl);
    void noUpdateFound();
    void checkFailed(const QString &error);

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager m_networkManager;
    QString m_currentVersion;
};

#endif // UPDATECHECKER_H