#!/usr/bin/env bash
# Sourced by the hive agent. Must set: khs (total kilohash) and stats (JSON).
# veilminer speaks the claymore-compatible miner_getstat1 on the api port,
# and reports hashrate in KH units, which is exactly what hive wants.

raw=$(echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | timeout 3 nc -w 3 127.0.0.1 3333 2>/dev/null | head -1)

if [[ -z $raw ]]; then
  khs=0
  stats="null"
else
  ver=$(echo "$raw" | jq -r '.result[0]')
  uptime=$(( $(echo "$raw" | jq -r '.result[1]') * 60 ))
  total=$(echo "$raw" | jq -r '.result[2]')
  khs=$(echo "$total" | cut -d';' -f1)
  acc=$(echo "$total" | cut -d';' -f2)
  rej=$(echo "$total" | cut -d';' -f3)
  hs=$(echo "$raw" | jq -c '.result[3] | split(";") | map(tonumber)')
  temp=$(echo "$raw" | jq -c '.result[6] | split(";") | . as $a | [$a[range(0; ($a|length); 2)] | tonumber]')
  fan=$(echo "$raw" | jq -c '.result[6] | split(";") | . as $a | [$a[range(1; ($a|length); 2)] | tonumber]')
  stats=$(jq -nc \
    --argjson hs "$hs" --argjson temp "$temp" --argjson fan "$fan" \
    --arg ver "$ver" --argjson uptime "$uptime" \
    --argjson acc "$acc" --argjson rej "$rej" \
    '{hs: $hs, hs_units: "khs", temp: $temp, fan: $fan, uptime: $uptime, ver: $ver, ar: [$acc, $rej]}')
fi
