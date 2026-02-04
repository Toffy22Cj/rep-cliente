#include "BaseService.h"
#include "ApiConfig.h"

namespace Rep {

BaseService::BaseService(QObject *parent) : QObject(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
}

QNetworkRequest BaseService::createRequest(const QUrl &url, const QString &token)
{
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    // request.setTransferTimeout(ApiConfig::requestTimeout()); // If requestTimeout exists

    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }
    
    return request;
}

} // namespace Rep
