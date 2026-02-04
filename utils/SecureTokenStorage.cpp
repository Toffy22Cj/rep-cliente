#include "SecureTokenStorage.h"
#include <qt6keychain/keychain.h> 
#include <QEventLoop>
#include <QDebug>
#include <QCoreApplication>

namespace Rep {

void SecureTokenStorage::saveToken(const QString &token)
{
    QKeychain::WritePasswordJob job(QLatin1String("RepClient"));
    job.setAutoDelete(false);
    job.setKey(QLatin1String("auth_token"));
    job.setTextData(token);
    
    QEventLoop loop;
    job.connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();
    
    if (job.error()) {
        qWarning() << "SecureTokenStorage: Error saving token:" << job.errorString();
    }
}

QString SecureTokenStorage::getToken()
{
    QKeychain::ReadPasswordJob job(QLatin1String("RepClient"));
    job.setAutoDelete(false);
    job.setKey(QLatin1String("auth_token"));
    
    QEventLoop loop;
    job.connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error()) {
         if (job.error() != QKeychain::Error::EntryNotFound) {
             qWarning() << "SecureTokenStorage: Error reading token:" << job.errorString();
         }
         return QString();
    }
    
    return job.textData();
}

void SecureTokenStorage::deleteToken()
{
    QKeychain::DeletePasswordJob job(QLatin1String("RepClient"));
    job.setAutoDelete(false);
    job.setKey(QLatin1String("auth_token"));
    
    QEventLoop loop;
    job.connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();
}

bool SecureTokenStorage::hasToken()
{
    return !getToken().isEmpty();
}

bool SecureTokenStorage::isTokenExpired()
{
    return !hasToken();
}

} // namespace Rep
