#!/usr/bin/env bash

SERVICE_LOG_DIR=${SERVICE_LOG_DIR:-${SERVICE_HOME}"/log"}
SERVICE_LOG_FILE=${SERVICE_LOG_FILE:-${SERVICE_LOG_DIR}"/pgsql.log"}

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"postgres"}
POSTGRES_USER=${POSTGRES_USER:-"postgres"}
PGDATA=${PGDATA:-${SERVICE_HOME}"/data"}
POSTGRES_DB=${POSTGRES_DB:-"postgres"}
POSTGRES_INITDB_ARGS=${POSTGRES_INITDB_ARGS:-"-E UTF8"}

export ZOO_LOG_DIR=${SERVICE_LOG_DIR}

function log {
        echo `date` $ME - $@
}

function serviceDefault {
    log "[ Applying default ${SERVICE_NAME} configuration... ]"
    ${SERVICE_HOME}/bin/pg_ctl initdb -D ${PGDATA} -o "${POSTGRES_INITDB_ARGS}"
}

function serviceConf {
    log "[ Applying dinamic ${SERVICE_NAME} configuration... ]"
    while [ ! -f ${SERVICE_CONF} ]; do
        log "  Waiting for ${SERVICE_NAME} configuration..."
        sleep 5
    done
}

function serviceLog {
    log "[ Redirecting ${SERVICE_NAME} log to stdout... ]"
    if [ ! -L ${SERVICE_LOG_FILE} ]; then
        rm ${SERVICE_LOG_FILE}
        ln -sf /proc/1/fd/1 ${SERVICE_LOG_FILE}
    fi
}

function serviceCheck {
    log "[ Checking ${SERVICE_NAME} configuration... ]"

    if [ -d "${SERVICE_VOLUME}" ]; then
        serviceConf
    else
        serviceDefault
    fi
}

function serviceStart {
    log "[ Starting ${SERVICE_NAME}... ]"
    serviceCheck
    serviceLog
    ${SERVICE_HOME}/bin/pg_ctl start -w -t 60 -D ${PGDATA} -l ${SERVICE_LOG_FILE} -o "${POSTGRES_INITDB_ARGS}"
}

function serviceStop {
    log "[ Stoping ${SERVICE_NAME}... ]"
    ${SERVICE_HOME}/bin/pg_ctl stop -t 60 -D ${PGDATA} -m SHUTDOWN-MODE
}

function serviceRestart {
    log "[ Restarting ${SERVICE_NAME}... ]"
    serviceStop
    serviceStart
    /opt/monit/bin/monit reload
}

case "$1" in
        "start")
            serviceStart
        ;;
        "stop")
            serviceStop
        ;;
        "restart")
            serviceRestart
        ;;
        *) 
            echo "Usage: $0 restart|start|stop"
            exit 1
        ;;

esac

exit 0
