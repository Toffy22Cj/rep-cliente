#include "Logger.h"
#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <iostream>

namespace Rep {

Logger& Logger::instance()
{
    static Logger inst;
    return inst;
}

Logger::Logger()
{
    openLogFile();
}

Logger::~Logger()
{
    if (m_logFile.isOpen()) {
        m_logFile.close();
    }
}

void Logger::openLogFile()
{
    QString logPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(logPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    m_logFile.setFileName(dir.filePath("rep_client.log"));
    if (!m_logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        std::cerr << "Failed to open log file: " << m_logFile.errorString().toStdString() << std::endl;
    }
}

void Logger::log(LogLevel level, const QString &category, const QString &message)
{
    QString levelStr;
    switch (level) {
        case LogLevel::DEBUG: levelStr = "DEBUG"; break;
        case LogLevel::INFO: levelStr = "INFO"; break;
        case LogLevel::WARNING: levelStr = "WARN"; break;
        case LogLevel::ERROR: levelStr = "ERROR"; break;
        case LogLevel::CRITICAL: levelStr = "CRITICAL"; break;
    }

    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
    QString logLine = QString("[%1] [%2] [%3] %4").arg(timestamp, levelStr, category, message);

    // Print to console
    std::cout << logLine.toStdString() << std::endl;

    // Write to file
    if (instance().m_logFile.isOpen()) {
        QTextStream out(&instance().m_logFile);
        out << logLine << "\n";
    }
}

void Logger::rotateLogsIfNeeded()
{
    // Rotation logic can be added here (e.g. check file size)
    if (m_logFile.size() > 10 * 1024 * 1024) { // 10MB
        m_logFile.close();
        QString newName = m_logFile.fileName() + "." + QDateTime::currentDateTime().toString("yyyyMMddHHmmss");
        QFile::rename(m_logFile.fileName(), newName);
        openLogFile();
    }
}

} // namespace Rep
