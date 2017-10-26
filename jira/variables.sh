THIS=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Include helpers
. ${THIS}/../helpers.sh

# Include config
. ${CONFIG_FILE}

test -z "$DEBUG" && export DEBUG=0

if [ "$DEBUG" = "1" ]
then
    export DEBUG="$DEBUG"
else
    export DEBUG="0"
fi

if [ "$DEBUG" = "1" ]
then
    # set -x when debug
    set -x
fi

which realpath > /dev/null || fail "realpath not installed"

test -z "$JIRA_PATH" && fail "JIRA_PATH not set"
test -e "$JIRA_PATH" || fail "Directory $JIRA_PATH does not exist"
export JIRA_BASE="$(realpath $JIRA_PATH)"
test -z "$JIRA_USER" && fail "JIRA_USER not set"
test -z "$JIRA_TYPE" && export JIRA_TYPE="jira-core"
test -z "$JIRA_SERVICE_NAME" && export JIRA_SERVICE_NAME="jira"
test -d "$JIRA_BASE" || fail "${JIRA_BASE} is not a directory"


export JIRA_BASE
export JIRA_USER
export JIRA_TYPE


export JIRA_CURRENT="${JIRA_BASE}/current"