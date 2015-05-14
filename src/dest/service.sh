#!/usr/bin/env sh
#
# MongoDB service

# import DroboApps framework functions
. /etc/service.subr

# framework-mandated variables
framework_version="2.1"
name="mongodb3"
version="3.0.2"
description="NoSQL database"
depends=""
webui=""

# app-specific variables
prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/bin/mongod"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  . "${prog_dir}/libexec/service.subr"
fi

start() {
  "${daemon}" --bind_ip "$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')" --port 2717 --dbpath "${prog_dir}/data" --pidfilepath "${pidfile}" --logpath "${logfile}" --logappend --fork
}

stop() {
  "${daemon}" --dbpath "${prog_dir}/data" --shutdown
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o pipefail # propagate last error code on pipe
set -o xtrace   # enable script tracing

main "$@"
