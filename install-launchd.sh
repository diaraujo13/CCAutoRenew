#!/bin/bash

# Install Claude Auto-Renewal as macOS LaunchAgent
# This ensures the daemon continues running even when Mac is sleeping

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/claude-auto-renew-daemon.sh"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.user.claude-auto-renew.plist"
LOG_DIR="$HOME/.claude-logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if daemon script exists
if [ ! -f "$DAEMON_SCRIPT" ]; then
    print_error "Daemon script not found: $DAEMON_SCRIPT"
    exit 1
fi

# Make daemon script executable
chmod +x "$DAEMON_SCRIPT"
print_info "Daemon script is executable"

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$PLIST_DIR"
mkdir -p "$LOG_DIR"

# Create the plist file
cat > "$PLIST_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.claude-auto-renew</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>__DAEMON_SCRIPT__</string>
    </array>

    <!-- Run at login -->
    <key>RunAtLoad</key>
    <true/>

    <!-- Keep the process running -->
    <key>KeepAlive</key>
    <dict>
        <!-- Restart if it crashes -->
        <key>SuccessfulExit</key>
        <false/>
        <!-- Don't exit on errors -->
    </dict>

    <!-- Standard output and error -->
    <key>StandardOutPath</key>
    <string>__LOG_DIR__/claude-auto-renew.stdout.log</string>

    <key>StandardErrorPath</key>
    <string>__LOG_DIR__/claude-auto-renew.stderr.log</string>

    <!-- Working directory -->
    <key>WorkingDirectory</key>
    <string>__HOME_DIR__</string>

    <!-- Environment variables -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>__HOME_DIR__</string>
    </dict>
</dict>
</plist>
EOF

# Replace placeholders
sed -i '' "s|__DAEMON_SCRIPT__|$DAEMON_SCRIPT|g" "$PLIST_FILE"
sed -i '' "s|__LOG_DIR__|$LOG_DIR|g" "$PLIST_FILE"
sed -i '' "s|__HOME_DIR__|$HOME|g" "$PLIST_FILE"

print_info "LaunchAgent plist created: $PLIST_FILE"

# Load the plist (if existing daemon is running, unload first)
if [ -f "$PLIST_FILE" ]; then
    # Unload if already loaded
    launchctl unload "$PLIST_FILE" 2>/dev/null

    # Load the plist
    launchctl load "$PLIST_FILE"

    if [ $? -eq 0 ]; then
        print_info "LaunchAgent loaded successfully"
    else
        print_error "Failed to load LaunchAgent"
        exit 1
    fi
fi

echo ""
print_info "✅ Installation complete!"
echo ""
echo "📋 What changed:"
echo "  • Daemon now runs via launchd (macOS native system)"
echo "  • Automatically starts at login"
echo "  • Keeps running even when Mac is in sleep"
echo "  • Automatically restarts if it crashes"
echo ""
echo "🔧 Commands:"
echo "  Check status:    launchctl list | grep claude-auto-renew"
echo "  View logs:       tail -f $LOG_DIR/claude-auto-renew.stdout.log"
echo "  Stop daemon:     launchctl unload $PLIST_FILE"
echo "  Start daemon:    launchctl load $PLIST_FILE"
echo "  Remove daemon:   rm $PLIST_FILE && launchctl unload $PLIST_FILE 2>/dev/null"
echo ""
print_warning "⚠️  Your existing background daemon will be replaced."
print_warning "    The old daemon will be automatically stopped."
