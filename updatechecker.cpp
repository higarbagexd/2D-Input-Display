#include "UpdateChecker.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QUrl>

UpdateChecker::UpdateChecker(QObject *parent) : QObject(parent) {}

void UpdateChecker::checkForUpdates(const QString &currentVersion) {

    m_currentVersion = currentVersion;

    // Updated with your GitHub repo!
    QUrl url("https://api.github.com/repos/higarbagexd/2D-Input-Display/releases/latest");
    QNetworkRequest request(url);

    request.setHeader(QNetworkRequest::UserAgentHeader, "2D-Input-Display-App");

    QNetworkReply *reply = m_networkManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onReplyFinished(reply);
    });
}

void UpdateChecker::onReplyFinished(QNetworkReply *reply) {
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        emit checkFailed(reply->errorString());
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);

    if (!jsonDoc.isObject()) return;

    QJsonObject jsonObject = jsonDoc.object();
    QString latestTag = jsonObject["tag_name"].toString(); // e.g. "v0.2.0"
    QString downloadUrl = jsonObject["html_url"].toString(); // Webpage for the release

    // Strip leading 'v' if present for comparison ("v0.2.0" -> "0.2.0")
    QString cleanCurrent = m_currentVersion;
    QString cleanLatest = latestTag;
    if (cleanCurrent.startsWith('v')) cleanCurrent.remove(0, 1);
    if (cleanLatest.startsWith('v')) cleanLatest.remove(0, 1);

    if (cleanLatest > cleanCurrent) {
        emit updateAvailable(latestTag, downloadUrl);
    } else {
        emit noUpdateFound();
    }
}