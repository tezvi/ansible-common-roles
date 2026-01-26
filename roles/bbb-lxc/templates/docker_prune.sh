#!/bin/bash
set -e

LMS_DIR="/srv/lms"
QUIET=0
AGGRESSIVE=1

usage() {
    echo "Usage: $0 [-q] [-a] [-h]"
    echo "  -q                Quiet mode (do not print to stdout, only log to file)"
    echo "  -a                Aggressive mode (prune all unused images, not just dangling ones) [default: on]"
    echo "  -n                Non-aggressive mode (prune only dangling images)"
    echo "  -h                Show this help message"
    echo ""
    echo "Description:"
    echo "  Prunes unused Docker resources including stopped containers, unused networks,"
    echo "  unused volumes, and unused images. By default, runs in aggressive mode which"
    echo "  removes all unused images. Use -n to prune only dangling images."
    exit 1
}

log_msg() {
  local msg="$1"
  local clean_msg
  clean_msg="$(echo -e "$msg" | sed -r 's/\x1B\[[0-9;]*[mK]//g')"
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') $clean_msg" >> "$PRUNE_LOG"
  if [[ $QUIET -eq 0 ]]; then
    echo -e "$msg"
  fi
}

trap 'QUIET=0; log_msg "🛑 Error occurred at line $LINENO. Stopping execution."; exit 1' ERR
trap 'QUIET=0; echo -e "\n⏹️  Script interrupted (SIGINT/SIGTERM/SIGQUIT/SIGTSTP). Exiting."; exit 130' INT TERM QUIT TSTP

# Parse options
while getopts "qanh" opt; do
  case "$opt" in
    q) QUIET=1 ;;
    a) AGGRESSIVE=1 ;;
    n) AGGRESSIVE=0 ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

LOG_DIR="/var/log"
PRUNE_LOG="$LOG_DIR/docker_prune.log"

# Check if log directory exists, create if not
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# Ensure prune.log exists with correct ownership and permissions
if [ ! -f "$PRUNE_LOG" ]; then
  install -o root -g root -m 664 /dev/null "$PRUNE_LOG"
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_msg "🛑 Error: Docker command not found. Please install Docker."
    exit 2
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    log_msg "🛑 Error: Docker daemon is not running or not accessible."
    exit 3
fi

log_msg "🟢 Starting Docker pruning process..."

if [[ $AGGRESSIVE -eq 1 ]]; then
    log_msg "📋 Mode: Aggressive (will prune all unused images)"
else
    log_msg "📋 Mode: Non-aggressive (will prune only dangling images)"
fi

# Prune stopped containers
log_msg "🔧 Pruning stopped containers..."
if [[ $QUIET -eq 0 ]]; then
    docker container prune -f 2>&1 | tee -a "$PRUNE_LOG"
    CONTAINER_STATUS=${PIPESTATUS[0]}
else
    docker container prune -f >> "$PRUNE_LOG" 2>&1
    CONTAINER_STATUS=$?
fi

if [[ $CONTAINER_STATUS -ne 0 ]]; then
    log_msg "⚠️  Warning: Failed to prune containers."
fi

# Prune unused networks
log_msg "🔧 Pruning unused networks..."
if [[ $QUIET -eq 0 ]]; then
    docker network prune -f 2>&1 | tee -a "$PRUNE_LOG"
    NETWORK_STATUS=${PIPESTATUS[0]}
else
    docker network prune -f >> "$PRUNE_LOG" 2>&1
    NETWORK_STATUS=$?
fi

if [[ $NETWORK_STATUS -ne 0 ]]; then
    log_msg "⚠️  Warning: Failed to prune networks."
fi

# Prune unused volumes
log_msg "🔧 Pruning unused volumes..."
if [[ $QUIET -eq 0 ]]; then
    docker volume prune -f 2>&1 | tee -a "$PRUNE_LOG"
    VOLUME_STATUS=${PIPESTATUS[0]}
else
    docker volume prune -f >> "$PRUNE_LOG" 2>&1
    VOLUME_STATUS=$?
fi

if [[ $VOLUME_STATUS -ne 0 ]]; then
    log_msg "⚠️  Warning: Failed to prune volumes."
fi

# Prune images
if [[ $AGGRESSIVE -eq 1 ]]; then
    log_msg "🔧 Pruning all unused images..."
    if [[ $QUIET -eq 0 ]]; then
        docker image prune -a -f 2>&1 | tee -a "$PRUNE_LOG"
        IMAGE_STATUS=${PIPESTATUS[0]}
    else
        docker image prune -a -f >> "$PRUNE_LOG" 2>&1
        IMAGE_STATUS=$?
    fi
else
    log_msg "🔧 Pruning dangling images..."
    if [[ $QUIET -eq 0 ]]; then
        docker image prune -f 2>&1 | tee -a "$PRUNE_LOG"
        IMAGE_STATUS=${PIPESTATUS[0]}
    else
        docker image prune -f >> "$PRUNE_LOG" 2>&1
        IMAGE_STATUS=$?
    fi
fi

if [[ $IMAGE_STATUS -ne 0 ]]; then
    log_msg "⚠️  Warning: Failed to prune images."
fi

# Optional: Prune build cache
log_msg "🔧 Pruning build cache..."
if [[ $QUIET -eq 0 ]]; then
    docker builder prune -f 2>&1 | tee -a "$PRUNE_LOG"
    BUILD_STATUS=${PIPESTATUS[0]}
else
    docker builder prune -f >> "$PRUNE_LOG" 2>&1
    BUILD_STATUS=$?
fi

if [[ $BUILD_STATUS -ne 0 ]]; then
    log_msg "⚠️  Warning: Failed to prune build cache."
fi

# Show disk space summary
log_msg "📊 Docker disk usage summary:"
if [[ $QUIET -eq 0 ]]; then
    docker system df 2>&1 | tee -a "$PRUNE_LOG"
else
    docker system df >> "$PRUNE_LOG" 2>&1
fi

log_msg "✅ Docker pruning completed successfully."

