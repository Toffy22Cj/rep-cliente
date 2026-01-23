#ifndef LOGINVIEWMODEL_H
#define LOGINVIEWMODEL_H

#include <QObject>
#include "../api/AuthService.h"

namespace Rep {

class LoginViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit LoginViewModel(QObject *parent = nullptr);

    bool isLoading() const { return m_isLoading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void login(const QString &identificacion, const QString &password);

signals:
    void isLoadingChanged();
    void errorMessageChanged();
    void loginSuccess(const QString &role);

private:
    AuthService *m_authService;
    bool m_isLoading = false;
    QString m_errorMessage;
};

} // namespace Rep

#endif // LOGINVIEWMODEL_H
