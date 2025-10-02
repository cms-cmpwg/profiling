#!/bin/bash -x
# Common utility functions for CMS profiling scripts
# This library provides shared functionality to avoid code duplication

# Set strict error handling
set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${LOG_FILE:-${SCRIPT_DIR}/profiling.log}"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#==============================================================================
# Logging Functions
#==============================================================================

log() {
    echo -e "${TIMESTAMP} [INFO] $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${TIMESTAMP} [${RED}ERROR${NC}] $*" | tee -a "${LOG_FILE}" >&2
}

log_warn() {
    echo -e "${TIMESTAMP} [${YELLOW}WARN${NC}] $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${TIMESTAMP} [${GREEN}SUCCESS${NC}] $*" | tee -a "${LOG_FILE}"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${TIMESTAMP} [${BLUE}DEBUG${NC}] $*" | tee -a "${LOG_FILE}"
    fi
}

#==============================================================================
# Error Handling Functions
#==============================================================================

# Generic error handler
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Script failed at line ${line_number} with exit code ${exit_code}"
    log_error "Command: ${BASH_COMMAND}"
    cleanup_on_exit
    exit ${exit_code}
}

# Set up error trapping
setup_error_handling() {
    trap 'handle_error ${LINENO}' ERR
    trap 'cleanup_on_exit' EXIT
}

# Cleanup function (override in calling script if needed)
cleanup_on_exit() {
    log_debug "Cleanup function called"
}

#==============================================================================
# Validation Functions
#==============================================================================

# Validate required environment variables
validate_env_vars() {
    local vars=("$@")
    local missing_vars=()
    
    for var in "${vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("${var}")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    return 0
}

# Validate that a command exists
validate_command() {
    local cmd=$1
    if ! command -v "${cmd}" &> /dev/null; then
        log_error "Required command '${cmd}' not found in PATH"
        return 1
    fi
    return 0
}

# Validate directory exists and is accessible
validate_directory() {
    local dir=$1
    if [[ ! -d "${dir}" ]]; then
        log_error "Directory '${dir}' does not exist or is not accessible"
        return 1
    fi
    return 0
}

# Validate file exists and is readable
validate_file() {
    local file=$1
    if [[ ! -f "${file}" || ! -r "${file}" ]]; then
        log_error "File '${file}' does not exist or is not readable"
        return 1
    fi
    return 0
}

#==============================================================================
# CMSSW Environment Functions
#==============================================================================

# Set up CMSSW version with validation
setup_cmssw_version() {
    if [[ "X${CMSSW_VERSION:-}" == "X" ]]; then
        CMSSW_VERSION=${1:-}
        if [[ -z "${CMSSW_VERSION}" ]]; then
            log_error "CMSSW_VERSION not provided and not set in environment"
            return 1
        fi
    fi
    
    log "Using CMSSW version: ${CMSSW_VERSION}"
    export CMSSW_VERSION
}

# Set up SCRAM architecture
setup_scram_arch() {
    if [[ "X${ARCHITECTURE:-}" != "X" ]]; then
        export SCRAM_ARCH="${ARCHITECTURE}"
    fi
    
    log "Using SCRAM_ARCH: ${SCRAM_ARCH:-default}"
}

# Set up profiling workflow with validation
setup_profiling_workflow() {
    local default_workflow=${1:-"13034.21"}
    
    if [[ "X${PROFILING_WORKFLOW:-}" == "X" ]]; then
        export PROFILING_WORKFLOW="${default_workflow}"
    fi
    
    log "Using profiling workflow: ${PROFILING_WORKFLOW}"
}

# Set up workspace directory
setup_workspace() {
    local cmssw_version=${1:-${CMSSW_VERSION}}
    
    if [[ "X${WORKSPACE:-}" != "X" ]]; then
        local target_dir="${WORKSPACE}/${cmssw_version}/${PROFILING_WORKFLOW}"
        if validate_directory "${target_dir}"; then
            cd "${target_dir}" || {
                log_error "Failed to change to workspace directory: ${target_dir}"
                return 1
            }
            log "Changed to workspace directory: ${target_dir}"
        else
            return 1
        fi
    else
        setup_cvmfs_environment "${cmssw_version}"
    fi
}

# Set up CVMFS environment (for non-Jenkins runs)
setup_cvmfs_environment() {
    local cmssw_version=$1
    
    export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
    log "Setting up CVMFS environment: ${VO_CMS_SW_DIR}"
    
    # shellcheck source=/dev/null
    source "${VO_CMS_SW_DIR}/cmsset_default.sh" || {
        log_error "Failed to source CMSSW default setup"
        return 1
    }
    
    local target_dir="${cmssw_version}/${PROFILING_WORKFLOW}"
    if validate_directory "${target_dir}"; then
        cd "${target_dir}" || {
            log_error "Failed to change to directory: ${target_dir}"
            return 1
        }
    else
        log_error "Target directory not found: ${target_dir}"
        return 1
    fi
    
    # Set up runtime environment
    eval "$(scram runtime -sh)" || {
        log_error "Failed to set up SCRAM runtime environment"
        return 1
    }
    
    setup_ibeos_cache
}

# Set up ibeos cache
setup_ibeos_cache() {
    if [[ ! -f "${LOCALRT}/ibeos_cache.txt" ]]; then
        log "Downloading ibeos cache..."
        curl -L -s "${LOCALRT}/ibeos_cache.txt" https://raw.githubusercontent.com/cms-sw/cms-sw.github.io/master/das_queries/ibeos.txt || {
            log_warn "Failed to download ibeos cache, continuing without it"
        }
    fi
    
    # Set up ibeos paths
    for base_dir in "${CMSSW_RELEASE_BASE}" "${CMSSW_BASE}"; do
        local ibeos_path="${base_dir}/src/Utilities/General/ibeos"
        if [[ -d "${ibeos_path}" ]]; then
            export PATH="${ibeos_path}:${PATH}"
            export CMS_PATH=/cvmfs/cms-ib.cern.ch
            export CMSSW_USE_IBEOS=true
            log "Added ibeos to PATH: ${ibeos_path}"
        fi
    done
}

# Set up common environment variables
setup_common_env() {
    export LC_ALL=C
    
    if [[ "X${TIMEOUT:-}" == "X" ]]; then
        export TIMEOUT=43200
    fi
    
    log "Set LC_ALL=C and TIMEOUT=${TIMEOUT}"
}

#==============================================================================
# Profiling Tool Functions
#==============================================================================

# Execute a profiling step with error handling
run_profiling_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=${4:-}
    local profiling_cmd=${5:-"cmsRun"}
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with ${profiling_cmd}"
        
        local cmd="${profiling_cmd} ${config_file}"
        if [[ -n "${job_report}" ]]; then
            cmd+=" -j ${job_report}"
        fi
        cmd+=" >& ${log_file}"
        
        eval "${cmd}" || {
            log_error "Failed to run ${step_name}"
            return 1
        }
        
        log_success "Completed ${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

# Rename files with a common pattern
rename_profiling_files() {
    local wildcard=$1
    local pattern=$2
    local prefix=$3
    local files_found=0

    for file in $( ls ${wildcard} 2>/dev/null ); do
        if [[ -f "${file}" ]]; then
            local new_name="${file/${pattern}/${prefix}_${pattern}}"
            mv "${file}" "${new_name}"
            log "Renamed ${file} to ${new_name}"
            ((files_found++))
        fi
    done
    
    if [[ ${files_found} -eq 0 ]]; then
        log_warn "No files found matching pattern: ${pattern}"
    fi
    
    return 0
}

#==============================================================================
# Utility Functions
#==============================================================================

# Check if running in Jenkins environment
is_jenkins() {
    [[ "X${WORKSPACE:-}" != "X" ]]
}

# Print script header
print_header() {
    local script_name=$1
    local description=${2:-"CMS Profiling Script"}
    
    log "=============================================="
    log "${description}"
    log "Script: ${script_name}"
    log "Started at: ${TIMESTAMP}"
    log "Working directory: $(pwd)"
    log "=============================================="
}

# Print script footer
print_footer() {
    local exit_code=${1:-0}
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    log "=============================================="
    if [[ ${exit_code} -eq 0 ]]; then
        log_success "Script completed successfully"
    else
        log_error "Script completed with errors (exit code: ${exit_code})"
    fi
    log "Finished at: ${end_time}"
    log "=============================================="
}

# Execute command with timeout and logging
execute_with_timeout() {
    local timeout_duration=${1:-${TIMEOUT}}
    local description=$2
    shift 2
    local cmd=("$@")
    
    log "Executing (timeout ${timeout_duration}s): ${description}"
    log_debug "Command: ${cmd[*]}"
    
    if timeout "${timeout_duration}" "${cmd[@]}"; then
        log_success "Command completed: ${description}"
        return 0
    else
        local exit_code=$?
        if [[ ${exit_code} -eq 124 ]]; then
            log_error "Command timed out after ${timeout_duration}s: ${description}"
        else
            log_error "Command failed with exit code ${exit_code}: ${description}"
        fi
        return ${exit_code}
    fi
}
