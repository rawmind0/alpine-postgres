#!/usr/bin/env bash

SERVICE_LOG_DIR=${SERVICE_LOG_DIR:-${SERVICE_HOME}"/log"}
SERVICE_LOG_FILE=${SERVICE_LOG_FILE:-${SERVICE_LOG_DIR}"/pgsql.log"}

POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"postgres"}
POSTGRES_USER=${POSTGRES_USER:-"postgres"}
PGDATA=${PGDATA:-${SERVICE_HOME}"/data"}
POSTGRES_DB=${POSTGRES_DB:-"test"}
POSTGRES_INITDB_ARGS=${POSTGRES_INITDB_ARGS:-"-E UTF8"}
POSTGRES_START_ARGS=${POSTGRES_START_ARGS:-"-c listen_addresses='*'"}
POSTGRES_SHUTDOWN_MODE=${POSTGRES_SHUTDOWN_MODE:-"immediate"}

export ZOO_LOG_DIR=${SERVICE_LOG_DIR}

function log {
        echo `date` $ME - $@
}

function createDb {
    log "[ Creating database ${POSTGRES_DB} ... ]"
    if [ "$POSTGRES_DB" != 'postgres' ]; then
        ${SERVICE_HOME}/bin/psql -c "CREATE DATABASE ${POSTGRES_DB};"
    fi
}

function addUser {
    log "[ Creating user ${POSTGRES_USER} ... ]"
    if [ "$POSTGRES_USER" == 'postgres' ]; then
        SQL="ALTER USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
    else
        SQL="CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} to ${POSTGRES_USER};"
    fi

    ${SERVICE_HOME}/bin/psql -c "${SQL}"
}

function serviceDefault {
    log "[ Applying default ${SERVICE_NAME} configuration... ]"
    DB_INIT=1
    if [ ! -f ${PGDATA}/postgresql.conf ]; then
        DB_INIT=0
        ${SERVICE_HOME}/bin/pg_ctl initdb -D ${PGDATA} -o "${POSTGRES_INITDB_ARGS}"

        { echo; echo "host all all 0.0.0.0/0 md5"; } >> "$PGDATA/pg_hba.conf"
    fi
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
    ${SERVICE_HOME}/bin/pg_ctl start -w -t 60 -D ${PGDATA} -l ${SERVICE_LOG_FILE} -o "${POSTGRES_START_ARGS}"
    if [ "$DB_INIT" -eq "0" ]; then
        createDb
        addUser 
    fi
}

function serviceStop {
    log "[ Stoping ${SERVICE_NAME}... ]"
    ${SERVICE_HOME}/bin/pg_ctl stop -t 60 -D ${PGDATA} -m ${POSTGRES_SHUTDOWN_MODE}
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
