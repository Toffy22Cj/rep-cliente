#ifndef APICONFIG_H
#define APICONFIG_H

#include <QString>

namespace Rep {

class ApiConfig
{
public:
    static QString baseUrl() {
        return "http://localhost:8080/api";
    }
};

} // namespace Rep

#endif // APICONFIG_H
