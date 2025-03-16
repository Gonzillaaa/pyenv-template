# Python Environment Setup Script

A comprehensive ZSH script for setting up Python development environments with pyenv, UV package manager, virtual environments, and development tools.

- [Python Environment Setup Script](#python-environment-setup-script)
  - [Overview](#overview)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Basic Usage](#basic-usage)
    - [Advanced Usage](#advanced-usage)
    - [Examples](#examples)
  - [Project Structure](#project-structure)
  - [Configuration Files](#configuration-files)
    - [.env](#env)
    - [.flake8](#flake8)
    - [mypy.ini](#mypyini)
    - [.pre-commit-config.yaml](#pre-commit-configyaml)
  - [Development Tools](#development-tools)
    - [Code Formatting](#code-formatting)
    - [Linting](#linting)
    - [Type Checking](#type-checking)
    - [Testing](#testing)
    - [Pre-commit Hooks](#pre-commit-hooks)
  - [Design Decisions](#design-decisions)
  - [Use Cases](#use-cases)
  - [Potential Expansions](#potential-expansions)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

## Overview

This script automates the setup of Python development environments using pyenv for Python version management and virtual environments for project isolation. It configures a comprehensive set of development tools including code formatters, linters, type checkers, and testing frameworks, all enforced through pre-commit hooks for consistent code quality.

## Features

- **Python Version Management**: Uses pyenv to install and manage multiple Python versions
- **Fast Package Management**: Integrates UV for significantly faster package installation and dependency resolution
- **Virtual Environment Creation**: Automatically creates and configures virtual environments
  - If a virtual environment with the specified name already exists, automatically creates a new one with the prefix `env-` followed by a random string
- **Auto-activation**: Sets up automatic activation/deactivation when entering/leaving the project directory
- **Project Structure**: Creates a standardized project structure with src, tests, docs, and scripts directories
- **Development Tools**:
  - Black for code formatting
  - Flake8 for linting
  - MyPy for static type checking
  - Pylint for additional code analysis
  - Pytest for testing
- **Git Integration**:
  - Configures pre-commit hooks for automated code quality checks
  - Sets up a comprehensive .gitignore file
- **Environment Configuration**:
  - Creates a template .env file for environment variables
  - Configures development tools with sensible defaults
  - Sets up pyproject.toml with UV configuration

## Prerequisites

- ZSH shell
- Git

The script will automatically install:

- pyenv
- pyenv-virtualenv plugin
- Required Python development tools

## Installation

1. Download the script:

   ```bash
   curl -o pyenv-setup.sh https://raw.githubusercontent.com/yourusername/pyenv-setup/main/pyenv-setup.sh
   ```

2. Make it executable:

   ```bash
   chmod +x pyenv-setup.sh
   ```

3. Move it to a directory in your PATH (optional):
   ```bash
   mv pyenv-setup.sh /usr/local/bin/pyenv-setup
   ```

## Usage

### Basic Usage

```bash
./pyenv-setup.sh
```

This will set up Python 3.12 in the current directory.

### Advanced Usage

```bash
./pyenv-setup.sh [options] [python_version] [project_directory] [venv_name] [requirements_file]
```

Options:

- `-h, --help`: Show help message and exit

Arguments:

- `python_version` (optional): The Python version to use (default: 3.12)
- `project_directory` (optional): The path to the project directory (default: current directory)
- `venv_name` (optional): Custom name for the virtual environment
- `requirements_file` (optional): Path to a requirements.txt file

### Examples

1. Create a new project using defaults (Python 3.12 in current directory):

   ```bash
   ./pyenv-setup.sh
   ```

2. Create a new project with a specific Python version:

   ```bash
   ./pyenv-setup.sh 3.11
   ```

3. Create a new project with Python 3.10 in a specific directory:

   ```bash
   ./pyenv-setup.sh 3.10 ~/projects/my_new_project
   ```

4. Create a project with a custom virtual environment name:

   ```bash
   ./pyenv-setup.sh 3.9 ~/projects/my_project custom_venv_name
   ```

   Note: If a virtual environment named `custom_venv_name` already exists, a new one will be created with the name pattern `env-{random_string}`.

5. Create a project in current directory with a specific Python version and custom venv name:

   ```bash
   ./pyenv-setup.sh 3.8 . my_special_env
   ```

6. Create a project and install packages from requirements.txt:

   ```bash
   ./pyenv-setup.sh 3.11 ~/projects/my_project my_project_env ~/requirements.txt
   ```

7. Working with existing environments:

   ```bash
   # If an environment with this name already exists
   ./pyenv-setup.sh -v 3.11 -d ~/projects/another_project -n existing_env_name

   # The script will automatically create a new environment with a name like:
   # env-a1b2c3d4
   ```

## Project Structure

The script creates the following project structure:

```
project_directory/
├── docs/             # Documentation files
├── scripts/          # Utility scripts
├── src/              # Source code
│   └── __init__.py
├── tests/            # Test files
│   └── __init__.py
├── .env              # Environment variables
├── .flake8           # Flake8 configuration
├── .gitignore        # Git ignore rules (includes .uv/ directory)
├── .pre-commit-config.yaml  # Pre-commit hooks configuration
├── mypy.ini          # MyPy configuration
└── README.md         # Project README
```

## Configuration Files

### .env

The script creates a sample .env file with common environment variables:

```
# Development Settings
DEBUG=True
LOG_LEVEL=DEBUG

# Application Settings
APP_NAME=project_name
APP_ENV=development
APP_SECRET=replace_this_with_a_real_secret_key

# Database Settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=project_name_db
DB_USER=postgres
DB_PASSWORD=postgres

# API Settings
API_URL=http://localhost:8000
API_VERSION=v1
API_TIMEOUT=30

# Paths
DATA_DIR=./data
LOGS_DIR=./logs
```

### pyproject.toml

The script creates a pyproject.toml file that configures the project and UV:

```toml
[build-system]
requires = ["setuptools>=42", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "project_name"
version = "0.1.0"
description = "project_name project"
readme = "README.md"
requires-python = ">=3.9"
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

[tool.uv]
python = "3.9.7"

[tool.black]
line-length = 100
target-version = ["py39"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"
```

### .flake8

Configuration for the Flake8 linter:

```
[flake8]
max-line-length = 100
exclude = .git,__pycache__,docs/source/conf.py,old,build,dist,.venv
ignore = E203, W503
per-file-ignores =
    __init__.py: F401
```

- `max-line-length = 100`: Allows lines up to 100 characters
- `exclude`: Directories to exclude from linting
- `ignore`: Error codes to ignore
  - `E203`: Whitespace before ':' (conflicts with Black)
  - `W503`: Line break before binary operator (conflicts with Black)
- `per-file-ignores`: Ignores unused imports in `__init__.py` files

### mypy.ini

Configuration for MyPy type checking:

```
[mypy]
python_version = 3.x
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
```

- `python_version`: Set to the Python version being used
- `disallow_untyped_defs = True`: Requires type annotations for all functions
- `strict_optional = True`: Enables strict handling of Optional types
- Special configurations for numpy and pytest modules

### .pre-commit-config.yaml

Configuration for pre-commit hooks:

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        args: [--line-length=100]

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        additional_dependencies: [flake8-docstrings]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        exclude: ^tests/
        additional_dependencies: [types-requests, types-PyYAML]
```

This sets up the following pre-commit hooks:

- Basic file checks (trailing whitespace, YAML validation, etc.)
- Black for code formatting
- Flake8 for linting (with docstring checking)
- MyPy for type checking

## Development Tools

### Package Management

**UV** is a significantly faster alternative to pip for Python package management:

Benefits:

- Drastically faster package installations (10-100x faster than pip)
- Reliable dependency resolution
- Consistent lockfiles for reproducible environments
- Better caching for faster repeated operations
- Parallel downloads and installations
- Virtual environment management capabilities

Configuration is done through pyproject.toml with the `[tool.uv]` section.

### Code Formatting

**Black** is configured with a line length of 100 characters for code formatting. Black is an opinionated formatter that reformats your code in a consistent, predictable manner with minimal configuration options.

Benefits:

- Eliminates debates about formatting
- Integrates with pre-commit for automatic formatting on commit
- Consistent code style throughout the project

### Linting

**Flake8** is configured to enforce PEP 8 style guidelines with some exceptions to accommodate Black's formatting choices. It includes:

- Basic PEP 8 style checks
- Python syntax errors detection
- Complexity checking
- Docstring checking (via flake8-docstrings)

### Type Checking

**MyPy** is configured with strict type checking to catch potential type-related errors:

- Requires type annotations for all functions
- Warns about returning `Any` types
- Checks for proper use of optional types
- Includes specific configurations for common libraries

### Testing

**Pytest** is installed as the testing framework, allowing for:

- Simple, readable test functions
- Powerful fixtures for test setup
- Rich plugin ecosystem
- Detailed test reports

### Pre-commit Hooks

Pre-commit hooks run automatically before each commit to ensure code quality:

- Prevents committing code that doesn't meet quality standards
- Automatically formats code with Black
- Runs linting and type checking
- Checks for sensitive information and common issues

## Design Decisions

1. **Why make Python version and project directory optional?**

   - Reduces friction when starting new projects
   - Provides sensible defaults (Python 3.12, current directory)
   - Makes the script more convenient for common use cases
   - Still allows full customization when needed

2. **Why pyenv?**

   - Provides isolation between Python versions
   - Enables easy switching between Python versions per project
   - Simplifies management of multiple Python environments

3. **Why UV?**

   - Significantly faster package installations than pip
   - Better dependency resolution
   - Compatible with modern Python packaging standards
   - Seamless integration with virtual environments
   - Strong caching for improved development workflow

4. **Why the standard directory structure?**

   - Follows Python packaging best practices
   - Separates source code, tests, and documentation
   - Makes the project more maintainable and navigable

5. **Why include pre-commit hooks?**

   - Enforces code quality standards automatically
   - Catches issues before they enter the codebase
   - Standardizes code formatting across all contributors

6. **Why extensive configuration files?**

   - Provides sensible defaults for development tools
   - Ensures consistency across the development environment
   - Reduces friction for new developers joining the project

7. **Why use src/ directory instead of a flat structure?**
   - Prevents import issues during development and testing
   - Follows modern Python packaging practices
   - Separates package code from project-level files
8. **Why pyproject.toml?**
   - Follows PEP 518/PEP 621 standards for Python project metadata
   - Central configuration location for multiple tools
   - Required for modern packaging and UV integration
   - Makes the project more maintainable

## Use Cases

1. **Starting a New Python Project**

   - Quickly bootstrap a new Python project with best practices already set up
   - Avoid spending time on repetitive environment setup
   - Enforce code quality from day one
   - Benefit from faster package installations with UV

2. **Standardizing Team Projects**

   - Ensure all team members use the same Python version and tools
   - Maintain consistent code quality across the team
   - Simplify onboarding for new team members

3. **Education and Training**

   - Set up standardized environments for Python workshops
   - Introduce best practices to students or junior developers
   - Demonstrate proper Python project structure

4. **Open Source Projects**

   - Create a welcoming environment for contributors
   - Enforce consistent code style across contributions
   - Reduce maintainer burden for style-related issues

5. **Microservices Development**

   - Quickly create and configure multiple Python services
   - Maintain consistency across different microservices
   - Simplify environment setup for new services
   - Accelerate development with faster dependency installations

6. **High-Performance Development Teams**
   - Reduce time spent waiting for package installations
   - Improve developer experience with faster tooling
   - Standardize on modern Python packaging practices
   - Streamline onboarding with consistent environments

## Potential Expansions

1. **Docker Integration**

   - Add options to generate a Dockerfile
   - Include docker-compose configuration for development
   - Support containerized development environments

2. **Framework-Specific Templates**

   - Add support for Flask/Django/FastAPI project templates
   - Include framework-specific configurations
   - Set up common framework dependencies

3. **CI/CD Configuration**

   - Generate GitHub Actions or GitLab CI configurations
   - Set up automated testing and deployment pipelines
   - Configure code coverage reporting

4. **Documentation Generation**

   - Add Sphinx documentation setup
   - Configure automatic API documentation generation
   - Set up Read the Docs integration

5. **Enhanced UV Integration**

   - Add support for UV lockfiles
   - Include UV sync commands for dependencies
   - Add UV configuration templates for different project types
   - Implement advanced UV caching strategies

6. **Alternative Dependency Management**

   - Add Poetry support as an alternative
   - Include options for different dependency management tools
   - Generate requirements-dev.txt for development dependencies

7. **Project Templates**

   - Allow selection from multiple project templates
   - Support custom template repositories
   - Add template customization options

8. **Interactive Mode**

   - Add a fully interactive setup process
   - Allow selecting features and configurations
   - Provide a guided experience for new users

9. **Plugin System**
   - Create a plugin architecture for custom extensions
   - Allow community-contributed configurations
   - Support organization-specific setups

## Troubleshooting

**Issue**: pyenv installation fails

- Solution: Check system dependencies required by pyenv (see pyenv documentation)
- Alternative: Install pyenv manually before running the script

**Issue**: UV installation fails

- Solution: Ensure Rust toolchain is available (UV is written in Rust)
- Alternative: Install UV manually using `curl -LsSf https://astral.sh/uv/install.sh | sh`

**Issue**: Virtual environment has a different name than expected

- Explanation: If a virtual environment with the specified name already exists, the script automatically creates a new one with the pattern `env-{random_string}`
- Solution: Use the environment name shown in the output or check the .python-version file in your project directory
- Note: This is by design to avoid conflicts with existing environments

**Issue**: Pre-commit hooks installation fails

- Solution: Ensure the project directory is a git repository
- Alternative: Run `git init` before running the script
- Manual fix: After script completion, run `pre-commit install` from within the project directory

**Issue**: TOML parsing error in the pyproject.toml file

- Solution: This has been fixed in the latest version of the script
- Alternative: Remove or update the problematic configuration in the pyproject.toml file

**Issue**: Python version installation fails

- Solution: Check internet connectivity and try again
- Alternative: Install the Python version manually with `pyenv install <version>`

**Issue**: Script fails with permission errors

- Solution: Ensure the script has execute permissions (`chmod +x pyenv-setup.sh`)
- Alternative: Run with explicit interpreter (`zsh pyenv-setup.sh ...`)

**Issue**: Virtual environment activation doesn't work

- Solution: Ensure pyenv-virtualenv is properly installed
- Alternative: Add the activation commands to your `.zshrc` manually

**Issue**: UV shows "command not found" despite installation

- Solution: Restart your shell or source your `.zshrc` file
- Alternative: Add `~/.cargo/bin` to your PATH manually

## Contributing

Contributions to improve the script are welcome! Please feel free to submit issues or pull requests for:

- Bug fixes
- Feature additions
- Documentation improvements
- Use case examples

## License

This script is released under the MIT License. See the LICENSE file for details.
