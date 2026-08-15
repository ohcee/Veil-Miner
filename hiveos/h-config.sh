#!/usr/bin/env bash
# Builds veilminer.conf from the flight sheet fields. Hive hands us:
#   CUSTOM_TEMPLATE     wallet and worker template (%WAL% already substituted)
#   CUSTOM_URL          pool host:port
#   CUSTOM_PASS         pool password, optional
#   CUSTOM_USER_CONFIG  extra config arguments, appended to the command line

source /hive/miners/custom/veilminer/h-manifest.conf

[[ -z $CUSTOM_TEMPLATE ]] && echo "veilminer: no wallet template set in flight sheet" && exit 1
[[ -z $CUSTOM_URL ]] && echo "veilminer: no pool URL set in flight sheet" && exit 1

# veilminer wants one -P url; strip any scheme the user typed, we add our own
host="${CUSTOM_URL#stratum+tcp://}"
host="${host#stratum+ssl://}"
host="${host#stratum://}"

url="stratum+tcp://${CUSTOM_TEMPLATE}"
[[ -n $CUSTOM_PASS ]] && url="${url}:${CUSTOM_PASS}"
url="${url}@${host}"

echo "POOL_URL=\"$url\"" > "$CUSTOM_CONFIG_FILENAME"
echo "EXTRA_ARGS=\"$CUSTOM_USER_CONFIG\"" >> "$CUSTOM_CONFIG_FILENAME"
