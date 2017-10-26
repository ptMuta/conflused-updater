#!/bin/bash

#
# Install the latest version of JIRA Core
#

if [ -z "$1" ]
then
	echo "Usage $0 path/to/config.sh"
	exit 1
fi

export CONFIG_FILE="$1"

set -e

export THIS=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Include variables
. ${THIS}/variables.sh

# Include helpers
. ${THIS}/../helpers.sh

function create_unit_file() {
    cat >/etc/systemd/system/jira.service <<EOL
[Unit]
Description=Jira Issue & Project Tracking Software
After=network.target

[Service]
Type=forking
User=${JIRA_USER}
PIDFile=${JIRA_CURRENT}/work/catalina.pid
ExecStart=${JIRA_CURRENT}/bin/start-jira.sh
ExecStop=${JIRA_CURRENT}/bin/stop-jira.sh

[Install]
WantedBy=multi-user.target
EOL
}

function create_init_script() {
    cat >/etc/init.d/jira <<EOL
#!/bin/bash

# JIRA Core Linux service controller script
cd "${JIRA_CURRENT}/bin"

case "$1" in
    start)
        ./start-jira.sh
        ;;
    stop)
        ./stop-jira.sh
        ;;
    restart)
        ./stop-jira.sh
        ./start-jira.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac

EOL
    chmod +x /etc/init.d/jira
}

JIRA_TGZ="$(mktemp -u --suffix=.tar.gz)"

function post_cleanup() {
    rm $JIRA_TGZ || true
}

trap post_cleanup SIGINT SIGTERM

if [[ -h ${JIRA_CURRENT} ]]; then
    fail "JIRA Core is already installed"
fi

# Download newest
JIRA_NEW_VERSION="$(latest_version ${JIRA_TYPE})"
JIRA_DOWNLOAD_URL="$(latest_version_url ${JIRA_TYPE})"

JIRA_NEW="${JIRA_BASE}/jira-${JIRA_NEW_VERSION}"

info "Downloading JIRA"

wget -O "$JIRA_TGZ" "$JIRA_DOWNLOAD_URL"

#Unzip new JIRA

mkdir "$JIRA_NEW"

info "Unzipping JIRA"
tar --strip-components=1 -xf "$JIRA_TGZ" -C "$JIRA_NEW"

# Remove tempdir
rm "$JIRA_TGZ"

info "Setting permissions..."

chown -R "$JIRA_USER" "${JIRA_NEW}/temp"
chown -R "$JIRA_USER" "${JIRA_NEW}/logs"
chown -R "$JIRA_USER" "${JIRA_NEW}/work"

# TODO: Configure

info "Updating current symlink"
ln -s ${JIRA_NEW} ${JIRA_CURRENT}

echo $JIRA_SERVICE_NAME

info "JIRA is now installed!"

if [ "$JIRA_SERVICE_NAME" != "disable" ]
then
    info "Preparing services"
    `which systemctl > /dev/null 2>&1`
    if [ $? -eq 0 ]
    then
        info "Installing systemd unit file"
        create_unit_file
    else
        info "Installing init script"
        create_init_script
    fi

    info "Starting JIRA Core"
    servicemanager "${JIRA_SERVICE_NAME}" enable
    servicemanager "${JIRA_SERVICE_NAME}" start
    info "Be patient, JIRA is starting up"
fi
