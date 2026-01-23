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
    static SessionManager& instance() {
        static SessionManager inst;
        return inst;
    }

    bool isAuthenticated() const { return !m_token.isEmpty(); }
    QString token() const { return m_token; }
    long long userId() const { return m_user.id; }
    QString userName() const { return m_user.nombre; }
    QString userRole() const {
        if (m_user.rol == Rol::ADMIN) return "ADMIN";
        if (m_user.rol == Rol::PROFESOR) return "PROFESOR";
        return "ESTUDIANTE";
    }

    void setSession(const AuthUsuarioDTO &user, const QString &token) {
        m_user = user;
        m_token = token;
        emit sessionChanged();
    }

    Q_INVOKABLE void clear() {
        m_user = {};
        m_token.clear();
        emit sessionChanged();
    }

signals:
    void sessionChanged();

private:
    SessionManager(QObject *parent = nullptr) : QObject(parent) {}
    AuthUsuarioDTO m_user;
    QString m_token;
};

} // namespace Rep

#endif // SESSIONMANAGER_H
