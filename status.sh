#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generate a unique timestamp for the file name (Format: YearMonthDay_HourMinuteSecond)
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="${SCRIPT_DIR}/system_status_${TIMESTAMP}.log"

# Automatically duplicate all stdout and stderr to the unique log file while displaying it on screen
exec > >(tee "$LOG_FILE") 2>&1

echo "========================================="
echo "  Mac OS SYSTEM STATUS & DIAGNOSTICS     "
echo "  Logged: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 1. Hostname
echo -e "Hostname:\t$(hostname)"

# 2. Uptime & Recommendation Logic
UPTIME_RAW=$(uptime)
echo -e "Uptime:\t\t$(echo "$UPTIME_RAW" | sed 's/.*up \([^,]*\), .*/\1/')"

if [[ "$UPTIME_RAW" == *"day"* ]]; then
    DAYS_UP=$(echo "$UPTIME_RAW" | awk -F'up ' '{print $2}' | awk '{print $1}')
    if [ "$DAYS_UP" -ge 7 ]; then
        echo -e "\033[0;31mUptime Rec:\t[!] It is highly recommended to RESTART your laptop. Long uptime (>7 days) causes network glitches and file search index errors.\033[0m"
    else
        echo -e "\033[0;32mUptime Rec:\t[✓] System uptime is okay (Less than a week).\033[0m"
    fi
else
    echo -e "\033[0;32mUptime Rec:\t[✓] System uptime is okay (Less than a week).\033[0m"
fi

echo "----------------------------------------"

# 3. Network Configuration (IP, Gateway, Subnet Mask, DNS)
ACTIVE_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -z "$ACTIVE_IFACE" ]; then
    echo "Network:\tNo Active Connection"
else
    LOCAL_IP=$(ipconfig getifaddr "$ACTIVE_IFACE")
    SUBNET_MASK=$(ipconfig getoption "$ACTIVE_IFACE" subnet_mask)
    GATEWAY_IP=$(route -n get default | awk '/gateway:/ {print $2}')
    DNS_SERVERS=$(scutil --dns | awk '/nameserver\[[0-9]\]/ {print $3}' | sort -u | paste -sd ", " -)

    echo -e "Local IP:\t$LOCAL_IP"
    echo -e "Subnet Mask:\t$SUBNET_MASK"
    echo -e "Gateway:\t$GATEWAY_IP"
    echo -e "System DNS:\t$DNS_SERVERS"
fi

echo "----------------------------------------"

# 4. Total Physical Memory
TOTAL_RAM_BYTES=$(sysctl -n hw.memsize)
TOTAL_RAM_GB=$((TOTAL_RAM_BYTES / 1024 / 1024 / 1024))
echo -e "Total Hardware RAM: ${TOTAL_RAM_GB} GB"

# 5. Active Memory Breakdown
PAGE_SIZE=$(vm_stat | grep "page size" | awk '{print $8}')

PAGES_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
PAGES_INACTIVE=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
PAGES_SPECULATIVE=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | tr -d '.')

AVAILABLE_PAGES=$((PAGES_FREE + PAGES_INACTIVE + PAGES_SPECULATIVE))
AVAILABLE_MEM_BYTES=$((AVAILABLE_PAGES * PAGE_SIZE))
AVAILABLE_MEM_GB=$((AVAILABLE_MEM_BYTES / 1024 / 1024 / 1024))
USED_MEM_GB=$((TOTAL_RAM_GB - AVAILABLE_MEM_GB))

echo -e "RAM Usage:\t${USED_MEM_GB} GB used / ${TOTAL_RAM_GB} GB total"

# 6. Swap Usage & Recommendation Logic
SWAP_TOTAL=$(sysctl -n vm.swapusage | awk '{print $3}')
SWAP_USED=$(sysctl -n vm.swapusage | awk '{print $6}')
SWAP_FREE=$(sysctl -n vm.swapusage | awk '{print $9}')

echo -e "Swap Usage:\t${SWAP_FREE} free / ${SWAP_USED} used / ${SWAP_TOTAL} total"

if [ "$SWAP_USED" != "0.00M" ]; then
    echo -e "\033[0;31mSwap Rec:\t[!] Swap is active ($SWAP_USED used). Background memory leaks are building up. A restart is recommended to bring swap back to zero.\033[0m"
else
    echo -e "\033[0;32mSwap Rec:\t[✓] Swap memory usage is okay (0.00M used).\033[0m"
fi

echo "----------------------------------------"

# 7. Dual Network Ping Tests (Cloudflare & Google)
echo "Testing network connectivity..."

# Ping Cloudflare
echo "- Ping Cloudflare DNS (1.1.1.1):"
PING_CF=$(ping -c 4 1.1.1.1)
echo "$PING_CF" | grep -A 2 "ping statistics"

# Ping Google
echo -e "\n- Ping Google DNS (8.8.8.8):"
PING_GG=$(ping -c 4 8.8.8.8)
echo "$PING_GG" | grep -A 2 "ping statistics"

# Parse Packet Loss percentages
LOSS_CF=$(echo "$PING_CF" | awk -F', ' '/packet loss/ {print $3}' | awk '{print $1}' | tr -d '%')
LOSS_GG=$(echo "$PING_GG" | awk -F', ' '/packet loss/ {print $3}' | awk '{print $1}' | tr -d '%')

if [ -z "$LOSS_CF" ]; then LOSS_CF=$(echo "$PING_CF" | grep -oE '[0-9]+(\.[0-9]+)?% packet loss' | awk '{print $1}' | tr -d '%'); fi
if [ -z "$LOSS_GG" ]; then LOSS_GG=$(echo "$PING_GG" | grep -oE '[0-9]+(\.[0-9]+)?% packet loss' | awk '{print $1}' | tr -d '%'); fi

INT_CF=${LOSS_CF%.*}
INT_GG=${LOSS_GG%.*}

echo -e "\n----------------------------------------"

if [ "$INT_CF" -gt 0 ] || [ "$INT_GG" -gt 0 ]; then
    echo -e "\033[0;31mPing Rec:\t[!] Potential network issues! Cloudflare loss: ${LOSS_CF}%, Google loss: ${LOSS_GG}%.\033[0m"
else
    echo -e "\033[0;32mPing Rec:\t[✓] Network connection looks stable to both providers (0% packet loss).\033[0m"
fi

echo "========================================="
echo -e "Saved separate log to: ${LOG_FILE}\n\n"