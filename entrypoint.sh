#!/bin/sh

# Determine backup pool based on active pool
if [ "$ACTIVE_POOL" = "blue" ]; then
    export BACKUP_POOL="green"
else
    export BACKUP_POOL="blue"
fi

echo "Active pool: $ACTIVE_POOL"
echo "Backup pool: $BACKUP_POOL"

# Substitute environment variables in nginx config
envsubst '${ACTIVE_POOL} ${BACKUP_POOL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Verify the configuration
nginx -t

# Start nginx in foreground
exec nginx -g 'daemon off;'
