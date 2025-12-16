#!/bin/bash

# EnGarde Application Cleanup Script
# This script provides comprehensive cleanup of all application processes and containers
# Usage: ./cleanup.sh [--hard] [--verify-only]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Target ports to check/clean
PORTS=(3000 3001 8000 8001 8002 7860 5432 6379)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended."
    fi
}

# Function to display help
show_help() {
    cat << EOF
EnGarde Application Cleanup Script

USAGE:
    ./cleanup.sh [OPTIONS]

OPTIONS:
    --hard          Perform aggressive cleanup (force kill processes)
    --verify-only   Only check current state, don't perform cleanup
    --help          Show this help message

DESCRIPTION:
    This script performs comprehensive cleanup of:
    - Node.js processes (Next.js dev servers)
    - Python/uvicorn processes (backend servers)
    - Docker containers and networks
    - Port bindings verification
    - Cleanup of stopped containers

EXAMPLES:
    ./cleanup.sh                # Standard cleanup
    ./cleanup.sh --hard         # Aggressive cleanup with force kill
    ./cleanup.sh --verify-only  # Check what's running without cleanup

EOF
}

# Function to find processes by pattern and port
find_processes() {
    local pattern=$1
    local description=$2

    print_status "Searching for $description processes..."

    # Find processes by pattern
    local pids=$(ps aux | grep -E "$pattern" | grep -v grep | awk '{print $2}' || true)

    if [[ -n "$pids" ]]; then
        print_warning "Found $description processes: $pids"
        while IFS= read -r pid; do
            if ps -p $pid > /dev/null 2>&1; then
                local cmd=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
                print_warning "  PID $pid: $cmd"
            fi
        done <<< "$pids"
        echo "$pids"
    else
        print_success "No $description processes found"
        echo ""
    fi
}

# Function to kill processes gracefully or forcefully
kill_processes() {
    local pids=$1
    local description=$2
    local force=${3:-false}

    if [[ -n "$pids" ]]; then
        print_status "Killing $description processes..."

        while IFS= read -r pid; do
            if ps -p $pid > /dev/null 2>&1; then
                if [[ "$force" == "true" ]]; then
                    print_status "Force killing PID $pid..."
                    kill -9 $pid 2>/dev/null || print_warning "Failed to kill PID $pid"
                else
                    print_status "Gracefully terminating PID $pid..."
                    kill -TERM $pid 2>/dev/null || print_warning "Failed to terminate PID $pid"
                    sleep 2
                    # Check if still running, then force kill
                    if ps -p $pid > /dev/null 2>&1; then
                        print_status "Force killing PID $pid..."
                        kill -9 $pid 2>/dev/null || print_warning "Failed to force kill PID $pid"
                    fi
                fi
            fi
        done <<< "$pids"

        # Wait a moment and verify
        sleep 1
        local remaining=$(ps aux | grep -E "$description" | grep -v grep | awk '{print $2}' || true)
        if [[ -n "$remaining" ]]; then
            print_error "Some $description processes are still running: $remaining"
            return 1
        else
            print_success "All $description processes terminated"
        fi
    fi
}

# Function to check port usage
check_ports() {
    print_status "Checking port usage..."

    for port in "${PORTS[@]}"; do
        local proc=$(lsof -ti :$port 2>/dev/null || true)
        if [[ -n "$proc" ]]; then
            local details=$(lsof -i :$port 2>/dev/null | tail -n +2 || true)
            print_warning "Port $port is in use:"
            echo "$details" | while IFS= read -r line; do
                print_warning "  $line"
            done
        else
            print_success "Port $port is free"
        fi
    done
}

# Function to handle Docker cleanup
cleanup_docker() {
    print_status "Starting Docker cleanup..."

    # Check if docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running"
        return 1
    fi

    # Stop all running containers
    local running_containers=$(docker ps -q 2>/dev/null || true)
    if [[ -n "$running_containers" ]]; then
        print_status "Stopping running containers..."
        echo "$running_containers" | while IFS= read -r container; do
            local name=$(docker ps --format "table {{.Names}}" --filter "id=$container" | tail -n +2)
            print_status "Stopping container: $name ($container)"
        done
        docker stop $running_containers 2>/dev/null || true
    else
        print_success "No running containers found"
    fi

    # Use docker-compose down if docker-compose.yml exists
    if [[ -f "docker-compose.yml" ]]; then
        print_status "Running docker-compose down..."
        docker-compose down 2>/dev/null || print_warning "docker-compose down failed"
    fi

    # Remove stopped containers
    print_status "Removing stopped containers..."
    local removed=$(docker container prune -f 2>/dev/null || true)
    if [[ "$removed" == *"Total reclaimed space"* ]]; then
        print_success "Containers cleaned up: $(echo "$removed" | grep "Total reclaimed space" | cut -d: -f2)"
    else
        print_success "No stopped containers to remove"
    fi

    # Remove unused networks
    print_status "Removing unused networks..."
    docker network prune -f >/dev/null 2>&1 || true
    print_success "Docker networks cleaned up"
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."

    # Check for processes directly without verbose output
    local node_procs=$(ps aux | grep -E "(node.*next|node.*dev)" | grep -v grep | awk '{print $2}' || true)
    local python_procs=$(ps aux | grep -E "(uvicorn|gunicorn)" | grep -v grep | awk '{print $2}' || true)
    local containers=$(docker ps -q 2>/dev/null || true)

    local issues_found=false

    if [[ -n "$node_procs" ]]; then
        print_error "Node.js processes still running: $node_procs"
        issues_found=true
    else
        print_success "No Node.js processes found"
    fi

    if [[ -n "$python_procs" ]]; then
        print_error "Python backend processes still running: $python_procs"
        issues_found=true
    else
        print_success "No Python backend processes found"
    fi

    if [[ -n "$containers" ]]; then
        print_error "Docker containers still running: $containers"
        issues_found=true
    else
        print_success "No Docker containers running"
    fi

    check_ports

    if [[ "$issues_found" == "false" ]]; then
        print_success "System cleanup verified - all clear!"
    else
        print_error "Cleanup verification failed - some processes/containers still running"
        return 1
    fi
}

# Main cleanup function
main_cleanup() {
    local force=$1

    print_status "Starting EnGarde application cleanup..."
    print_status "Timestamp: $(date)"

    # Find and kill Node.js processes
    local node_pids=$(find_processes "(node.*next|node.*dev)" "Node.js development")
    if [[ -n "$node_pids" ]]; then
        kill_processes "$node_pids" "Node.js" "$force"
    fi

    # Find and kill Python processes
    local python_pids=$(find_processes "(uvicorn|gunicorn)" "Python backend")
    if [[ -n "$python_pids" ]]; then
        kill_processes "$python_pids" "Python backend" "$force"
    fi

    # Docker cleanup
    cleanup_docker

    # Verify cleanup
    sleep 2
    verify_cleanup
}

# Parse command line arguments
HARD_CLEANUP=false
VERIFY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --hard)
            HARD_CLEANUP=true
            shift
            ;;
        --verify-only)
            VERIFY_ONLY=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_status "EnGarde Application Cleanup Script"
    print_status "=================================="

    check_permissions

    if [[ "$VERIFY_ONLY" == "true" ]]; then
        print_status "Running in verification mode only"
        verify_cleanup
    else
        main_cleanup "$HARD_CLEANUP"
        print_success "Cleanup completed successfully!"
        print_status "You can now start fresh instances of your applications"
        print_status ""
        print_status "To start the application:"
        print_status "  Frontend: cd production-frontend && npm run dev"
        print_status "  Backend:  cd production-backend && python3 -m uvicorn app.main:app --reload --port 8000"
        print_status "  Docker:   docker-compose up"
    fi
}

# Run main function
main "$@"