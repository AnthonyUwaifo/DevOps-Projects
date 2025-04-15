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
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  cpu_usage=${cpu_usage%.*}
  if ((cpu_usage >= CPU_THRESHOLD)); then
    send_alert "CPU" "$cpu_usage"
  fi

  # Monitor memory
  memory_usage=$(free | awk '/Mem/ {printf("%3.1f", ($3/$2) * 100)}')
  memory_usage=${memory_usage%.*}
  if ((memory_usage >= MEMORY_THRESHOLD)); then
    send_alert "Memory" "$memory_usage"
  fi

  # Monitor disk
  disk_usage=$(df -h / | awk '/\// {print $(NF-1)}')
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
done