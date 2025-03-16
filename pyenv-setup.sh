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
    echo "  -n, --name NAME           Custom name for the virtual environment"
    echo "  -r, --requirements FILE   Path to requirements.txt file"
    echo ""
    echo "Examples:"
    echo "  ./pyenv-setup.sh                                # Use Python 3.12 in current directory"
    echo "  ./pyenv-setup.sh -v 3.11                        # Use Python 3.11 in current directory" 
    echo "  ./pyenv-setup.sh -v 3.10 -d ~/projects/my_project  # Use Python 3.10 in specified directory"
    echo "  ./pyenv-setup.sh -v 3.9 -d . -n custom_venv_name   # Use Python 3.9 in current dir with custom venv name"
    echo "  ./pyenv-setup.sh -r requirements.txt            # Use requirements.txt file"
    echo ""
    echo "Notes:"
    echo "  - The virtual environment will auto-activate when entering the project directory"
    echo "  - If the project directory doesn't exist, it will be created"
    echo "  - If venv_name isn't provided, the project directory name will be used"
    echo "  - If a virtual environment with the specified name already exists, a new one named 'env-{random}' will be created"
    echo "  - Standard directories will be created: src, tests, docs, scripts"
    echo "  - UV is used for fast package management"
    echo "  - Development tools include: black, flake8, mypy, pytest, and pre-commit hooks"
}

# Function to install packages with UV
install_packages() {
    local venv_name=$1
    local requirements_file=$2
    local recreate_venv=$3
    local python_version=$4
    
    # Install UV within the virtual environment if needed
    if $recreate_venv || ! command -v uv &> /dev/null; then
        print_message "$YELLOW" "Installing UV package manager in the virtual environment..."
        pip install uv
    fi
    
    # Create pyproject.toml for UV
    create_pyproject_toml "$python_version"
    
    # Make sure we're using the correct virtual environment
    if command -v pyenv &> /dev/null; then
        eval "$(pyenv init -)"
        pyenv shell "$venv_name"
        
        # Install required packages if a requirements file is provided
        if [ -n "$requirements_file" ] && [ -f "$requirements_file" ]; then
            print_message "$YELLOW" "Installing packages from $requirements_file using UV..."
            pip install --upgrade pip
            # Use pip instead of UV if we're having issues with the environment
            pip install -r "$requirements_file"
            print_message "$GREEN" "Packages installed successfully!"
        else
            # Install development packages
            print_message "$YELLOW" "Installing development packages..."
            pip install --upgrade pip
            pip install black flake8 mypy pylint pytest pre-commit
            print_message "$GREEN" "Development packages installed!"
        fi
        
        # Reset shell
        pyenv shell --unset
    else
        print_message "$RED" "Error: pyenv is not available in the current environment."
        print_message "$YELLOW" "Installing packages with standard pip..."
        
        if [ -n "$requirements_file" ] && [ -f "$requirements_file" ]; then
            pip install -r "$requirements_file"
        else
            pip install black flake8 mypy pylint pytest pre-commit
        fi
    fi
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
* Virtual environment: $venv_name
* Package manager: UV

## Project Structure

\`\`\`
├── docs/             # Documentation files
├── scripts/          # Utility scripts
├── src/              # Source code
├── tests/            # Test files
├── .env              # Environment variables (DO NOT COMMIT)
├── .flake8           # Flake8 configuration
├── .gitignore        # Git ignore rules
├── .pre-commit-config.yaml  # Pre-commit hooks configuration
├── mypy.ini          # MyPy configuration
├── pyproject.toml    # Project configuration and UV settings
└── README.md         # This file
\`\`\`

## Setup

1. Clone this repository
2. Ensure pyenv is installed
3. The virtual environment will auto-activate when entering the project directory

## Development

This project uses:
- UV for fast package management
- Black for code formatting
- Flake8 for linting
- MyPy for type checking
- Pre-commit hooks for automated checks

To install dependencies:
\`\`\`bash
uv pip install -e .
\`\`\`

To install development dependencies:
\`\`\`bash
uv pip install -e ".[dev]"
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
    
    # Check if the virtualenv already exists
    if pyenv virtualenvs | grep -q "$venv_name"; then
        print_message "$YELLOW" "Virtual environment '$venv_name' already exists."
        
        # Generate a new environment name with random string
        local random_string=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
        local new_venv_name="env-${random_string}"
        
        print_message "$YELLOW" "Creating a new environment with name: $new_venv_name"
        venv_name=$new_venv_name
        recreate_venv=true
    else
        recreate_venv=true
    fi
    
    # Create virtual environment if needed
    if $recreate_venv; then
        print_message "$YELLOW" "Creating virtual environment '$venv_name' with Python $python_version..."
        pyenv virtualenv "$python_version" "$venv_name"
    fi
    
    # Create project directory if it doesn't exist
    mkdir -p "$project_dir"
    
    # Set the local Python version for the project directory
    cd "$project_dir" || exit
    pyenv local "$venv_name"
    
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

def test_sample():
    """Sample test function."""
    assert True
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
    
    # Install packages with UV
    install_packages "$venv_name" "$requirements_file" "$recreate_venv" "$python_version"
    
    # Set up flake8 configuration
    create_flake8_config
    
    # Set up mypy configuration
    create_mypy_config "$python_version"
    
    # Set up pre-commit hooks
    create_precommit_config
    
    # Initialize pre-commit
    print_message "$YELLOW" "Setting up pre-commit hooks..."
    # Make sure we're using the pre-commit from the virtual environment
    if command -v pyenv &> /dev/null; then
        eval "$(pyenv init -)"
        pyenv shell "$venv_name"
        if [ -f "$(pyenv which pre-commit)" ]; then
            # Ensure there's at least one commit before initializing pre-commit hooks
            if ! git rev-parse --verify HEAD &> /dev/null; then
                print_message "$YELLOW" "Creating initial commit for pre-commit hooks..."
                git add .
                git commit -m "Initial commit" --no-verify
            fi
            "$(pyenv which pre-commit)" install
            print_message "$GREEN" "Pre-commit hooks installed successfully!"
        else
            print_message "$YELLOW" "Warning: pre-commit executable not found in virtual environment."
            print_message "$YELLOW" "You may need to manually run: 'pre-commit install' after setup."
        fi
        # Reset shell
        pyenv shell --unset
    else
        print_message "$YELLOW" "Warning: Unable to initialize pre-commit hooks automatically."
        print_message "$YELLOW" "You may need to manually run: 'pre-commit install' after setup."
    fi
    
    # Create a README.md if it doesn't exist
    if [ ! -f README.md ]; then
        create_readme "$python_version" "$venv_name"
    fi
    
    print_message "$GREEN" "Virtual environment created and configured successfully!"
    print_message "$BLUE" "The environment will auto-activate when you enter $project_dir"
}

# Set default values
DEFAULT_PYTHON_VERSION="3.12"
DEFAULT_PROJECT_DIR="$(pwd)"

# Parse command line options
PYTHON_VERSION=$DEFAULT_PYTHON_VERSION
PROJECT_DIR=$DEFAULT_PROJECT_DIR
VENV_NAME=""
REQUIREMENTS_FILE=""

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
    print_message "$BLUE" "Virtual environment name: $VENV_NAME"
else
    print_message "$BLUE" "Virtual environment name will be derived from project directory"
fi
if [ -n "$REQUIREMENTS_FILE" ]; then
    print_message "$BLUE" "Requirements file: $REQUIREMENTS_FILE"
fi

# Install UV globally
install_uv

# Create pyenv environment
create_pyenv_venv "$PYTHON_VERSION" "$PROJECT_DIR" "$VENV_NAME" "$REQUIREMENTS_FILE"

# Final message
print_message "$GREEN" "Setup complete! Your Python environment is ready."
cd "$PROJECT_DIR" # Ensure we're in the project directory
print_message "$BLUE" "Currently in: $(pwd) with $(python --version)"
print_message "$BLUE" "Package manager: UV $(uv --version)"
print_message "$YELLOW" "Project structure created:"
find . -type d -maxdepth 1 | sort | grep -v "^\.$" | sed 's/\.\///'