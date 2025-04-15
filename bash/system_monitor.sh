#!/bin/bash

# Define the threshold values for CPU, memory, and disk usage (in percentage)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

# Function to send an alert
send_alert() {
  echo "$(tput setaf 1)ALERT: $1 usage exceeded threshold! Current value: $2%$(tput sgr0)"
}

# Monitor CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
cpu_usage=${cpu_usage%.*} # Convert to integer
echo "Current CPU usage: $cpu_usage%"

if ((cpu_usage >= CPU_THRESHOLD)); then
  send_alert "CPU" "$cpu_usage"
fi

# Monitor memory usage
memory_usage=$(free | awk '/Mem/ {printf("%3.1f", ($3/$2) * 100)}')
echo "Current memory usage: $memory_usage%"
memory_usage=${memory_usage%.*}
if ((memory_usage >= MEMORY_THRESHOLD)); then
  send_alert "Memory" "$memory_usage"
fi

# Monitor disk usage
disk_usage=$(df -h / | awk '/\// {print $(NF-1)}')
disk_usage=${disk_usage%?} # Remove the % sign
echo "Current disk usage: $disk_usage%"

if ((disk_usage >= DISK_THRESHOLD)); then
  send_alert "Disk" "$disk_usage"
fi

while true; do
  # Monitor CPU
  cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
  cpu_usage=${cpu_usage%.*}

  if ((cpu_usage >= CPU_THRESHOLD)); then
    send_alert "CPU" "$cpu_usage"
  fi

  # Monitor memory
  memory_usage=$(vm_stat | awk '
/Pages active/      {active=$3}
/Pages wired down/  {wired=$3}
/Pages speculative/ {speculative=$3}
/Pages free/        {free=$3}
/Pages inactive/    {inactive=$3}
/Pages purgeable/   {purgeable=$3}
/page size of/      {gsub("[^0-9]", "", $8); size=$8}
END {
  used = (active + wired + speculative)
  total = used + inactive + purgeable + free
  used_mb = used * size / 1024 / 1024
  total_mb = total * size / 1024 / 1024
  printf "%.0f\n", (used_mb / total_mb) * 100
}')

  memory_usage=${memory_usage%.*}
  if ((memory_usage >= MEMORY_THRESHOLD)); then
    send_alert "Memory" "$memory_usage"
  fi

  # Monitor disk
  disk_usage=$(df -H / | awk 'NR==2 {print $5}' | tr -d '%')
  disk_usage=${disk_usage%?}
  if ((disk_usage >= DISK_THRESHOLD)); then
    send_alert "Disk" "$disk_usage"
  fi

  # Display current stats
  clear
  echo "Resource Usage:"
  echo "CPU: $cpu_usage%"
  echo "Memory: $memory_usage%"
  echo "Disk: $disk_usage%"
  sleep 2

  # Log resource usage to a file
log_entry="$(date '+%Y-%m-%d %H:%M:%S') CPU: $cpu_usage% Memory: $memory_usage% Disk: $disk_usage%"

if [-f /Users/admin/Desktop/unix/bash/resource_usage.log]; then
  echo "$log_entry" >> /Users/admin/Desktop/unix/bash/resource_usage.log
else
  touch /Users/admin/Desktop/unix/bash/resource_usage.log 
  echo "$log_entry" >> /Users/admin/Desktop/unix/bash/resource_usage.log
fi

done

