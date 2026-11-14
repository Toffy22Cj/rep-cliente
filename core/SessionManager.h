#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include <QSettings>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include "../models/AuthDTOs.h"
#include "security/SecureTokenStorage.h"

namespace Rep {

/**
 * Sesión del usuario autenticado.
 *
 * El token JWT se guarda en el llavero del sistema (SecureTokenStorage). El perfil
 * básico (id, nombre, rol), que no es sensible, se guarda en QSettings para poder
 * restaurar la sesión al reiniciar la aplicación. Antes solo se restauraba el token,
 * por lo que la app arrancaba "autenticada" pero sin usuario (id 0, rol por defecto).
 */
class SessionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY sessionChanged)
    Q_PROPERTY(QString token READ token NOTIFY sessionChanged)
    Q_PROPERTY(long long userId READ userId NOTIFY sessionChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY sessionChanged)
    Q_PROPERTY(QString userFullName READ userFullName NOTIFY sessionChanged)
    Q_PROPERTY(QString userInitials READ userInitials NOTIFY sessionChanged)
    Q_PROPERTY(QString userRole READ userRole NOTIFY sessionChanged)
    Q_PROPERTY(bool debeCambiarContrasena READ debeCambiarContrasena NOTIFY sessionChanged)

public:
    static SessionManager& instance() {
        static SessionManager inst;
        return inst;
    }

    bool isAuthenticated() const {
        return !m_token.isEmpty() && m_user.id > 0
               && QDateTime::currentSecsSinceEpoch() < m_expiresAt;
    }
    QString token() const { return m_token; }
    long long userId() const { return m_user.id; }
    QString userName() const { return m_user.nombre; }
    QString userFullName() const {
        return (m_user.nombre + QLatin1Char(' ') + m_user.apellido).trimmed();
    }
    QString userInitials() const {
        QString initials;
        if (!m_user.nombre.isEmpty()) initials += m_user.nombre.at(0).toUpper();
        if (!m_user.apellido.isEmpty()) initials += m_user.apellido.at(0).toUpper();
        return initials.isEmpty() ? QStringLiteral("?") : initials;
    }
    QString userRole() const { return roleToString(m_user.rol); }
    bool debeCambiarContrasena() const { return m_user.debeCambiarContrasena; }

    void setSession(const AuthUsuarioDTO &user, const QString &token) {
        m_user = user;
        m_token = token;
        m_expiresAt = jwtExpiry(token);
        // Si el llavero no está disponible la sesión sigue siendo válida en memoria;
        // solo se pierde la restauración automática al reiniciar.
        SecureTokenStorage::instance().saveToken(token);
        saveProfile();
        emit sessionChanged();
    }

    /** Sustituye el token (p. ej. tras cambiar la contraseña, que invalida el anterior). */
    /** Tras cambiar la contraseña provisional (no se guarda en el perfil local). */
    Q_INVOKABLE void contrasenaCambiada() {
        if (!m_user.debeCambiarContrasena) return;
        m_user.debeCambiarContrasena = false;
        emit sessionChanged();
    }

    Q_INVOKABLE void actualizarToken(const QString &token) {
        m_token = token;
        m_expiresAt = jwtExpiry(token);
        SecureTokenStorage::instance().saveToken(token);
        emit sessionChanged();
    }

    /** Refleja en la sesión los datos editados en el perfil. */
    Q_INVOKABLE void actualizarDatos(const QString &nombre, const QString &apellido, const QString &correo) {
        m_user.nombre = nombre;
        m_user.apellido = apellido;
        m_user.correo = correo;
        saveProfile();
        emit sessionChanged();
    }

    Q_INVOKABLE void clear() {
        const bool hadSession = !m_token.isEmpty();
        m_user = {};
        m_token.clear();
        m_expiresAt = 0;
        SecureTokenStorage::instance().deleteToken();
        QSettings().remove(QStringLiteral("session"));
        if (hadSession)
            emit sessionChanged();
    }

    static QString roleToString(Rol rol) {
        switch (rol) {
        case Rol::ADMIN:    return QStringLiteral("ADMIN");
        case Rol::PROFESOR: return QStringLiteral("PROFESOR");
        default:            return QStringLiteral("ESTUDIANTE");
        }
    }

    static Rol roleFromString(const QString &value) {
        const QString v = value.trimmed().toUpper();
        if (v == QLatin1String("ADMIN")) return Rol::ADMIN;
        if (v == QLatin1String("PROFESOR")) return Rol::PROFESOR;
        return Rol::ESTUDIANTE;
    }

signals:
    void sessionChanged();

private:
    explicit SessionManager(QObject *parent = nullptr) : QObject(parent) {
        restore();
    }

    void saveProfile() const {
        QSettings s;
        s.beginGroup(QStringLiteral("session"));
        s.setValue("id", m_user.id);
        s.setValue("nombre", m_user.nombre);
        s.setValue("apellido", m_user.apellido);
        s.setValue("correo", m_user.correo);
        s.setValue("identificacion", m_user.identificacion);
        s.setValue("rol", roleToString(m_user.rol));
        s.endGroup();
    }

    void restore() {
        QSettings s;
        s.beginGroup(QStringLiteral("session"));
        AuthUsuarioDTO user;
        user.id = s.value("id", 0).toLongLong();
        user.nombre = s.value("nombre").toString();
        user.apellido = s.value("apellido").toString();
        user.correo = s.value("correo").toString();
        user.identificacion = s.value("identificacion").toString();
        user.rol = roleFromString(s.value("rol").toString());
        s.endGroup();
        if (user.id <= 0)
            return;

        const QString token = SecureTokenStorage::instance().getToken();
        const qint64 expiresAt = jwtExpiry(token);
        if (token.isEmpty() || QDateTime::currentSecsSinceEpoch() >= expiresAt)
            return;
        m_user = user;
        m_token = token;
        m_expiresAt = expiresAt;
    }

    /**
     * Lee la claim "exp" (segundos epoch) del JWT. La firma la valida el servidor;
     * aquí solo se usa para saber cuándo dejar de considerar válida la sesión local.
     * Si no puede leerse, se asume una validez de 24 h.
     */
    static qint64 jwtExpiry(const QString &token) {
        const QStringList parts = token.split(QLatin1Char('.'));
        if (parts.size() == 3) {
            const QByteArray payload = QByteArray::fromBase64(
                parts.at(1).toUtf8(), QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
            const qint64 exp = QJsonDocument::fromJson(payload).object().value("exp").toVariant().toLongLong();
            if (exp > 0)
                return exp;
        }
        return token.isEmpty() ? 0 : QDateTime::currentSecsSinceEpoch() + 24 * 3600;
    }

    AuthUsuarioDTO m_user;
    QString m_token;
    qint64 m_expiresAt = 0;
};

} // namespace Rep

#endif // SESSIONMANAGER_H
