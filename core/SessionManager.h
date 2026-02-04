#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include "../models/AuthDTOs.h"
#include "security/SecureTokenStorage.h"

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
    static SessionManager& instance() {
        static SessionManager inst;
        return inst;
    }

    bool isAuthenticated() const { 
        return !token().isEmpty() && !SecureTokenStorage::instance().isTokenExpired(); 
    }
    QString token() const { return SecureTokenStorage::instance().getToken(); }
    long long userId() const { return m_user.id; }
    QString userName() const { return m_user.nombre; }
    QString userRole() const {
        QString r = "ESTUDIANTE";
        if (m_user.rol == Rol::ADMIN) r = "ADMIN";
        else if (m_user.rol == Rol::PROFESOR) r = "PROFESOR";
        qDebug() << "SessionManager::userRole called. Stored Rol enum value:" << (int)m_user.rol << "Returning string:" << r;
        return r;
    }

    void setSession(const AuthUsuarioDTO &user, const QString &token) {
        m_user = user;
        SecureTokenStorage::instance().saveToken(token);
        emit sessionChanged();
    }

    Q_INVOKABLE void clear() {
        m_user = {};
        SecureTokenStorage::instance().deleteToken();
        emit sessionChanged();
    }

signals:
    void sessionChanged();

private:
    SessionManager(QObject *parent = nullptr) : QObject(parent) {}

    AuthUsuarioDTO m_user;
};

} // namespace Rep

#endif // SESSIONMANAGER_H
