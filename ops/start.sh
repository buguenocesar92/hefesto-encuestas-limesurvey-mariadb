#!/bin/sh
set -eu
php /opt/hefesto-configure.php
exec /usr/local/bin/entrypoint.sh "$@"
