#ifndef BASESERVICE_H
#define BASESERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QUrl>

namespace Rep {

class BaseService : public QObject
{
    Q_OBJECT
public:
    explicit BaseService(QObject *parent = nullptr);

protected:
    QNetworkRequest createRequest(const QUrl &url, const QString &token);
    QNetworkAccessManager* m_networkManager;
};

} // namespace Rep

#endif // BASESERVICE_H
