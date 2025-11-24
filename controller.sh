#!/bin/bash

# Minecraft Server Controller Script
# Manages dependencies, server operations, and player monitoring

set -e

CONTAINER_NAME="minecraft-server"
COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if running as root/sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script requires sudo privileges for installation"
        print_info "Run with: sudo ./controller.sh install"
        exit 1
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is installed ($(docker --version))"
        return 0
    else
        print_error "Docker is not installed"
        return 1
    fi
}

# Check if Docker Compose is installed
check_docker_compose() {
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is installed ($(docker compose version))"
        return 0
    else
        print_error "Docker Compose is not installed"
        return 1
    fi
}

# Install Docker
install_docker() {
    print_info "Installing Docker..."

    # Update package list
    apt update

    # Install required packages
    apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package list again
    apt update

    # Install Docker
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add current user to docker group
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
        print_success "Added $SUDO_USER to docker group"
    fi

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    print_success "Docker installed successfully"
    print_info "Please log out and back in for group changes to take effect"
}

# Install all dependencies
install_dependencies() {
    check_sudo

    print_info "Checking dependencies..."

    local need_install=false

    if ! check_docker; then
        need_install=true
    fi

    if ! check_docker_compose; then
        need_install=true
    fi

    if [ "$need_install" = true ]; then
        install_docker
        print_success "All dependencies installed"
    else
        print_success "All dependencies are already installed"
    fi
}

# Check if server is running
is_running() {
    if docker ps --filter "name=$CONTAINER_NAME" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
        return 0
    else
        return 1
    fi
}

# Start the server
start_server() {
    print_info "Starting Minecraft server..."

    if is_running; then
        print_info "Server is already running"
        return 0
    fi

    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "docker-compose.yml not found"
        exit 1
    fi

    docker compose up -d

    if is_running; then
        print_success "Server started successfully"
        print_info "View logs with: ./controller.sh logs"
    else
        print_error "Failed to start server"
        exit 1
    fi
}

# Stop the server
stop_server() {
    print_info "Stopping Minecraft server..."

    if ! is_running; then
        print_info "Server is not running"
        return 0
    fi

    docker compose stop
    print_success "Server stopped"
}

# Restart the server
restart_server() {
    print_info "Restarting Minecraft server..."
    docker compose restart
    print_success "Server restarted"
}

# Get server status
status_server() {
    print_info "Server Status:"
    echo ""

    if is_running; then
        print_success "Server is RUNNING"
        echo ""
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        print_error "Server is STOPPED"
    fi
}

# View server logs
view_logs() {
    if ! is_running; then
        print_error "Server is not running"
        exit 1
    fi

    print_info "Viewing server logs (Ctrl+C to exit)..."
    docker compose logs -f minecraft
}

# Check number of players
check_players() {
    if ! is_running; then
        print_error "Server is not running"
        exit 1
    fi

    print_info "Checking player count..."

    # Use RCON to get player list
    player_output=$(docker exec "$CONTAINER_NAME" rcon-cli list 2>/dev/null || echo "Error")

    if [ "$player_output" = "Error" ]; then
        print_error "Failed to connect to server (is RCON enabled?)"
        exit 1
    fi

    echo ""
    echo "$player_output"
    echo ""

    # Extract player count
    if echo "$player_output" | grep -q "There are"; then
        player_count=$(echo "$player_output" | grep -oP 'There are \K\d+')
        max_players=$(echo "$player_output" | grep -oP 'of a max of \K\d+')

        echo "Players online: $player_count / $max_players"
    fi
}

# Execute server command
exec_command() {
    if ! is_running; then
        print_error "Server is not running"
        exit 1
    fi

    if [ -z "$1" ]; then
        print_error "No command provided"
        print_info "Usage: ./controller.sh exec <command>"
        exit 1
    fi

    print_info "Executing command: $1"
    docker exec "$CONTAINER_NAME" rcon-cli "$1"
}

# Update server
update_server() {
    print_info "Updating Minecraft server..."

    docker compose pull
    docker compose up -d

    print_success "Server updated"
}

# Backup server
backup_server() {
    print_info "Creating server backup..."

    local backup_name="minecraft-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    if is_running; then
        print_info "Stopping server for backup..."
        docker compose stop
        local was_running=true
    fi

    if [ ! -d "data" ]; then
        print_error "Data directory not found"
        exit 1
    fi

    tar -czf "$backup_name" data/

    if [ "$was_running" = true ]; then
        print_info "Restarting server..."
        docker compose start
    fi

    print_success "Backup created: $backup_name"
}

# Show help
show_help() {
    cat << EOF
Minecraft Server Controller

Usage: ./controller.sh [command]

Commands:
  install       Install Docker and dependencies (requires sudo)
  check         Check if dependencies are installed

  start         Start the Minecraft server
  stop          Stop the Minecraft server
  restart       Restart the Minecraft server
  status        Show server status

  logs          View server logs (real-time)
  players       Check number of players online
  exec <cmd>    Execute a server command via RCON

  update        Update server to latest version
  backup        Create a backup of server data

  help          Show this help message

Examples:
  ./controller.sh install
  ./controller.sh start
  ./controller.sh players
  ./controller.sh exec "say Hello everyone!"
  ./controller.sh backup

EOF
}

# Main script logic
case "${1:-}" in
    install)
        install_dependencies
        ;;
    check)
        check_docker
        check_docker_compose
        ;;
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        status_server
        ;;
    logs)
        view_logs
        ;;
    players)
        check_players
        ;;
    exec)
        exec_command "${2:-}"
        ;;
    update)
        update_server
        ;;
    backup)
        backup_server
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        echo ""
        show_help
        exit 1
        ;;
esac
