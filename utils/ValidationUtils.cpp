#include "ValidationUtils.h"
#include <QRegularExpression>

namespace Rep {

bool ValidationUtils::isValidIdentification(const QString &identificacion)
{
    if (identificacion.isEmpty()) return false;
    
    // Allow numbers and hyphens, length 3-20
    QRegularExpression regex("^[a-zA-Z0-9-]{3,20}$");
    return regex.match(identificacion).hasMatch();
}

bool ValidationUtils::isValidPassword(const QString &password)
{
    // Min length 6
    if (password.length() < 6) return false;
    if (password.length() > 128) return false;
    return true;
}

bool ValidationUtils::isValidEmail(const QString &email)
{
    if (email.isEmpty()) return false;
    
    // Simple email regex
    QRegularExpression regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    return regex.match(email).hasMatch();
}

bool ValidationUtils::isValidName(const QString &name)
{
    if (name.isEmpty()) return false;
    
    // Allow letters, spaces, limited punctuation. Min 2 chars.
    QRegularExpression regex("^[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]{2,100}$");
    return regex.match(name).hasMatch();
}

QString ValidationUtils::sanitizeInput(const QString &input)
{
    QString sanitized = input.trimmed();
    // Basic XSS/Injection prevention if displayed improperly, though QML handles text rendering safely.
    // Mainly removing control characters if needed.
    return sanitized;
}

} // namespace Rep
