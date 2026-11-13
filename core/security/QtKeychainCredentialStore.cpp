#include "QtKeychainCredentialStore.h"
#include <qt6keychain/keychain.h>
#include <QEventLoop>
#include <QDebug>

namespace Rep::Security {

QtKeychainCredentialStore::QtKeychainCredentialStore(QObject *parent)
    : QObject(parent)
{
}

bool QtKeychainCredentialStore::saveToken(const QString &service, const QString &key, const QString &token)
{
    QKeychain::WritePasswordJob job(service);
    job.setAutoDelete(false);
    job.setKey(key);
    job.setTextData(token);

    QEventLoop loop;
    connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        qCritical() << "QtKeychainCredentialStore::saveToken Error:" << job.errorString();
        return false;
    }
    return true;
}

QString QtKeychainCredentialStore::loadToken(const QString &service, const QString &key)
{
    QKeychain::ReadPasswordJob job(service);
    job.setAutoDelete(false);
    job.setKey(key);

    QEventLoop loop;
    connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        qWarning() << "QtKeychainCredentialStore::loadToken Error (may not be found):" << job.errorString();
        return QString();
    }
    return job.textData();
}

bool QtKeychainCredentialStore::deleteToken(const QString &service, const QString &key)
{
    QKeychain::DeletePasswordJob job(service);
    job.setAutoDelete(false);
    job.setKey(key);

    QEventLoop loop;
    connect(&job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    job.start();
    loop.exec();

    if (job.error() != QKeychain::NoError) {
        qCritical() << "QtKeychainCredentialStore::deleteToken Error:" << job.errorString();
        return false;
    }
    return true;
}

} // namespace Rep::Security
