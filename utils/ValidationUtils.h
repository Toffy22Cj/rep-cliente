#ifndef VALIDATIONUTILS_H
#define VALIDATIONUTILS_H

#include <QString>

namespace Rep {

class ValidationUtils
{
public:
    static bool isValidIdentification(const QString &identificacion);
    static bool isValidPassword(const QString &password);
    static bool isValidEmail(const QString &email);
    static bool isValidName(const QString &name);
    
    // Sanitization
    static QString sanitizeInput(const QString &input);
};

} // namespace Rep

#endif // VALIDATIONUTILS_H
