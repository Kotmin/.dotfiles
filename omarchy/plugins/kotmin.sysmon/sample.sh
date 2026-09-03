#!/bin/sh
# One sample for the kotmin.sysmon bar widget. Prints a single line:
#   cpuBusy cpuTotal memTotalKB memAvailKB diskAvailBytes netRxBytes netTxBytes
# The widget keeps the previous sample and turns the deltas into rates.

# /proc/stat first line: "cpu  user nice system idle iowait irq softirq steal ..."
read -r _ u ni sy idl io ir so st _ </proc/stat
busy=$((u + ni + sy + ir + so + st))
total=$((busy + idl + io))

mt=$(awk '/^MemTotal:/{print $2; exit}' /proc/meminfo)
ma=$(awk '/^MemAvailable:/{print $2; exit}' /proc/meminfo)

da=$(df -P -B1 / | awk 'NR==2{print $4; exit}')

# /proc/net/dev: sum every interface except loopback. After turning the
# "iface:" colon into a space, $2 is rx bytes and $10 is tx bytes.
set -- $(awk 'NR>2 { sub(/:/, " "); if ($1 != "lo") { rx += $2; tx += $10 } } END { print rx + 0, tx + 0 }' /proc/net/dev)

printf '%s %s %s %s %s %s %s\n' "$busy" "$total" "$mt" "$ma" "$da" "$1" "$2"
