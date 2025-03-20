#!/usr/bin/env zsh

# Script: pyenv-setup.sh
# Description: Sets up Python environments with pyenv, UV, auto-activation, and development tools

set -e  # Exit immediately if a command exits with non-zero status

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display help
show_help() {
    echo "Usage: ./pyenv-setup.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message and exit"
    echo "  -v, --version VERSION     The Python version to use (default: 3.12)"
    echo "  -d, --directory DIR       The project directory path (default: current directory)"
    echo "  -n, --name NAME           Custom name for the virtual environment (not used with local .venv)"
    echo "  -r, --requirements FILE   Path to requirements.txt file"
    echo "  --docker                  Generate Docker configuration files"
    echo ""
    echo "Examples:"
    echo "  ./pyenv-setup.sh                                # Use Python 3.12 in current directory"
    echo "  ./pyenv-setup.sh -v 3.11                        # Use Python 3.11 in current directory" 
    echo "  ./pyenv-setup.sh -v 3.10 -d ~/projects/my_project  # Use Python 3.10 in specified directory"
    echo "  ./pyenv-setup.sh -r requirements.txt            # Use requirements.txt file"
    echo "  ./pyenv-setup.sh --docker                       # Generate Docker configuration files"
    echo ""
    echo "Notes:"
    echo "  - The virtual environment is created as a .venv directory in the project folder"
    echo "  - If the project directory doesn't exist, it will be created"
    echo "  - If .venv already exists, you'll be asked whether to recreate it"
    echo "  - Standard directories will be created: src, tests, docs, scripts"
    echo "  - UV is used for fast package management"
    echo "  - Development tools include: black, flake8, mypy, pytest, and pre-commit hooks"
    echo "  - Auto-activation setup: direnv (.envrc) if available, or activate.sh script"
}

# Function to install packages with UV
install_packages() {
    # This function is no longer needed as package installation is handled in create_pyenv_venv
    return 0
}

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
    print_message "$YELLOW" "pyenv is not installed. Installing now..."
    # Install pyenv
    curl -s https://pyenv.run | bash
    
    # Add pyenv to PATH and initialize
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc
    
    # Source the updated zshrc
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    print_message "$GREEN" "pyenv installed successfully!"
fi

# Check if pyenv-virtualenv is installed
if [ ! -d "$(pyenv root)/plugins/pyenv-virtualenv" ]; then
    print_message "$YELLOW" "pyenv-virtualenv is not installed. Installing now..."
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)/plugins/pyenv-virtualenv"
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
    
    # Initialize virtualenv-init right away
    eval "$(pyenv virtualenv-init -)"
    
    print_message "$GREEN" "pyenv-virtualenv installed successfully!"
else
    # Ensure virtualenv-init is properly configured in the user's shell
    if ! grep -q "pyenv virtualenv-init" ~/.zshrc; then
        print_message "$YELLOW" "Adding pyenv virtualenv-init to ~/.zshrc..."
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
        
        # Initialize virtualenv-init right away for this session
        eval "$(pyenv virtualenv-init -)"
        
        print_message "$GREEN" "Added pyenv virtualenv-init to ~/.zshrc"
    fi
    
    # Ensure virtualenv-init is active in the current session
    if ! env | grep -q "PYENV_VIRTUALENV_INIT=1"; then
        print_message "$YELLOW" "Initializing pyenv-virtualenv for current session..."
        eval "$(pyenv virtualenv-init -)"
    fi
fi

# Function to install UV
install_uv() {
    if ! command -v uv &> /dev/null; then
        print_message "$YELLOW" "UV package manager not found. Installing now..."
        
        # Install UV using the official installer
        curl -LsSf https://astral.sh/uv/install.sh | sh

        # Add UV to PATH
        if [[ ! -f ~/.zshrc ]] || ! grep -q "uv" ~/.zshrc; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        
        print_message "$GREEN" "UV installed successfully!"
    else
        print_message "$BLUE" "UV package manager is already installed."
    fi
}

# Function to create a sample .env file
create_env_file() {
    cat > .env << EOF
# Environment Variables for $(basename "$(pwd)")
# Created on $(date)

# Development Settings
DEBUG=True
LOG_LEVEL=DEBUG

# Application Settings
APP_NAME=$(basename "$(pwd)")
APP_ENV=development
APP_SECRET=replace_this_with_a_real_secret_key

# Database Settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$(basename "$(pwd)")_db
DB_USER=postgres
DB_PASSWORD=postgres

# API Settings
API_URL=http://localhost:8000
API_VERSION=v1
API_TIMEOUT=30

# Paths
DATA_DIR=./data
LOGS_DIR=./logs
EOF
    print_message "$GREEN" "Created sample .env file"
}

# Function to create a pyproject.toml file
create_pyproject_toml() {
    local python_version=$1
    cat > pyproject.toml << EOF
[build-system]
requires = ["setuptools>=42", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "$(basename "$(pwd)")"
version = "0.1.0"
description = "$(basename "$(pwd)") project"
readme = "README.md"
requires-python = ">=$(echo $python_version | cut -d. -f1).$(echo $python_version | cut -d. -f2)"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]

[project.optional-dependencies]
dev = [
    "black",
    "flake8",
    "mypy",
    "pylint",
    "pytest",
    "pre-commit",
]

[tool.black]
line-length = 100
target-version = ["py$(echo $python_version | cut -d. -f1)$(echo $python_version | cut -d. -f2)"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"
EOF
    print_message "$GREEN" "Created pyproject.toml file with UV configuration"
}

# Function to create a .gitignore file
create_gitignore() {
    cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Environment
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# UV
.uv/

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Logs
logs/
*.log

# OS specific
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
    print_message "$GREEN" "Created .gitignore file"
}

# Function to create flake8 configuration
create_flake8_config() {
    cat > .flake8 << EOF
[flake8]
max-line-length = 100
exclude = .git,__pycache__,docs/source/conf.py,old,build,dist,.venv,.uv
ignore = E203, W503
per-file-ignores =
    __init__.py: F401
EOF
    print_message "$GREEN" "Created flake8 configuration"
}

# Function to create mypy configuration
create_mypy_config() {
    cat > mypy.ini << EOF
[mypy]
python_version = ${1}
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
disallow_untyped_decorators = False
no_implicit_optional = True
strict_optional = True

[mypy.plugins.numpy.*]
follow_imports = silent

[mypy-pytest.*]
ignore_missing_imports = True
EOF
    print_message "$GREEN" "Created mypy configuration"
}

# Function to create pre-commit configuration
create_precommit_config() {
    cat > .pre-commit-config.yaml << EOF
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files
    -   id: check-json
    -   id: check-merge-conflict
    -   id: detect-private-key

-   repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
    -   id: black
        args: [--line-length=100]

-   repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
    -   id: flake8
        additional_dependencies: [flake8-docstrings]

-   repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
    -   id: mypy
        exclude: ^tests/
        additional_dependencies: [types-requests, types-PyYAML]
EOF
    print_message "$GREEN" "Created pre-commit configuration"
}

# Function to create a README.md
create_readme() {
    local python_version=$1
    local venv_name=$2
    cat > README.md << EOF
# $(basename "$(pwd)")

Created with pyenv-setup on $(date)

## Environment

* Python version: $python_version
* Virtual environment: Local .venv directory
* Package manager: UV

## Project Structure

\`\`\`
├── .venv/            # Local virtual environment (not committed to git)
├── docs/             # Documentation files
├── scripts/          # Utility scripts
├── src/              # Source code
├── tests/            # Test files
├── .env              # Environment variables (DO NOT COMMIT)
├── .flake8           # Flake8 configuration
├── .gitignore        # Git ignore rules
├── .pre-commit-config.yaml  # Pre-commit hooks configuration
├── activate.sh       # Helper script to activate the environment
├── mypy.ini          # MyPy configuration
├── pyproject.toml    # Project configuration and UV settings
└── README.md         # This file
\`\`\`

## Setup

1. Clone this repository
2. Ensure pyenv is installed
3. Activate the virtual environment:
   - Using direnv (if installed): cd into the directory (auto-activates)
   - Manually: \`source .venv/bin/activate\` or \`./activate.sh\`

## Development

This project uses:
- UV for fast package management
- Black for code formatting
- Flake8 for linting
- MyPy for type checking
- Pre-commit hooks for automated checks

To install dependencies:
\`\`\`bash
pip install -e .
\`\`\`

To install development dependencies:
\`\`\`bash
pip install -e ".[dev]"
\`\`\`

To run the tests:
\`\`\`bash
pytest
\`\`\`
EOF
    print_message "$GREEN" "Created README.md with project structure documentation"
}

# Function to create and configure a Python virtual environment
create_pyenv_venv() {
    local python_version=$1
    local project_dir=$2
    local venv_name=${3:-$(basename "$project_dir")}
    local requirements_file=${4:-""}
    local recreate_venv=false
    
    # Check if the Python version is installed
    if ! pyenv versions | grep -q "$python_version"; then
        print_message "$YELLOW" "Installing Python $python_version..."
        pyenv install "$python_version"
        print_message "$GREEN" "Python $python_version installed successfully!"
    else
        print_message "$BLUE" "Python $python_version is already installed."
    fi
    
    # Create project directory if it doesn't exist
    print_message "$YELLOW" "Creating/using project directory: $project_dir"
    mkdir -p "$project_dir"
    cd "$project_dir" || exit
    
    # Set the local Python version for the project directory
    pyenv local "$python_version"
    
    # Check if the .venv directory already exists
    if [ -d ".venv" ]; then
        print_message "$YELLOW" "Virtual environment '.venv' already exists in this directory."
        read -p "Do you want to recreate it? (y/n): " choice
        case "$choice" in
            y|Y ) 
                print_message "$YELLOW" "Removing existing .venv directory..."
                rm -rf .venv
                recreate_venv=true
                ;;
            * ) 
                print_message "$BLUE" "Using existing .venv directory."
                ;;
        esac
    else
        recreate_venv=true
    fi
    
    # Create virtual environment if needed
    if $recreate_venv; then
        print_message "$YELLOW" "Creating virtual environment '.venv' with Python $python_version..."
        python -m venv .venv
    fi
    
    # Add .venv to .gitignore if not already there
    if ! grep -q "^\.venv/$" .gitignore 2>/dev/null; then
        echo ".venv/" >> .gitignore
    fi
    
    # Activate the virtual environment for the current session
    source .venv/bin/activate
    
    # Initialize Git repository if not already initialized
    if [ ! -d ".git" ]; then
        print_message "$YELLOW" "Initializing Git repository..."
        git init
        print_message "$GREEN" "Git repository initialized!"
    else
        print_message "$BLUE" "Git repository already initialized."
    fi
    
    # Create standard project directories and structure
    print_message "$YELLOW" "Creating project structure..."
    mkdir -p src tests docs scripts data logs
    
    # Initialize Python packages
    touch src/__init__.py
    touch tests/__init__.py
    
    # Create a basic conftest.py for pytest
    cat > tests/conftest.py << EOF
# -*- coding: utf-8 -*-
"""
Pytest configuration file.
Define fixtures and configuration for tests.
"""
import pytest

# Add your fixtures here
EOF
    
    # Create a sample test file
    cat > tests/test_sample.py << EOF
# -*- coding: utf-8 -*-
"""
Sample test file.
"""
import os
import sys
import pytest


def test_sample():
    """Sample test function."""
    assert True


def test_virtual_environment():
    """Test that we're running in the virtual environment."""
    # Check if we're running in a virtual environment
    assert sys.prefix != sys.base_prefix, "Not running in a virtual environment"
    
    # Check if we can import installed packages
    try:
        import pytest
        assert pytest is not None
    except ImportError:
        pytest.fail("Failed to import pytest - environment may not be set up correctly")


def test_project_imports():
    """Test that we can import project modules."""
    # Add parent directory to path
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    if project_root not in sys.path:
        sys.path.insert(0, project_root)
    
    # Try importing the core module
    try:
        from src.$(basename "$project_dir").core import get_version
        assert get_version() is not None
    except ImportError as e:
        pytest.fail(f"Failed to import project module: {e}")
EOF
    
    # Create sample module 
    mkdir -p src/$(basename "$project_dir")
    cat > src/$(basename "$project_dir")/__init__.py << EOF
# -*- coding: utf-8 -*-
"""
$(basename "$project_dir") package.
"""

__version__ = '0.1.0'
EOF
    
    # Create a basic module file
    cat > src/$(basename "$project_dir")/core.py << EOF
# -*- coding: utf-8 -*-
"""
Core functionality for $(basename "$project_dir").
"""

def get_version():
    """Return the package version."""
    from . import __version__
    return __version__
EOF
    
    # Create a basic README for docs
    cat > docs/README.md << EOF
# Documentation

This directory contains documentation for the project.

## Structure

- \`api/\`: API documentation (auto-generated)
- \`user/\`: User guides and tutorials
- \`development/\`: Development guides

## Building Documentation

Instructions for building documentation will go here.
EOF
    
    # Create a sample script
    cat > scripts/run.py << EOF
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Example script for running the application.
"""
import sys
import os

# Add parent directory to path so we can import our package
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.$(basename "$project_dir").core import get_version

def main():
    """Main entry point."""
    print(f"Running $(basename "$project_dir") version {get_version()}")
    # Add your code here

if __name__ == "__main__":
    main()
EOF
    chmod +x scripts/run.py
    
    # Create a sample .env file
    create_env_file
    
    # Create a basic .gitignore if it doesn't exist
    if [ ! -f .gitignore ]; then
        create_gitignore
    fi
    
    # Update pip and install packages
    print_message "$YELLOW" "Updating pip and installing packages..."
    pip install --upgrade pip

    # Install UV within the virtual environment if needed
    if ! command -v uv &> /dev/null; then
        print_message "$YELLOW" "Installing UV package manager in the virtual environment..."
        pip install uv
    fi
    
    # Create pyproject.toml for UV
    create_pyproject_toml "$python_version"
    
    # Install required packages if a requirements file is provided
    if [ -n "$requirements_file" ] && [ -f "$requirements_file" ]; then
        print_message "$YELLOW" "Installing packages from $requirements_file..."
        pip install -r "$requirements_file"
        print_message "$GREEN" "Packages installed successfully!"
    else
        # Install development packages
        print_message "$YELLOW" "Installing development packages..."
        pip install black flake8 mypy pylint pytest pre-commit
        print_message "$GREEN" "Development packages installed!"
    fi
    
    # Set up flake8 configuration
    create_flake8_config
    
    # Set up mypy configuration
    create_mypy_config "$python_version"
    
    # Set up pre-commit hooks
    create_precommit_config
    
    # Initialize pre-commit
    print_message "$YELLOW" "Setting up pre-commit hooks..."
    # Ensure there's at least one commit before initializing pre-commit hooks
    if ! git rev-parse --verify HEAD &> /dev/null; then
        print_message "$YELLOW" "Creating initial commit for pre-commit hooks..."
        git add .
        git commit -m "Initial commit" --no-verify
    fi
    
    if command -v pre-commit &> /dev/null; then
        pre-commit install
        print_message "$GREEN" "Pre-commit hooks installed successfully!"
    else
        print_message "$YELLOW" "Warning: pre-commit executable not found in virtual environment."
        print_message "$YELLOW" "You may need to manually run: 'pre-commit install' after setup."
    fi
    
    # Create a README.md if it doesn't exist
    if [ ! -f README.md ]; then
        create_readme "$python_version" ".venv"
    fi
    
    # Create .envrc file for direnv auto-activation (if installed)
    if command -v direnv &> /dev/null; then
        print_message "$YELLOW" "Creating .envrc for direnv auto-activation..."
        echo "source .venv/bin/activate" > .envrc
        direnv allow
    else
        # Create activation script for manual activation
        print_message "$YELLOW" "Creating activate.sh script for manual activation..."
        cat > activate.sh << EOF
#!/bin/bash
source .venv/bin/activate
EOF
        chmod +x activate.sh
    fi
    
    # Deactivate the virtual environment
    deactivate
    
    print_message "$GREEN" "Virtual environment created and configured successfully!"
    print_message "$BLUE" "To activate the environment manually, run: source .venv/bin/activate"
    if [ -f "activate.sh" ]; then
        print_message "$BLUE" "Or run: ./activate.sh"
    fi
    if command -v direnv &> /dev/null; then
        print_message "$BLUE" "The environment will auto-activate with direnv when you enter $project_dir"
    fi
}

# Function to create a Dockerfile
create_dockerfile() {
    local python_version=$1
    local project_dir=$2
    
    print_message "$YELLOW" "Creating Dockerfile..."
    
    cat > "$project_dir/Dockerfile" << EOF
FROM python:$python_version-slim

WORKDIR /app

# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Default command
CMD ["python", "src/app.py"]
EOF
    
    print_message "$GREEN" "Dockerfile created successfully!"
}

# Function to create a docker-compose.yml file
create_docker_compose() {
    local python_version=$1
    local project_dir=$2
    local project_name=$(basename "$project_dir")
    
    print_message "$YELLOW" "Creating docker-compose.yml..."
    
    cat > "$project_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/app
    environment:
      - PYTHONPATH=/app
      - PYTHONDONTWRITEBYTECODE=1
      - PYTHONUNBUFFERED=1
    ports:
      - "8000:8000"
    command: python src/app.py
    # Uncomment for development with auto-reload
    # command: python -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
EOF
    
    print_message "$GREEN" "docker-compose.yml created successfully!"
}

# Function to create a .dockerignore file
create_dockerignore() {
    local project_dir=$1
    
    print_message "$YELLOW" "Creating .dockerignore..."
    
    cat > "$project_dir/.dockerignore" << EOF
# Git
.git
.gitignore

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
.env
.venv
env/
venv/
ENV/
.python-version

# IDE
.idea/
.vscode/
*.swp
*.swo

# Project specific
.pytest_cache/
.coverage
htmlcov/
.tox/

# Docker specific
Dockerfile
docker-compose.yml
EOF
    
    print_message "$GREEN" ".dockerignore created successfully!"
}

# Function to update README.md with Docker instructions
update_readme_with_docker_info() {
    local project_dir=$1
    local python_version=$2
    local readme_file="$project_dir/README.md"
    
    # Check if README.md exists
    if [ -f "$readme_file" ]; then
        # Check if Docker section already exists
        if ! grep -q "## Docker" "$readme_file"; then
            print_message "$YELLOW" "Updating README.md with Docker information..."
            
            # Append Docker section to README.md
            cat >> "$readme_file" << EOF

## Docker

This project supports Docker for containerized development and deployment.

### Development with Docker

To start the development environment using Docker:

```bash
docker-compose up
```

### Building the Docker image

To build the Docker image:

```bash
docker build -t project-name .
```

### Running the Docker container

To run the Docker container:

```bash
docker run -p 8000:8000 project-name
```

### Docker configuration

- Dockerfile: Contains the instructions to build the Docker image.
- docker-compose.yml: Configuration for Docker Compose to run multiple services.
- .dockerignore: Specifies which files should be excluded from the Docker build context.
EOF
            
            print_message "$GREEN" "README.md updated with Docker information!"
        else
            print_message "$YELLOW" "Docker section already exists in README.md. No changes made."
        fi
    else
        # Create README.md with Docker information
        create_readme "$python_version" "dockerized"
    fi
}

# Function to set up Docker configuration
setup_docker() {
    local python_version=$1
    local project_dir=$2
    
    print_message "$BLUE" "Setting up Docker configuration..."
    
    # Create Dockerfile
    create_dockerfile "$python_version" "$project_dir"
    
    # Create docker-compose.yml
    create_docker_compose "$python_version" "$project_dir"
    
    # Create .dockerignore
    create_dockerignore "$project_dir"
    
    # Update README.md with Docker instructions
    update_readme_with_docker_info "$project_dir" "$python_version"
    
    print_message "$GREEN" "Docker configuration set up successfully!"
}

# Set default values
DEFAULT_PYTHON_VERSION="3.12"
DEFAULT_PROJECT_DIR="$(pwd)"

# Parse command line options
PYTHON_VERSION=$DEFAULT_PYTHON_VERSION
PROJECT_DIR=$DEFAULT_PROJECT_DIR
VENV_NAME=""
REQUIREMENTS_FILE=""
DOCKER_CONFIG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: -v|--version requires a Python version argument."
                exit 1
            fi
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -d|--directory)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: -d|--directory requires a directory path argument."
                exit 1
            fi
            PROJECT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: -n|--name requires a virtual environment name argument."
                exit 1
            fi
            VENV_NAME="$2"
            shift 2
            ;;
        -r|--requirements)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: -r|--requirements requires a file path argument."
                exit 1
            fi
            REQUIREMENTS_FILE="$2"
            shift 2
            ;;
        --docker)
            DOCKER_CONFIG=true
            shift
            ;;
        *)
            # For backward compatibility, accept positional arguments
            if [[ -z "$PYTHON_VERSION" || "$PYTHON_VERSION" == "$DEFAULT_PYTHON_VERSION" ]]; then
                PYTHON_VERSION="$1"
            elif [[ -z "$PROJECT_DIR" || "$PROJECT_DIR" == "$DEFAULT_PROJECT_DIR" ]]; then
                PROJECT_DIR="$1"
            elif [[ -z "$VENV_NAME" ]]; then
                VENV_NAME="$1"
            elif [[ -z "$REQUIREMENTS_FILE" ]]; then
                REQUIREMENTS_FILE="$1"
            else
                print_message "$RED" "Error: Unexpected argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

print_message "$BLUE" "Using Python version: $PYTHON_VERSION"
print_message "$BLUE" "Project directory: $PROJECT_DIR"
if [ -n "$VENV_NAME" ]; then
    print_message "$BLUE" "Virtual environment name: $VENV_NAME (note: using local .venv directory instead)"
else
    print_message "$BLUE" "Virtual environment will be created in .venv directory"
fi
if [ -n "$REQUIREMENTS_FILE" ]; then
    print_message "$BLUE" "Requirements file: $REQUIREMENTS_FILE"
fi

# Install UV globally
install_uv

# Main script execution
# Resolve project directory (convert to absolute path if needed)
if [[ "$PROJECT_DIR" != /* ]]; then
    # Convert relative path to absolute, if the directory exists
    if [ -d "$PROJECT_DIR" ]; then
        PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"
    else
        # For non-existent directories, create the full path
        PROJECT_DIR="$(pwd)/$PROJECT_DIR"
    fi
fi

# Set up pyenv environment
create_pyenv_venv "$PYTHON_VERSION" "$PROJECT_DIR" "$VENV_NAME" "$REQUIREMENTS_FILE"

# Set up Docker configuration if requested
if $DOCKER_CONFIG; then
    setup_docker "$PYTHON_VERSION" "$PROJECT_DIR"
fi

# Print completion message
print_message "$GREEN" "Setup completed successfully!"
if $DOCKER_CONFIG; then
    print_message "$BLUE" "Docker configuration files have been generated."
    print_message "$BLUE" "You can now use 'docker-compose up' to start the Docker environment."
fi