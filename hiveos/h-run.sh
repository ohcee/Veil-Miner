#!/usr/bin/env bash
cd "$(dirname "$0")"
source h-manifest.conf
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo "veilminer: config missing, apply the flight sheet first" && exit 1
source "$CUSTOM_CONFIG_FILENAME"
[[ -z $POOL_URL ]] && echo "veilminer: no POOL_URL in config" && exit 1

# rpath already points at ORIGIN for the bundled nvrtc; belt and braces
export LD_LIBRARY_PATH=.

# HWMON 2 turns on temp, fan and power readings through NVML, which the rig
# has via its driver. Off by default upstream, and without it the dashboard
# shows zero temps.
./veilminer --cuda -P "$POOL_URL" --api-port 3333 --HWMON 2 $EXTRA_ARGS 2>&1 | tee "$CUSTOM_LOG_BASENAME.log"
