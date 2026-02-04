#ifndef AUTHSERVICE_H
#define AUTHSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "BaseService.h"
#include "../models/AuthDTOs.h"

namespace Rep {

class AuthService : public BaseService
{
    Q_OBJECT
public:
    explicit AuthService(QObject *parent = nullptr);
    void login(const QString &identificacion, const QString &password);

signals:
    void loginFinished(const LoginResponse &response);
    void errorOccurred(const QString &error);

private slots:
    void onLoginReply(QNetworkReply *reply);

private:
    // QNetworkAccessManager *m_networkManager; // Inherited from BaseService
};

} // namespace Rep

#endif // AUTHSERVICE_H
