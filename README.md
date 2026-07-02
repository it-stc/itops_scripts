# ITOps Scripts

A centralized repository of production-ready IT Operations and Systems Administration scripts. These tools are built to automate routine infrastructure tasks, monitor endpoint performance, diagnose network health, and simplify day-to-day sysadmin workflows.

## 🚀 Featured Scripts

### 📊 `macos_health_check.sh` — macOS System & Network Diagnostics
A robust shell script designed to give an instant operational snapshot of a macOS system. It identifies potential performance bottlenecks and local network stability problems dynamically.

* **Smart Uptime Checks:** Flags uptimes exceeding 7 days and recommends a proactive reboot to avoid OS degradation.
* **Deep Memory Analysis:** Breaks down hardware physical RAM and tracks background application swap memory (warning when memory leaks are active).
* **Network Footprint Data:** Displays local IP address, subnet mask, default gateway router, and active system DNS servers.
* **Dual-Provider Ping Testing:** Actively checks network packet loss and latency to both Cloudflare (`1.1.1.1`) and Google (`8.8.8.8`) DNS endpoints to instantly map connection stability.
* **Isolated Timestamped Logs:** Duplicates live terminal output into unique, microsecond-precise log files (`system_status_YYYYMMDD_HHMMSS.log`) within its native directory for historical auditing.
