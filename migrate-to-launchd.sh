#!/bin/bash

# Migrate from background daemon to LaunchAgent (macOS native)
# This fixes the issue where daemon stops when Mac sleeps

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DAEMON_MANAGER="$SCRIPT_DIR/claude-daemon-manager.sh"
DAEMON_SCRIPT="$SCRIPT_DIR/claude-auto-renew-daemon.sh"
INSTALL_LAUNCHD="$SCRIPT_DIR/install-launchd.sh"
MANAGE_LAUNCHD="$SCRIPT_DIR/manage-launchd.sh"
PID_FILE="$HOME/.claude-auto-renew-daemon.pid"
START_TIME_FILE="$HOME/.claude-auto-renew-start-time"
STOP_TIME_FILE="$HOME/.claude-auto-renew-stop-time"
MESSAGE_FILE="$HOME/.claude-auto-renew-message"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header "Claude Auto-Renewal: Migrate to LaunchAgent"

echo "This migration fixes the issue where the daemon stops when your Mac sleeps."
echo ""
echo "Current situation:"
echo "  ❌ Background daemon runs in terminal (stops when Mac sleeps)"
echo ""
echo "After migration:"
echo "  ✅ LaunchAgent runs via macOS (continues even during sleep)"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if [ ! -f "$DAEMON_SCRIPT" ]; then
    print_error "Daemon script not found: $DAEMON_SCRIPT"
    exit 1
fi
print_info "Daemon script found"

if [ ! -f "$INSTALL_LAUNCHD" ]; then
    print_error "Install script not found: $INSTALL_LAUNCHD"
    exit 1
fi
print_info "Install script found"

chmod +x "$INSTALL_LAUNCHD" 2>/dev/null
chmod +x "$MANAGE_LAUNCHD" 2>/dev/null

# Check if old daemon is running
echo ""
echo "Checking for existing daemon..."
OLD_PID=""
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        print_warning "Old daemon is running (PID: $OLD_PID)"
    else
        print_info "Old daemon is not running"
    fi
else
    print_info "No old daemon found"
fi

# Save current configuration
echo ""
echo "Saving your current configuration..."

CONFIG_BACKUP="/tmp/claude-autorenew-config-backup.txt"
cat > "$CONFIG_BACKUP" << EOF
# Configuration backup from $(date)

# Start time (epoch)
$([ -f "$START_TIME_FILE" ] && echo "START_TIME=$(cat $START_TIME_FILE)" || echo "START_TIME=")

# Stop time (epoch)
$([ -f "$STOP_TIME_FILE" ] && echo "STOP_TIME=$(cat $STOP_TIME_FILE)" || echo "STOP_TIME=")

# Custom message
$([ -f "$MESSAGE_FILE" ] && echo "MESSAGE=$(cat $MESSAGE_FILE)" || echo "MESSAGE=")
EOF

print_info "Configuration saved to $CONFIG_BACKUP"

# Stop old daemon if running
if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo ""
    echo "Stopping old background daemon..."
    if [ -f "$DAEMON_MANAGER" ]; then
        "$DAEMON_MANAGER" stop 2>/dev/null
        sleep 1
    else
        kill "$OLD_PID" 2>/dev/null
    fi
    print_info "Old daemon stopped"
fi

# Install LaunchAgent
echo ""
echo "Installing LaunchAgent..."
bash "$INSTALL_LAUNCHD"

if [ $? -ne 0 ]; then
    print_error "Failed to install LaunchAgent"
    exit 1
fi

# Verify installation
echo ""
echo "Verifying installation..."
sleep 1
bash "$MANAGE_LAUNCHD" status

echo ""
print_header "Migration Complete! ✅"

echo "What changed:"
echo "  • Your daemon now runs via macOS LaunchAgent"
echo "  • Automatically starts at login"
echo "  • Continues running when Mac sleeps"
echo "  • Automatically restarts if it crashes"
echo ""

echo "Your configuration has been preserved:"
if [ -f "$START_TIME_FILE" ]; then
    START_TIME=$(cat "$START_TIME_FILE")
    echo "  • Start time: $(date -r "$START_TIME" 2>/dev/null || echo 'preserved')"
fi
if [ -f "$STOP_TIME_FILE" ]; then
    STOP_TIME=$(cat "$STOP_TIME_FILE")
    echo "  • Stop time: $(date -r "$STOP_TIME" 2>/dev/null || echo 'preserved')"
fi
if [ -f "$MESSAGE_FILE" ]; then
    MESSAGE=$(cat "$MESSAGE_FILE")
    echo "  • Custom message: \"$MESSAGE\""
fi

echo ""
echo "Next steps:"
echo "  1. Restart your Mac to confirm daemon starts automatically"
echo "  2. Use: ./manage-launchd.sh status    (check daemon status)"
echo "  3. Use: ./manage-launchd.sh logs -f   (watch logs in real-time)"
echo ""

echo "Your old background daemon has been replaced with LaunchAgent."
echo "The daemon will now work 24/7, even when your Mac is asleep! 🎉"
