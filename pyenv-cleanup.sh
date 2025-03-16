#!/usr/bin/env zsh

# Script: pyenv-cleanup.sh
# Description: Lists and removes pyenv virtual environments

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

# Function to check if pyenv and pyenv-virtualenv are installed
check_pyenv() {
    if ! command -v pyenv &> /dev/null; then
        print_message "$RED" "Error: pyenv is not installed. Please install pyenv first."
        exit 1
    fi

    if [ ! -d "$(pyenv root)/plugins/pyenv-virtualenv" ]; then
        print_message "$RED" "Error: pyenv-virtualenv is not installed. Please install it first."
        exit 1
    fi
}

# Function to list all pyenv virtualenvs
list_virtualenvs() {
    print_message "$BLUE" "Listing all pyenv virtual environments:"
    
    # Get all virtualenvs, filter out Python version references
    local virtualenvs=($(pyenv virtualenvs --bare | sort))
    
    if [ ${#virtualenvs[@]} -eq 0 ]; then
        print_message "$YELLOW" "No virtual environments found."
        return 1
    fi
    
    # Filter out Python version directory references
    local real_venvs=()
    for venv in "${virtualenvs[@]}"; do
        # Skip entries with slashes which are references to the Python version
        if [[ "$venv" != *"/"* ]]; then
            real_venvs+=("$venv")
        fi
    done

    if [ ${#real_venvs[@]} -eq 0 ]; then
        print_message "$YELLOW" "No virtual environments found."
        return 1
    fi
    
    local count=1
    print_message "$BLUE" "Found ${#real_venvs[@]} virtual environments:"
    for venv in "${real_venvs[@]}"; do
        echo "$count) $venv"
        ((count++))
    done
    
    return 0
}

# Function to show help message
show_help() {
    echo "Usage: ./pyenv-cleanup.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message and exit"
    echo "  -l, --list            List all pyenv virtual environments"
    echo "  -a, --all             Remove all pyenv virtual environments"
    echo "  -p, --prefix PREFIX   Remove all environments starting with PREFIX"
    echo "  -n, --name NAME       Remove the specific environment NAME"
    echo "  -i, --interactive     Interactive mode for selecting environments to remove"
    echo "  -f, --force           Skip confirmation prompts (use with caution)"
    echo ""
    echo "Examples:"
    echo "  ./pyenv-cleanup.sh --list                # List all virtual environments"
    echo "  ./pyenv-cleanup.sh --all                 # Remove all virtual environments"
    echo "  ./pyenv-cleanup.sh --prefix env-         # Remove all environments starting with 'env-'"
    echo "  ./pyenv-cleanup.sh --name my_project_env # Remove the specific environment 'my_project_env'"
    echo "  ./pyenv-cleanup.sh --interactive         # Select environments to remove interactively"
    echo "  ./pyenv-cleanup.sh --prefix env- --force # Remove all environments starting with 'env-' without confirmation"
    echo ""
    echo "Note: Use with caution as removing virtual environments cannot be undone."
}

# Function to remove a single environment
remove_virtualenv() {
    local venv=$1
    
    print_message "$YELLOW" "Removing virtual environment: $venv"
    pyenv uninstall -f "$venv" || {
        print_message "$RED" "Error: Failed to remove virtual environment: $venv"
        return 1
    }
    print_message "$GREEN" "Successfully removed virtual environment: $venv"
    return 0
}

# Function to remove all virtualenvs
remove_all_virtualenvs() {
    local force=$1
    
    # Get all virtualenvs, filter out Python version references
    local virtualenvs=()
    
    # We need to properly read all lines without losing any due to word splitting
    while IFS= read -r venv; do
        # Skip entries with slashes which are references to the Python version
        if [[ "$venv" != *"/"* ]]; then
            virtualenvs+=("$venv")
        fi
    done < <(pyenv virtualenvs --bare | sort)
    
    if [ ${#virtualenvs[@]} -eq 0 ]; then
        print_message "$YELLOW" "No virtual environments found to remove."
        return 0
    fi
    
    print_message "$YELLOW" "Removing all ${#virtualenvs[@]} virtual environments..."
    
    # If not forced, ask for confirmation
    if [ "$force" != "true" ]; then
        print_message "$YELLOW" "WARNING: This will remove ALL pyenv virtual environments."
        echo -n "Are you sure you want to continue? [y/N] "
        read confirm
        if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
            print_message "$BLUE" "Operation cancelled."
            return 0
        fi
    fi
    
    # Create a temporary script to remove all environments
    local temp_script=$(mktemp)
    echo "#!/bin/zsh" > "$temp_script"
    echo "set -e" >> "$temp_script"
    
    # Add commands to remove each environment
    for venv in "${virtualenvs[@]}"; do
        echo "echo \"Removing virtual environment: $venv\"" >> "$temp_script"
        echo "pyenv uninstall -f \"$venv\"" >> "$temp_script"
        echo "echo \"Successfully removed virtual environment: $venv\"" >> "$temp_script"
    done
    
    # Make the script executable
    chmod +x "$temp_script"
    
    # Execute the script
    "$temp_script"
    local script_status=$?
    
    # Clean up the temporary script
    rm -f "$temp_script"
    
    if [ $script_status -eq 0 ]; then
        print_message "$GREEN" "Successfully removed ${#virtualenvs[@]} virtual environments."
    else
        print_message "$RED" "Failed to remove some virtual environments."
        
        # Verify all environments were removed
        local remaining=$(pyenv virtualenvs --bare | grep -v "/" | wc -l | tr -d '[:space:]')
        if [ "$remaining" -gt 0 ]; then
            print_message "$YELLOW" "Warning: $remaining environments still remain."
            print_message "$YELLOW" "They may require manual removal."
        fi
    fi
    
    return $script_status
}

# Function to remove virtualenvs with a specific prefix
remove_virtualenvs_by_prefix() {
    local prefix=$1
    local force=$2
    
    # Get all virtualenvs with the specified prefix
    local venvs_to_remove=()
    while IFS= read -r venv; do
        # Skip entries with slashes which are references to the Python version
        if [[ "$venv" == "$prefix"* && "$venv" != *"/"* ]]; then
            venvs_to_remove+=("$venv")
        fi
    done < <(pyenv virtualenvs --bare | sort)
    
    if [ ${#venvs_to_remove[@]} -eq 0 ]; then
        print_message "$YELLOW" "No virtual environments found with prefix: $prefix"
        return 0
    fi
    
    print_message "$YELLOW" "Found ${#venvs_to_remove[@]} virtual environments with prefix '$prefix':"
    for venv in "${venvs_to_remove[@]}"; do
        echo "- $venv"
    done
    
    # If not forced, ask for confirmation
    if [ "$force" != "true" ]; then
        # Fix for zsh: Use echo and read without -p
        echo -n "Are you sure you want to remove these environments? [y/N] "
        read confirm
        if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
            print_message "$BLUE" "Operation cancelled."
            return 0
        fi
    fi
    
    # Create a temporary script to remove all environments
    local temp_script=$(mktemp)
    echo "#!/bin/zsh" > "$temp_script"
    echo "set -e" >> "$temp_script"
    
    # Add commands to remove each environment
    for venv in "${venvs_to_remove[@]}"; do
        echo "echo \"Removing virtual environment: $venv\"" >> "$temp_script"
        echo "pyenv uninstall -f \"$venv\"" >> "$temp_script"
        echo "echo \"Successfully removed virtual environment: $venv\"" >> "$temp_script"
    done
    
    # Make the script executable
    chmod +x "$temp_script"
    
    # Execute the script
    "$temp_script"
    local script_status=$?
    
    # Clean up the temporary script
    rm -f "$temp_script"
    
    if [ $script_status -eq 0 ]; then
        print_message "$GREEN" "Successfully removed ${#venvs_to_remove[@]} virtual environments."
    else
        print_message "$RED" "Failed to remove some virtual environments."
        
        # Verify all environments were removed
        local remaining=$(pyenv virtualenvs --bare | grep "^$prefix" | grep -v "/" | wc -l | tr -d '[:space:]')
        if [ "$remaining" -gt 0 ]; then
            print_message "$YELLOW" "Warning: $remaining environments with prefix '$prefix' still remain."
            print_message "$YELLOW" "They may require manual removal."
        fi
    fi
    
    return $script_status
}

# Function for interactive selection of environments to remove
interactive_remove() {
    local force=$1
    
    local virtualenvs=()
    
    # We need to properly read all lines without losing any due to word splitting
    while IFS= read -r venv; do
        # Skip entries with slashes which are references to the Python version
        if [[ "$venv" != *"/"* ]]; then
            virtualenvs+=("$venv")
        fi
    done < <(pyenv virtualenvs --bare | sort)
    
    if [ ${#virtualenvs[@]} -eq 0 ]; then
        print_message "$YELLOW" "No virtual environments found."
        return 0
    fi
    
    print_message "$BLUE" "Select virtual environments to remove:"
    print_message "$YELLOW" "Enter numbers separated by spaces (e.g., '1 3 5') or 'all' for all environments."
    print_message "$YELLOW" "Enter 'q' to quit without removing any environments."
    
    local count=1
    for venv in "${virtualenvs[@]}"; do
        echo "$count) $venv"
        ((count++))
    done
    
    # Fix for zsh
    echo -n "Selection: "
    read selection
    
    if [[ "$selection" == "q" ]]; then
        print_message "$BLUE" "Operation cancelled."
        return 0
    fi
    
    local venvs_to_remove=()
    
    if [[ "$selection" == "all" ]]; then
        venvs_to_remove=("${virtualenvs[@]}")
    else
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ] && [ "$num" -le ${#virtualenvs[@]} ]; then
                venvs_to_remove+=("${virtualenvs[$num-1]}")
            else
                print_message "$RED" "Invalid selection: $num. Skipping."
            fi
        done
    fi
    
    if [ ${#venvs_to_remove[@]} -eq 0 ]; then
        print_message "$YELLOW" "No valid selections. No environments will be removed."
        return 0
    fi
    
    print_message "$YELLOW" "The following virtual environments will be removed:"
    for venv in "${venvs_to_remove[@]}"; do
        echo "- $venv"
    done
    
    # If not forced, ask for confirmation
    if [ "$force" != "true" ]; then
        # Fix for zsh
        echo -n "Are you sure you want to remove these environments? [y/N] "
        read confirm
        if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
            print_message "$BLUE" "Operation cancelled."
            return 0
        fi
    fi
    
    # Create a temporary script to remove all environments
    local temp_script=$(mktemp)
    echo "#!/bin/zsh" > "$temp_script"
    echo "set -e" >> "$temp_script"
    
    # Add commands to remove each environment
    for venv in "${venvs_to_remove[@]}"; do
        echo "echo \"Removing virtual environment: $venv\"" >> "$temp_script"
        echo "pyenv uninstall -f \"$venv\"" >> "$temp_script"
        echo "echo \"Successfully removed virtual environment: $venv\"" >> "$temp_script"
    done
    
    # Make the script executable
    chmod +x "$temp_script"
    
    # Execute the script
    "$temp_script"
    local script_status=$?
    
    # Clean up the temporary script
    rm -f "$temp_script"
    
    if [ $script_status -eq 0 ]; then
        print_message "$GREEN" "Successfully removed ${#venvs_to_remove[@]} virtual environments."
    else
        print_message "$RED" "Failed to remove some virtual environments."
    fi
    
    return $script_status
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# First check if pyenv and pyenv-virtualenv are installed
check_pyenv

# Check if force flag is provided
force="false"
for arg in "$@"; do
    if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
        force="true"
        break
    fi
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_virtualenvs
            exit 0
            ;;
        -a|--all)
            remove_all_virtualenvs "$force"
            exit 0
            ;;
        -p|--prefix)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: --prefix requires a PREFIX argument."
                exit 1
            fi
            remove_virtualenvs_by_prefix "$2" "$force"
            shift 2
            exit 0
            ;;
        -n|--name)
            if [[ -z "$2" || "$2" == -* ]]; then
                print_message "$RED" "Error: --name requires a NAME argument."
                exit 1
            fi
            if pyenv virtualenvs --bare | grep -q "^$2$"; then
                if [ "$force" != "true" ]; then
                    echo -n "Are you sure you want to remove the environment '$2'? [y/N] "
                    read confirm
                    if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
                        print_message "$BLUE" "Operation cancelled."
                        exit 0
                    fi
                fi
                remove_virtualenv "$2"
            else
                print_message "$RED" "Error: Virtual environment '$2' not found."
            fi
            shift 2
            exit 0
            ;;
        -i|--interactive)
            interactive_remove "$force"
            exit 0
            ;;
        -f|--force)
            # Already handled above
            shift
            ;;
        *)
            print_message "$RED" "Error: Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

exit 0 