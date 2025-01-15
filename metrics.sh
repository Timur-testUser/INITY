#!/bin/bash

# Получение имени хоста
echo "host[\"attributes\"].hostname = \"$(hostname)\";"

# Загрузка ОЗУ
ram_usage_prc=$(free | awk '/Mem/{printf "%.0f", \$3/\$2*100}')
echo "host[\"attributes\"].ramUsagePrc = $ram_usage_prc;"

# Загрузка CPU
cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - \$8}')
echo "host[\"attributes\"].cpuLoadPrc = $cpu_load;"

# Файловые системы
df -h --output=source,size,used,avail,pcent | grep '^/' | while read -r line; do
    echo "filesystem[\"$(echo $line | awk '{print \$1}')\"].size = \"$(echo $line | awk '{print \$2}')\";"
    echo "filesystem[\"$(echo $line | awk '{print \$1}')\"].used = \"$(echo $line | awk '{print \$3}')\";"
    echo "filesystem[\"$(echo $line | awk '{print \$1}')\"].avail = \"$(echo $line | awk '{print \$4}')\";"
    echo "filesystem[\"$(echo $line | awk '{print \$1}')\"].usedPrc = $(echo $line | awk '{print \$5}' | sed 's/%//');"
done

# Сетевые интерфейсы
for iface in $(ls /sys/class/net/ | grep -v lo); do
    tx_bytes=$(cat /sys/class/net/$iface/statistics/tx_bytes)
    rx_bytes=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    echo "interface[\"$iface\"].txBytes = $tx_bytes;"
    echo "interface[\"$iface\"].rxBytes = $rx_bytes;"
done

# Загрузка сети
if command -v sar &> /dev/null; then
    net_load=$(sar -n DEV 1 1 | grep -E '^[^ ]+ [^ ]+ [^ ]+' | grep -v 'IFACE')
    echo "host[\"attributes\"].networkLoad = \"$net_load\";"
else
    echo "host[\"attributes\"].networkLoad = \"sar command not found\";"
fi
