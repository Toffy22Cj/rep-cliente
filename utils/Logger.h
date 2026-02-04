#ifndef LOGGER_H
#define LOGGER_H

#include <QString>
#include <QFile>
#include <QDateTime>
#include <QTextStream>

namespace Rep {

enum class LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL };

class Logger
{
public:
    static Logger& instance();

    // Log con nivel
    static void log(LogLevel level, const QString &category, const QString &message);

    // Atajos convenientes
    static void debug(const QString &category, const QString &message)
        { log(LogLevel::DEBUG, category, message); }

    static void info(const QString &category, const QString &message)
        { log(LogLevel::INFO, category, message); }

    static void warning(const QString &category, const QString &message)
        { log(LogLevel::WARNING, category, message); }

    static void error(const QString &category, const QString &message)
        { log(LogLevel::ERROR, category, message); }

    static void critical(const QString &category, const QString &message)
        { log(LogLevel::CRITICAL, category, message); }

private:
    Logger();
    ~Logger();
    QFile m_logFile;
    void rotateLogsIfNeeded();
    void openLogFile();
};

} // namespace Rep

#endif // LOGGER_H
