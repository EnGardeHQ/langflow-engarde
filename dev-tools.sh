#!/bin/bash

# =============================================================================
# EnGarde Development Tools Script
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_help() {
    echo "🛠️  EnGarde Development Tools"
    echo ""
    echo "Usage: ./dev-tools.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start      Start development environment"
    echo "  stop       Stop all services"
    echo "  restart    Restart all services"
    echo "  rebuild    Rebuild and restart services"
    echo "  logs       Follow logs from all services"
    echo "  logs-fe    Follow frontend logs only"
    echo "  logs-be    Follow backend logs only"
    echo "  shell-fe   Access frontend container shell"
    echo "  shell-be   Access backend container shell"
    echo "  shell-db   Access database container shell"
    echo "  status     Show service status"
    echo "  clean      Clean up containers and images"
    echo "  reset      Full reset (stop, clean, rebuild)"
    echo ""
    echo "Examples:"
    echo "  ./dev-tools.sh start     # Start the development environment"
    echo "  ./dev-tools.sh logs-be   # View backend logs"
    echo "  ./dev-tools.sh shell-fe  # Access frontend container"
    echo ""
}

COMPOSE_FILE="docker-compose.dev.yml"

case "${1}" in
    "start")
        echo "🚀 Starting development environment..."
        ./start-dev.sh
        ;;

    "stop")
        echo "🛑 Stopping all services..."
        docker-compose -f $COMPOSE_FILE down
        ;;

    "restart")
        echo "🔄 Restarting all services..."
        docker-compose -f $COMPOSE_FILE restart
        ;;

    "rebuild")
        echo "🔨 Rebuilding and restarting services..."
        docker-compose -f $COMPOSE_FILE down
        docker-compose -f $COMPOSE_FILE build --no-cache
        docker-compose -f $COMPOSE_FILE up -d
        ;;

    "logs")
        echo "📋 Following logs from all services..."
        docker-compose -f $COMPOSE_FILE logs -f
        ;;

    "logs-fe")
        echo "📋 Following frontend logs..."
        docker-compose -f $COMPOSE_FILE logs -f frontend
        ;;

    "logs-be")
        echo "📋 Following backend logs..."
        docker-compose -f $COMPOSE_FILE logs -f backend
        ;;

    "shell-fe")
        echo "🐚 Accessing frontend container..."
        docker-compose -f $COMPOSE_FILE exec frontend /bin/sh
        ;;

    "shell-be")
        echo "🐚 Accessing backend container..."
        docker-compose -f $COMPOSE_FILE exec backend /bin/bash
        ;;

    "shell-db")
        echo "🐚 Accessing database container..."
        docker-compose -f $COMPOSE_FILE exec postgres psql -U engarde_user -d engarde
        ;;

    "status")
        echo "📊 Service status:"
        docker-compose -f $COMPOSE_FILE ps
        ;;

    "clean")
        echo "🧹 Cleaning up..."
        docker-compose -f $COMPOSE_FILE down --remove-orphans
        docker system prune -f
        docker volume prune -f
        ;;

    "reset")
        echo "🔄 Full reset..."
        docker-compose -f $COMPOSE_FILE down --remove-orphans
        docker system prune -f
        docker volume prune -f
        docker-compose -f $COMPOSE_FILE build --no-cache
        ./start-dev.sh
        ;;

    *)
        print_help
        ;;
esac