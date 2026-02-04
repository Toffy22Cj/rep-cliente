#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include "../models/AuthDTOs.h"

namespace Rep {

class SessionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY sessionChanged)
    Q_PROPERTY(QString token READ token NOTIFY sessionChanged)
    Q_PROPERTY(long long userId READ userId NOTIFY sessionChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY sessionChanged)
    Q_PROPERTY(QString userRole READ userRole NOTIFY sessionChanged)

public:
    static SessionManager& instance();

    bool isAuthenticated() const;
    QString token() const;
    long long userId() const;
    QString userName() const;
    QString userRole() const;

    void setSession(const AuthUsuarioDTO &user, const QString &token);

    Q_INVOKABLE void clear();

signals:
    void sessionChanged();

private:
    SessionManager(QObject *parent = nullptr);
    AuthUsuarioDTO m_user;
    QString m_token;
};

} // namespace Rep

#endif // SESSIONMANAGER_H
