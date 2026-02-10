#!/bin/bash

source ./config.env

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

log() {
    echo "$TIMESTAMP : $1" | tee -a "$LOG_FILE"
}

log "Starting health check for $SERVICE_NAME"

#  Service status check
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "$SERVICE_NAME service is running"
else
    log "$SERVICE_NAME service is NOT running. Restarting..."
    systemctl restart "$SERVICE_NAME"
fi

#  Port check
if ss -tulpn | grep -q ":$SERVICE_PORT"; then
    log "Port $SERVICE_PORT is listening"
else
    log "Port $SERVICE_PORT is NOT listening. Restart required..."
    systemctl restart "$SERVICE_NAME"
fi

# HTTP health check
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$HEALTH_ENDPOINT")

if [ "$HTTP_STATUS" -eq 200 ]; then
    log "Health check PASSED (HTTP $HTTP_STATUS)"
else
    log "Health check FAILED (HTTP $HTTP_STATUS). Restarting service..."
    systemctl restart "$SERVICE_NAME"
fi

log "Health check completed"
