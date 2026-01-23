#include "LoginViewModel.h"
#include "../core/SessionManager.h"

namespace Rep {

LoginViewModel::LoginViewModel(QObject *parent)
    : QObject(parent), m_authService(new AuthService(this))
{
    connect(m_authService, &AuthService::loginFinished, this, [this](const LoginResponse &response) {
        m_isLoading = false;
        emit isLoadingChanged();

        if (response.success) {
            SessionManager::instance().setSession(response.usuario, response.token);
            QString roleStr = "ESTUDIANTE";
            if (response.usuario.rol == Rol::PROFESOR) roleStr = "PROFESOR";
            else if (response.usuario.rol == Rol::ADMIN) roleStr = "ADMIN";
            emit loginSuccess(roleStr);
        } else {
            m_errorMessage = response.mensaje;
            emit errorMessageChanged();
        }
    });

    connect(m_authService, &AuthService::errorOccurred, this, [this](const QString &error) {
        m_isLoading = false;
        m_errorMessage = error;
        emit isLoadingChanged();
        emit errorMessageChanged();
    });
}

void LoginViewModel::login(const QString &identificacion, const QString &password)
{
    if (m_isLoading) return;

    m_isLoading = true;
    m_errorMessage.clear();
    emit isLoadingChanged();
    emit errorMessageChanged();

    m_authService->login(identificacion, password);
}

} // namespace Rep
