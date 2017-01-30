#!/bin/sh -e
# =========================================================
#  flower - Starts the Celery periodic task scheduler.
# =========================================================
#
# :Usage: /etc/init.d/flower {start|stop|force-reload|restart|try-restart|status}
# :Configuration file: /etc/default/flower or /etc/default/celerybeat or /etc/default/celeryd
#
# See http://docs.celeryproject.org/en/latest/tutorials/daemonizing.html#generic-init-scripts

### BEGIN INIT INFO
# Provides:          flower
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: flower monitoring interface daemon
### END INIT INFO

# Cannot use set -e/bash -e since the kill -0 command will abort
# abnormally in the absence of a valid process ID.
#set -e
VERSION=10.1
echo "celery flower init v${VERSION}."

if [ $(id -u) -ne 0 ]; then
    echo "Error: This program can only be used by the root user."
    echo "       Unpriviliged users must use 'celery beat --detach'"
    exit 1
fi

origin_is_runlevel_dir () {
    set +e
    dirname $0 | grep -q "/etc/rc.\.d"
    echo $?
}

# Can be a runlevel symlink (e.g., S02celeryd)
if [ $(origin_is_runlevel_dir) -eq 0 ]; then
    SCRIPT_FILE=$(readlink "$0")
else
    SCRIPT_FILE="$0"
fi
SCRIPT_NAME="$(basename "$SCRIPT_FILE")"

# /etc/init.d/flower: start and stop the flower daemon.

# Make sure executable configuration script is owned by root
_config_sanity() {
    local path="$1"
    local owner=$(ls -ld "$path" | awk '{print $3}')
    local iwgrp=$(ls -ld "$path" | cut -b 6)
    local iwoth=$(ls -ld "$path" | cut -b 9)

    if [ "$(id -u $owner)" != "0" ]; then
        echo "Error: Config script '$path' must be owned by root!"
        echo
        echo "Resolution:"
        echo "Review the file carefully, and make sure it hasn't been "
        echo "modified with mailicious intent.  When sure the "
        echo "script is safe to execute with superuser privileges "
        echo "you can change ownership of the script:"
        echo "    $ sudo chown root '$path'"
        exit 1
    fi

    if [ "$iwoth" != "-" ]; then  # S_IWOTH
        echo "Error: Config script '$path' cannot be writable by others!"
        echo
        echo "Resolution:"
        echo "Review the file carefully, and make sure it hasn't been "
        echo "modified with malicious intent.  When sure the "
        echo "script is safe to execute with superuser privileges "
        echo "you can change the scripts permissions:"
        echo "    $ sudo chmod 640 '$path'"
        exit 1
    fi
    if [ "$iwgrp" != "-" ]; then  # S_IWGRP
        echo "Error: Config script '$path' cannot be writable by group!"
        echo
        echo "Resolution:"
        echo "Review the file carefully, and make sure it hasn't been "
        echo "modified with malicious intent.  When sure the "
        echo "script is safe to execute with superuser privileges "
        echo "you can change the scripts permissions:"
        echo "    $ sudo chmod 640 '$path'"
        exit 1
    fi
}

scripts=""

if test -f /etc/default/celeryd; then
    scripts="/etc/default/celeryd"
    _config_sanity /etc/default/celeryd
    . /etc/default/celeryd
fi

if test -f /etc/default/celerybeat; then
    scripts="$scripts, /etc/default/celerybeat"
    _config_sanity /etc/default/celerybeat
    . /etc/default/celerybeat
fi

EXTRA_CONFIG="/etc/default/${SCRIPT_NAME}"
if test -f "$EXTRA_CONFIG"; then
    scripts="$scripts, $EXTRA_CONFIG"
    _config_sanity "$EXTRA_CONFIG"
    . "$EXTRA_CONFIG"
fi

echo "Using configuration: $scripts"

DEFAULT_USER="celery"
DEFAULT_PID_FILE="/var/run/celery/flower.pid"
DEFAULT_LOG_FILE_PREFIX="/var/log/celery/flower.log"
DEFAULT_LOG_LEVEL="info"
DEFAULT_FLOWER="flower"
DEFAULT_PORT=5555

FLOWER=${FLOWER:-$DEFAULT_FLOWER}
FLOWER_APP=${FLOWER_APP:-$CELERY_APP}
FLOWER_LOG_LEVEL=${FLOWER_LOG_LEVEL:-${FLOWER_LOGLEVEL:-$DEFAULT_LOG_LEVEL}}
FLOWER_PORT=${FLOWER_PORT:-$DEFAULT_PORT}

FLOWER_SU=${FLOWER_SU:-"su"}
FLOWER_SU_ARGS=${FLOWER_SU_ARGS:-""}

# Sets --app argument for CELERY_BIN
FLOWER_APP_ARG=""
if [ ! -z "$FLOWER_APP" ]; then
    FLOWER_APP_ARG="--app=$FLOWER_APP"
fi

FLOWER_USER=${FLOWER_USER:-${CELERYBEAT_USER:-${CELERYD_USER:-$DEFAULT_USER}}}
[ -z "$FLOWER_GROUP" ] && [ ! -z "$CELERYD_GROUP" ] && FLOWER_GROUP=${CELERYD_GROUP}

# Set CELERY_CREATE_DIRS to always create log/pid dirs.
CELERY_CREATE_DIRS=${CELERY_CREATE_DIRS:-0}
CELERY_CREATE_RUNDIR=$CELERY_CREATE_DIRS
CELERY_CREATE_LOGDIR=$CELERY_CREATE_DIRS
if [ -z "$FLOWER_PID_FILE" ]; then
    FLOWER_PID_FILE="$DEFAULT_PID_FILE"
    CELERY_CREATE_RUNDIR=1
fi
if [ -z "$FLOWER_LOG_FILE_PREFIX" ]; then
    FLOWER_LOG_FILE_PREFIX="$DEFAULT_LOG_FILE_PREFIX"
    CELERY_CREATE_LOGDIR=1
fi

export CELERY_LOADER

FLOWER_OPTS="$FLOWER_OPTS -- --log_file_prefix=$FLOWER_LOG_FILE_PREFIX --logging=$FLOWER_LOG_LEVEL --port=$FLOWER_PORT"

if [ -n "$2" ]; then
    FLOWER_OPTS="$FLOWER_OPTS $2"
fi

FLOWER_LOG_DIR=`dirname $FLOWER_LOG_FILE_PREFIX`
FLOWER_PID_DIR=`dirname $FLOWER_PID_FILE`

# Extra start-stop-daemon options, like user/group.

FLOWER_CHDIR=${FLOWER_CHDIR:-$CELERYD_CHDIR}
if [ -n "$FLOWER_CHDIR" ]; then
    DAEMON_OPTS="$DAEMON_OPTS --workdir=$FLOWER_CHDIR"
fi

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

check_dev_null() {
    if [ ! -c /dev/null ]; then
        echo "/dev/null is not a character device!"
        exit 75  # EX_TEMPFAIL
    fi
}

maybe_die() {
    if [ $? -ne 0 ]; then
        echo "Exiting: $*"
        exit 77  # EX_NOPERM
    fi
}

create_default_dir() {
    if [ ! -d "$1" ]; then
        echo "- Creating default directory: '$1'"
        mkdir -p "$1"
        maybe_die "Couldn't create directory $1"
        echo "- Changing permissions of '$1' to 02755"
        chmod 02755 "$1"
        maybe_die "Couldn't change permissions for $1"
        if [ -n "$FLOWER_USER" ]; then
            echo "- Changing owner of '$1' to '$FLOWER_USER'"
            chown "$FLOWER_USER" "$1"
            maybe_die "Couldn't change owner of $1"
        fi
        if [ -n "$FLOWER_GROUP" ]; then
            echo "- Changing group of '$1' to '$FLOWER_GROUP'"
            chgrp "$FLOWER_GROUP" "$1"
            maybe_die "Couldn't change group of $1"
        fi
    fi
}

check_paths() {
    if [ $CELERY_CREATE_LOGDIR -eq 1 ]; then
        create_default_dir "$FLOWER_LOG_DIR"
    fi
    if [ $CELERY_CREATE_RUNDIR -eq 1 ]; then
        create_default_dir "$FLOWER_PID_DIR"
    fi
}


create_paths () {
    create_default_dir "$FLOWER_LOG_DIR"
    create_default_dir "$FLOWER_PID_DIR"
}

is_running() {
    pid=$1
    ps $pid > /dev/null 2>&1
}

stop_beat () {
    echo -n "Stopping ${SCRIPT_NAME}... "
    if [ -f "$FLOWER_PID_FILE" ]; then
	start-stop-daemon --stop --quiet --oknodo --pidfile "$FLOWER_PID_FILE" && rm -f "$FLOWER_PID_FILE" && echo "OK" || echo "FAILED"
    else
        echo "NOT RUNNING"
    fi
}

start_beat () {
    echo "Starting ${SCRIPT_NAME}..."
    start-stop-daemon --start $DAEMON_OPTS --background --make-pidfile --pidfile "$FLOWER_PID_FILE" --exec "/usr/local/bin/$FLOWER" -- $FLOWER_APP_ARG $FLOWER_OPTS
}


check_status () {
    local failed=
    local pid_file=$FLOWER_PID_FILE
    if [ ! -e $pid_file ]; then
        echo "${SCRIPT_NAME} is down: no pid file found"
        failed=true
    elif [ ! -r $pid_file ]; then
        echo "${SCRIPT_NAME} is in unknown state, user cannot read pid file."
        failed=true
    else
        local pid=`cat "$pid_file"`
        local cleaned_pid=`echo "$pid" | sed -e 's/[^0-9]//g'`
        if [ -z "$pid" ] || [ "$cleaned_pid" != "$pid" ]; then
            echo "${SCRIPT_NAME}: bad pid file ($pid_file)"
            failed=true
        else
            local failed=
            kill -0 $pid 2> /dev/null || failed=true
            if [ "$failed" ]; then
                echo "${SCRIPT_NAME} (pid $pid) is down, but pid file exists!"
                failed=true
            else
                echo "${SCRIPT_NAME} (pid $pid) is up..."
            fi
        fi
    fi

    [ "$failed" ] && exit 1 || exit 0
}


case "$1" in
    start)
        check_dev_null
        check_paths
        start_beat
    ;;
    stop)
        check_paths
        stop_beat
    ;;
    reload|force-reload)
        echo "Use start+stop"
    ;;
    status)
        check_status
    ;;
    restart)
        echo "Restarting flower monitor interface"
        check_paths
        stop_beat && check_dev_null && start_beat
    ;;
    create-paths)
        check_dev_null
        create_paths
    ;;
    check-paths)
        check_dev_null
        check_paths
    ;;
    *)
        echo "Usage: /etc/init.d/${SCRIPT_NAME} {start|stop|restart|create-paths|status}"
        exit 64  # EX_USAGE
    ;;
esac

exit 0
