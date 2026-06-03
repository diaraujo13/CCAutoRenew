#!/bin/bash

# Manage LaunchAgent for Claude Auto-Renewal Daemon

PLIST_FILE="$HOME/Library/LaunchAgents/com.user.claude-auto-renew.plist"
PID_FILE="$HOME/.claude-auto-renew-daemon.pid"
LOG_FILE="$HOME/.claude-auto-renew-daemon.log"
LOG_DIR="$HOME/.claude-logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_status() {
    print_header "Claude Auto-Renewal Status"
    echo ""

    # Check launchd status
    if [ -f "$PLIST_FILE" ]; then
        print_info "LaunchAgent plist exists"

        # Check if loaded
        if launchctl list | grep -q "claude-auto-renew"; then
            print_info "✅ LaunchAgent is LOADED (running via launchd)"
            echo ""
            echo "This means:"
            echo "  • Daemon starts automatically at login"
            echo "  • Continues running even when Mac is in sleep"
            echo "  • Automatically restarts if it crashes"
        else
            print_warning "LaunchAgent exists but is NOT loaded"
        fi
    else
        print_warning "LaunchAgent not installed"
    fi

    echo ""

    # Check traditional background daemon
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            print_warning "Old background daemon is still running (PID: $OLD_PID)"
            echo "  Note: This will be suspended when Mac sleeps!"
        else
            print_info "Old daemon process is not running (stale PID file)"
        fi
    else
        print_info "No old background daemon found"
    fi

    echo ""

    # Show recent logs
    if [ -d "$LOG_DIR" ]; then
        echo "📋 Recent activity (launchd logs):"
        if [ -f "$LOG_DIR/claude-auto-renew.stdout.log" ]; then
            echo "  From stdout:"
            tail -3 "$LOG_DIR/claude-auto-renew.stdout.log" | sed 's/^/    /'
        fi
    fi

    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📋 Daemon logs:"
        tail -3 "$LOG_FILE" | sed 's/^/    /'
    fi
}

stop_launchd() {
    if [ -f "$PLIST_FILE" ]; then
        print_warning "Stopping LaunchAgent..."
        launchctl unload "$PLIST_FILE"
        if [ $? -eq 0 ]; then
            print_info "LaunchAgent stopped"
        else
            print_error "Failed to stop LaunchAgent"
            return 1
        fi
    else
        print_warning "LaunchAgent not found"
        return 1
    fi
}

start_launchd() {
    if [ -f "$PLIST_FILE" ]; then
        print_warning "Starting LaunchAgent..."
        launchctl load "$PLIST_FILE"
        if [ $? -eq 0 ]; then
            print_info "LaunchAgent started"
            sleep 1
            check_status
        else
            print_error "Failed to start LaunchAgent"
            return 1
        fi
    else
        print_error "LaunchAgent not found. Run 'install-launchd.sh' first"
        return 1
    fi
}

uninstall_launchd() {
    print_warning "Uninstalling LaunchAgent..."

    # Stop it first
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null
    fi

    # Remove plist
    if [ -f "$PLIST_FILE" ]; then
        rm "$PLIST_FILE"
        print_info "LaunchAgent plist removed"
    fi

    echo ""
    print_warning "⚠️  LaunchAgent has been uninstalled"
    echo "The daemon will no longer:"
    echo "  • Start automatically at login"
    echo "  • Continue running when Mac sleeps"
    echo "  • Automatically restart if it crashes"
}

restart_launchd() {
    print_warning "Restarting LaunchAgent..."
    stop_launchd
    sleep 1
    start_launchd
}

show_logs() {
    if [ "$1" = "follow" ]; then
        # Follow launchd logs
        if [ -f "$LOG_DIR/claude-auto-renew.stdout.log" ]; then
            echo "Following LaunchAgent logs (press Ctrl+C to stop):"
            tail -f "$LOG_DIR/claude-auto-renew.stdout.log"
        else
            print_error "No logs found"
        fi
    else
        # Show last 50 lines
        if [ -f "$LOG_DIR/claude-auto-renew.stdout.log" ]; then
            echo "Last 50 lines of LaunchAgent logs:"
            tail -50 "$LOG_DIR/claude-auto-renew.stdout.log"
        elif [ -f "$LOG_FILE" ]; then
            echo "Last 50 lines of daemon logs:"
            tail -50 "$LOG_FILE"
        else
            print_error "No logs found"
        fi
    fi
}

show_help() {
    cat << 'EOF'
Claude Auto-Renewal LaunchAgent Manager

Usage:
  ./manage-launchd.sh status      - Show current daemon status
  ./manage-launchd.sh start       - Start LaunchAgent
  ./manage-launchd.sh stop        - Stop LaunchAgent
  ./manage-launchd.sh restart     - Restart LaunchAgent
  ./manage-launchd.sh logs        - Show recent logs
  ./manage-launchd.sh logs -f     - Follow logs in real-time
  ./manage-launchd.sh uninstall   - Remove LaunchAgent

What's LaunchAgent?
  • macOS native way to run background services
  • Continues running even when Mac is in sleep
  • Automatically starts at login
  • Automatically restarts if it crashes

Why use LaunchAgent?
  ✓ Your Claude renewal works 24/7
  ✓ Mac no longer needs to be "touched" to wake it up
  ✓ Daemon survives sleep/wake cycles
  ✓ Automatically restarts if it crashes

EOF
}

# Main command handler
case "$1" in
    status)
        check_status
        ;;
    start)
        start_launchd
        ;;
    stop)
        stop_launchd
        ;;
    restart)
        restart_launchd
        ;;
    logs)
        show_logs "$2"
        ;;
    uninstall)
        uninstall_launchd
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
