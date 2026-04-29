#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

# Ensure persistent home paths exist and are always writable/readable by node,
# even when UID/GID remapping is not needed.
mkdir -p /paperclip /paperclip/instances/default /paperclip/.infisical
chown -R node:node /paperclip
chmod -R u+rwX /paperclip

# Keep global CLI installs reachable after gosu hands off to the node user.
export PATH="/usr/local/bin:$PATH"

exec gosu node "$@"
