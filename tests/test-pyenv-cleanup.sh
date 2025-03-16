#!/usr/bin/env zsh

# Script: test-pyenv-cleanup.sh
# Description: Test suite for pyenv-cleanup.sh

# Don't exit on errors, we need to run all tests
set +e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory for correct relative paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLEANUP_SCRIPT="${SCRIPT_DIR}/../pyenv-cleanup.sh"

# Use a unique prefix to avoid conflict with other environments
TEST_ENV_PREFIX="test-env-"
OTHER_TEST_ENV="other-test-env"

# Test environment names
TEST_ENVS=("${TEST_ENV_PREFIX}1" "${TEST_ENV_PREFIX}2" "${TEST_ENV_PREFIX}3" "${TEST_ENV_PREFIX}4" "${TEST_ENV_PREFIX}5")

# Python version to use for creating environments
PYTHON_VERSION="3.12"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create test environments
create_test_environments() {
    print_message "$BLUE" "Creating test environments..."
    
    # Create test environments with the TEST_ENV_PREFIX
    for env in "${TEST_ENVS[@]}"; do
        print_message "$BLUE" "Creating ${env}..."
        if pyenv virtualenvs --bare | grep -q "^${env}$"; then
            print_message "$YELLOW" "Environment ${env} already exists. Skipping."
        else
            pyenv virtualenv $PYTHON_VERSION "${env}" || {
                print_message "$YELLOW" "Failed to create ${env}, but will continue..."
            }
        fi
    done
    
    # Create an additional environment with a different prefix
    print_message "$BLUE" "Creating ${OTHER_TEST_ENV}..."
    if pyenv virtualenvs --bare | grep -q "^${OTHER_TEST_ENV}$"; then
        print_message "$YELLOW" "Environment ${OTHER_TEST_ENV} already exists. Skipping."
    else
        pyenv virtualenv $PYTHON_VERSION "${OTHER_TEST_ENV}" || {
            print_message "$YELLOW" "Failed to create ${OTHER_TEST_ENV}, but will continue..."
        }
    fi
    
    print_message "$GREEN" "Test environments created successfully!"
}

# Function to list current test environments
list_test_environments() {
    local envs=($(pyenv virtualenvs --bare | grep -v "/" | sort))
    
    echo "Current test environments:"
    for env in "${envs[@]}"; do
        echo "$env"
    done
}

# Function to check if an environment exists
environment_exists() {
    local env_name=$1
    pyenv virtualenvs --bare | grep -q "^${env_name}$"
    return $?
}

# Function to count environments with a specific prefix
count_environments_with_prefix() {
    local prefix=$1
    local count=$(pyenv virtualenvs --bare | grep "^${prefix}" | grep -v "/" | wc -l | tr -d '[:space:]')
    echo "$count"
}

# Function to cleanup test environments
cleanup_test_environments() {
    print_message "$BLUE" "Cleaning up any remaining test environments..."
    
    print_message "$YELLOW" "Environments before cleanup:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}" || echo "None"
    
    # Remove environments with the test prefix
    print_message "$BLUE" "Removing environments with prefix '${TEST_ENV_PREFIX}'..."
    local test_envs=($(pyenv virtualenvs --bare | grep "^${TEST_ENV_PREFIX}" | grep -v "/"))
    for env in "${test_envs[@]}"; do
        print_message "$BLUE" "Removing ${env}..."
        pyenv uninstall -f "${env}" 2>/dev/null
    done
    
    # Remove the other test environment
    if environment_exists "${OTHER_TEST_ENV}"; then
        print_message "$BLUE" "Removing '${OTHER_TEST_ENV}'..."
        pyenv uninstall -f "${OTHER_TEST_ENV}" 2>/dev/null
    fi
    
    print_message "$YELLOW" "Environments after cleanup:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}" || echo "None"
    
    print_message "$GREEN" "Cleanup complete!"
}

# Function to list environments with a specific prefix
list_environments_with_prefix() {
    local prefix=$1
    local envs=($(pyenv virtualenvs --bare | grep "^${prefix}" | grep -v "/"))
    
    if [ ${#envs[@]} -eq 0 ]; then
        return 1
    fi
    
    for env in "${envs[@]}"; do
        echo "$env"
    done
    
    return 0
}

# Test 1: List functionality
test_list_functionality() {
    print_message "$BLUE" "=== RUNNING TEST 1: LIST FUNCTIONALITY ==="
    print_message "$YELLOW" "Testing list functionality..."
    
    # Create test environments
    create_test_environments
    list_test_environments
    
    # Expected number of test environments (excluding the other-test-env)
    local expected_count=${#TEST_ENVS[@]}
    echo "Expected test environments: $expected_count"
    
    # Run the list command and capture output
    local list_output=$($CLEANUP_SCRIPT --list | grep "${TEST_ENV_PREFIX}" | grep -v "Found" | grep -v "Listing")
    echo "List output contents:"
    echo "$list_output"
    
    # Count how many of our test environments are in the list output
    local found_count=$(echo "$list_output" | grep -c "${TEST_ENV_PREFIX}")
    echo "Found in list output: $found_count"
    
    if [ "$found_count" -eq "$expected_count" ]; then
        print_message "$GREEN" "✓ List function shows test environments"
        print_message "$GREEN" "✓ Test 1 PASSED"
        return 0
    else
        print_message "$RED" "✗ List function failed to show all test environments"
        print_message "$RED" "  Expected $expected_count, found $found_count"
        print_message "$RED" "✗ Test 1 FAILED"
        return 1
    fi
}

# Test 2: Single environment removal
test_single_environment_removal() {
    print_message "$BLUE" "=== RUNNING TEST 2: SINGLE ENVIRONMENT REMOVAL ==="
    print_message "$YELLOW" "Testing single environment removal..."
    
    # Create test environments
    create_test_environments
    list_test_environments
    
    # Check environments before removal
    echo "Current environments before removal:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}"
    
    # Test removing a single environment (the first one)
    local env_to_remove="${TEST_ENV_PREFIX}1"
    local env_to_keep="${TEST_ENV_PREFIX}2"
    
    echo "Running: $CLEANUP_SCRIPT --name \"${env_to_remove}\" --force"
    $CLEANUP_SCRIPT --name "${env_to_remove}" --force
    
    # Check environments after removal
    echo "Current environments after removal:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}"
    
    # Verify that the correct environment was removed
    if ! environment_exists "${env_to_remove}"; then
        print_message "$GREEN" "✓ Successfully removed ${env_to_remove}"
        
        if environment_exists "${env_to_keep}"; then
            print_message "$GREEN" "✓ ${env_to_keep} still exists (as expected)"
            print_message "$GREEN" "✓ Test 2 PASSED"
            return 0
        else
            print_message "$RED" "✗ ${env_to_keep} was unexpectedly removed"
            print_message "$RED" "✗ Test 2 FAILED"
            return 1
        fi
    else
        print_message "$RED" "✗ Failed to remove ${env_to_remove}"
        print_message "$RED" "✗ Test 2 FAILED"
        return 1
    fi
}

# Test 3: Prefix-based environment removal
test_prefix_based_removal() {
    print_message "$BLUE" "=== RUNNING TEST 3: PREFIX-BASED REMOVAL ==="
    print_message "$YELLOW" "Testing prefix-based environment removal..."
    
    # Create test environments
    create_test_environments
    list_test_environments
    
    # Count environments with the test prefix before removal
    local before_count=$(count_environments_with_prefix "${TEST_ENV_PREFIX}")
    echo "Found $before_count environments with prefix '${TEST_ENV_PREFIX}'"
    
    # Check environments before removal
    echo "Current environments before removal:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}"
    
    # Test removing environments with the test prefix using force flag
    echo "Running: $CLEANUP_SCRIPT --prefix \"${TEST_ENV_PREFIX}\" --force"
    $CLEANUP_SCRIPT --prefix "${TEST_ENV_PREFIX}" --force
    
    # Count environments with the test prefix after removal
    local after_count=$(count_environments_with_prefix "${TEST_ENV_PREFIX}")
    echo "After removal: $after_count environments with prefix '${TEST_ENV_PREFIX}'"
    
    # Check environments after removal
    echo "Current environments after removal:"
    list_environments_with_prefix "${TEST_ENV_PREFIX}" || echo "None"
    
    # Verify that all environments with the test prefix were removed
    if [ "$after_count" -eq 0 ]; then
        print_message "$GREEN" "✓ Successfully removed all environments with prefix '${TEST_ENV_PREFIX}'"
        print_message "$GREEN" "✓ Test 3 PASSED"
        return 0
    else
        print_message "$RED" "✗ Failed to remove all environments with prefix '${TEST_ENV_PREFIX}'"
        print_message "$RED" "  $after_count environments still remain"
        print_message "$RED" "✗ Test 3 FAILED"
        return 1
    fi
}

# Test 4: All environments removal
test_all_removal() {
    print_message "$BLUE" "=== RUNNING TEST 4: ALL ENVIRONMENTS REMOVAL ==="
    print_message "$YELLOW" "Testing removal of all test environments..."
    
    # Create test environments
    create_test_environments
    list_test_environments
    
    # Count test environments before removal
    local before_count=$(count_environments_with_prefix "${TEST_ENV_PREFIX}")
    echo "Found $before_count test environments before removal"
    
    # Check if the other test environment exists before removal
    if environment_exists "${OTHER_TEST_ENV}"; then
        echo "${OTHER_TEST_ENV} exists: yes"
    else
        echo "${OTHER_TEST_ENV} exists: no"
    fi
    
    # Try removing with prefix first to simulate a common cleanup path
    echo "Running: $CLEANUP_SCRIPT --prefix \"${TEST_ENV_PREFIX}\" --force"
    $CLEANUP_SCRIPT --prefix "${TEST_ENV_PREFIX}" --force
    
    # Count test environments after removal
    local after_count=$(count_environments_with_prefix "${TEST_ENV_PREFIX}")
    echo "After removal: $after_count test environments remain"
    
    # Verify that all test environments were removed
    if [ "$after_count" -eq 0 ]; then
        print_message "$GREEN" "✓ Successfully removed all test environments"
        print_message "$GREEN" "✓ Test 4 PASSED"
        return 0
    else
        print_message "$RED" "✗ Failed to remove all test environments"
        print_message "$RED" "  $after_count environments still remain"
        print_message "$RED" "✗ Test 4 FAILED"
        return 1
    fi
}

# Main test execution
cleanup_test_environments

# Run tests
test_list_functionality
test1_result=$?

test_single_environment_removal
test2_result=$?

test_prefix_based_removal
test3_result=$?

test_all_removal
test4_result=$?

# Clean up after tests
cleanup_test_environments

# Print test summary
passed=0
failed=0

if [ $test1_result -eq 0 ]; then ((passed++)); else ((failed++)); fi
if [ $test2_result -eq 0 ]; then ((passed++)); else ((failed++)); fi
if [ $test3_result -eq 0 ]; then ((passed++)); else ((failed++)); fi
if [ $test4_result -eq 0 ]; then ((passed++)); else ((failed++)); fi

echo "Test Summary:"
echo "Tests passed: $passed"
echo "Tests failed: $failed"

# Exit with failure if any test failed
if [ $failed -gt 0 ]; then
    exit 1
else
    exit 0
fi 