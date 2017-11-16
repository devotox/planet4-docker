#!/usr/bin/env bash
set -euo pipefail

chmod +x /app/bin/*

# Configure environment
for env_file in /app/env/*
do
  # shellcheck source=/dev/null
  . ${env_file}
done

# Add application user
/app/bin/add_user.sh

# Install configuration overrides
[[ -d "/app/etc" ]] && cp -R /app/etc/* /etc/

[[ -d "/etc/my_init.d" ]] && chmod 755 /etc/my_init.d/*.sh

# Ensure service start scripts are executable
chmod 755 /etc/service/*/run

# =============================================================================
# 	BOOT
# =============================================================================

_good "$(date) -" "exec $*"

# Default Docker CMD will be /sbin/my_init
if [[ "$1" = "/sbin/my_init" ]]
then
  shift
	exec /sbin/my_init
else
  # Execute the custom CMD
	exec /bin/bash -c "$*"
fi
