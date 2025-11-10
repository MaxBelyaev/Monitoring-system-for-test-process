#!/bin/bash

PROCESS_NAME="test"
MONITORING_URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
PID_FILE="/run/monitoring_test/monitoring_test.pid"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверяем запущен ли процесс
if ! pgrep -x "$PROCESS_NAME" > /dev/null; then
    # Процесс не запущен, удаляем PID-файл если существует
    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
    exit 0
fi

# Получаем текущий PID процесса
CURRENT_PID=$(pgrep -x "$PROCESS_NAME")

# Проверяем наличие предыдущего PID
if [ -f "$PID_FILE" ]; then
    PREVIOUS_PID=$(cat "$PID_FILE")
    if [ "$CURRENT_PID" != "$PREVIOUS_PID" ]; then
        log_message "PROCESS RESTARTED - New PID: $CURRENT_PID"
    fi
else
    log_message "PROCESS STARTED - PID: $CURRENT_PID"
fi

# Сохраняем текущий PID
echo "$CURRENT_PID" > "$PID_FILE"

# Отправляем запрос к серверу мониторинга
if ! curl -sf -H "Connection: close" --max-time 10 "$MONITORING_URL" > /dev/null; then
    log_message "MONITORING SERVER UNREACHABLE"
fi
