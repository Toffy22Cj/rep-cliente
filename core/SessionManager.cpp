#include "SessionManager.h"
#include "../utils/SecureTokenStorage.h"
#include <QDebug>

namespace Rep {

SessionManager& SessionManager::instance() {
    static SessionManager inst;
    return inst;
}

SessionManager::SessionManager(QObject *parent) : QObject(parent) {
    // Attempt to restore session from secure storage
    if (SecureTokenStorage::hasToken()) {
        m_token = SecureTokenStorage::getToken();
        qDebug() << "SessionManager: Restored token from secure storage";
    }
}

bool SessionManager::isAuthenticated() const { 
    return !m_token.isEmpty(); 
}

QString SessionManager::token() const { 
    return m_token; 
}

long long SessionManager::userId() const { 
    return m_user.id; 
}

QString SessionManager::userName() const { 
    return m_user.nombre; 
}

QString SessionManager::userRole() const {
    QString r = "ESTUDIANTE";
    if (m_user.rol == Rol::ADMIN) r = "ADMIN";
    else if (m_user.rol == Rol::PROFESOR) r = "PROFESOR";
    return r;
}

void SessionManager::setSession(const AuthUsuarioDTO &user, const QString &token) {
    m_user = user;
    m_token = token;
    
    // Persist token securely
    if (!token.isEmpty()) {
        SecureTokenStorage::saveToken(token);
    }
    
    emit sessionChanged();
}

void SessionManager::clear() {
    m_user = {};
    m_token.clear();
    
    // Remove from secure storage
    SecureTokenStorage::deleteToken();
    
    emit sessionChanged();
}

} // namespace Rep
