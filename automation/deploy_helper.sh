#!/bin/bash
################################################################################
# Deployment Automation Helper
# Simplifies deployment processes with pre/post hooks
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

PROJECT_DIR=""
DEPLOY_TYPE="web"
GIT_BRANCH="main"
RUN_TESTS=0
BACKUP_BEFORE=1
RESTART_SERVICES=()

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Deployment Automation Helper"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -p PROJECT_DIR  Project directory [required]
    -t TYPE         Deployment type: web, app, docker [default: web]
    -b BRANCH       Git branch to deploy [default: main]
    -T              Run tests before deployment
    -n              No backup before deployment
    -r SERVICE      Restart service after deployment (can be used multiple times)
    --help          Show this help message

Examples:
    $0 -p /var/www/myapp -b production
    $0 -p /opt/app -t docker -T -r nginx
    $0 -p /home/user/project -T -r apache2 -r mysql
EOF
)"
    exit 0
}

# Pre-deployment checks
pre_deployment_checks() {
    log_header "Pre-Deployment Checks"

    # Check if project directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        die "Project directory not found: $PROJECT_DIR"
    fi
    log_success "Project directory exists"

    # Check if git repository
    if [[ -d "$PROJECT_DIR/.git" ]]; then
        log_success "Git repository detected"
    else
        log_warning "Not a git repository"
    fi

    # Check write permissions
    if [[ -w "$PROJECT_DIR" ]]; then
        log_success "Write permissions OK"
    else
        die "No write permissions for: $PROJECT_DIR"
    fi

    echo
}

# Backup current deployment
backup_deployment() {
    log_header "Creating Backup"

    local backup_name="deploy_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_dir="$PROJECT_DIR/../$backup_name"

    log_info "Backing up to: $backup_dir"

    cp -a "$PROJECT_DIR" "$backup_dir" 2>&1

    if [[ -d "$backup_dir" ]]; then
        log_success "Backup created successfully"
        echo "$backup_dir" > "$PROJECT_DIR/.last_backup"
    else
        log_warning "Backup failed, continuing anyway..."
    fi

    echo
}

# Pull latest code
pull_code() {
    log_header "Pulling Latest Code"

    cd "$PROJECT_DIR" || die "Cannot change to project directory"

    # Fetch updates
    log_info "Fetching from remote..."
    git fetch --all 2>&1 | grep -v "^$"

    # Checkout branch
    log_info "Checking out branch: $GIT_BRANCH"
    git checkout "$GIT_BRANCH" 2>&1 | grep -v "^$"

    # Pull changes
    log_info "Pulling changes..."
    local pull_output=$(git pull origin "$GIT_BRANCH" 2>&1)
    echo "$pull_output"

    if echo "$pull_output" | grep -q "Already up to date"; then
        log_info "No new changes to deploy"
    else
        log_success "Code updated successfully"
    fi

    echo
}

# Run tests
run_tests() {
    log_header "Running Tests"

    cd "$PROJECT_DIR" || die "Cannot change to project directory"

    # Detect test framework and run
    if [[ -f "package.json" ]] && grep -q "\"test\"" package.json; then
        log_info "Running npm tests..."
        npm test
    elif [[ -f "composer.json" ]]; then
        log_info "Running PHP tests..."
        ./vendor/bin/phpunit
    elif [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]]; then
        log_info "Running Python tests..."
        pytest
    elif [[ -f "Makefile" ]] && grep -q "^test:" Makefile; then
        log_info "Running make test..."
        make test
    else
        log_warning "No test framework detected, skipping tests"
        echo
        return
    fi

    if [ $? -eq 0 ]; then
        log_success "All tests passed"
    else
        die "Tests failed! Deployment aborted."
    fi

    echo
}

# Install dependencies
install_dependencies() {
    log_header "Installing Dependencies"

    cd "$PROJECT_DIR" || die "Cannot change to project directory"

    if [[ -f "package.json" ]]; then
        log_info "Installing npm dependencies..."
        npm install --production
    elif [[ -f "composer.json" ]]; then
        log_info "Installing composer dependencies..."
        composer install --no-dev --optimize-autoloader
    elif [[ -f "requirements.txt" ]]; then
        log_info "Installing Python dependencies..."
        pip install -r requirements.txt
    elif [[ -f "Gemfile" ]]; then
        log_info "Installing Ruby dependencies..."
        bundle install --deployment
    else
        log_info "No dependency file found, skipping..."
    fi

    echo
}

# Build assets
build_assets() {
    log_header "Building Assets"

    cd "$PROJECT_DIR" || die "Cannot change to project directory"

    if [[ -f "package.json" ]] && grep -q "\"build\"" package.json; then
        log_info "Running npm build..."
        npm run build
    elif [[ -f "Makefile" ]] && grep -q "^build:" Makefile; then
        log_info "Running make build..."
        make build
    elif [[ -f "docker-compose.yml" ]] && [[ "$DEPLOY_TYPE" == "docker" ]]; then
        log_info "Building Docker containers..."
        docker-compose build
    else
        log_info "No build process detected, skipping..."
    fi

    echo
}

# Restart services
restart_services() {
    log_header "Restarting Services"

    if [ ${#RESTART_SERVICES[@]} -eq 0 ]; then
        log_info "No services to restart"
        echo
        return
    fi

    for service in "${RESTART_SERVICES[@]}"; do
        log_info "Restarting $service..."

        if command_exists systemctl; then
            systemctl restart "$service"
        elif command_exists service; then
            service "$service" restart
        fi

        if [ $? -eq 0 ]; then
            log_success "$service restarted successfully"
        else
            log_error "$service restart failed"
        fi
    done

    echo
}

# Post-deployment tasks
post_deployment() {
    log_header "Post-Deployment Tasks"

    cd "$PROJECT_DIR" || return

    # Clear caches if applicable
    if [[ -f "artisan" ]]; then
        log_info "Clearing Laravel cache..."
        php artisan cache:clear
        php artisan config:cache
        php artisan route:cache
    elif [[ -f "bin/console" ]]; then
        log_info "Clearing Symfony cache..."
        php bin/console cache:clear --env=prod
    fi

    log_success "Post-deployment tasks completed"
    echo
}

# Main deployment process
deploy() {
    log_header "Starting Deployment"
    log_info "Project: $PROJECT_DIR"
    log_info "Type: $DEPLOY_TYPE"
    log_info "Branch: $GIT_BRANCH"
    echo

    local start_time=$(epoch_time)

    # Run deployment steps
    pre_deployment_checks
    ((BACKUP_BEFORE)) && backup_deployment
    pull_code
    ((RUN_TESTS)) && run_tests
    install_dependencies
    build_assets
    restart_services
    post_deployment

    local end_time=$(epoch_time)
    local duration=$(calc_duration "$start_time" "$end_time")

    # Summary
    log_header "Deployment Complete"
    log_success "Deployment successful!"
    log_info "Duration: $duration"
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p)
                PROJECT_DIR="$2"
                shift 2
                ;;
            -t)
                DEPLOY_TYPE="$2"
                shift 2
                ;;
            -b)
                GIT_BRANCH="$2"
                shift 2
                ;;
            -T)
                RUN_TESTS=1
                shift
                ;;
            -n)
                BACKUP_BEFORE=0
                shift
                ;;
            -r)
                RESTART_SERVICES+=("$2")
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate arguments
    require_arg "$PROJECT_DIR" "project directory (-p)"

    if [[ ! "$DEPLOY_TYPE" =~ ^(web|app|docker)$ ]]; then
        die "Invalid deployment type: $DEPLOY_TYPE"
    fi

    # Run deployment
    deploy
}

main "$@"
