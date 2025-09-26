#!/bin/bash
#
# Improved CMS Profiling Cron Job
# Enhanced with error handling, logging, and notifications
#

# Set strict error handling
set -euo pipefail

# Configuration
readonly WORKDIR="/home/users/gartung"
readonly EOSWWWDIR="/eos/user/g/gartung/www"
readonly LOG_FILE="${WORKDIR}/profiling-cron.log"
readonly LOCK_FILE="${WORKDIR}/.profiling-cron.lock"
readonly MAX_LOCK_AGE=7200  # 2 hours in seconds

# Email configuration (set these environment variables if email notifications are desired)
readonly EMAIL_TO="${PROFILING_EMAIL_TO:-}"
readonly EMAIL_SUBJECT="CMS Profiling Cron Job"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" | tee -a "${LOG_FILE}" >&2
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*" | tee -a "${LOG_FILE}"
}

# Send email notification if configured
send_notification() {
    local subject_suffix="$1"
    local message="$2"
    
    if [[ -n "${EMAIL_TO}" ]] && command -v mail &>/dev/null; then
        echo "${message}" | mail -s "${EMAIL_SUBJECT} - ${subject_suffix}" "${EMAIL_TO}"
        log "Email notification sent to ${EMAIL_TO}"
    fi
}

# Check and create lock file
acquire_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_age
        lock_age=$(( $(date +%s) - $(stat -c %Y "${LOCK_FILE}" 2>/dev/null || echo 0) ))
        
        if [[ ${lock_age} -lt ${MAX_LOCK_AGE} ]]; then
            log_error "Another profiling job is already running (lock age: ${lock_age}s)"
            exit 1
        else
            log "Removing stale lock file (age: ${lock_age}s)"
            rm -f "${LOCK_FILE}"
        fi
    fi
    
    echo $$ > "${LOCK_FILE}"
    log "Lock acquired: ${LOCK_FILE}"
}

# Remove lock file
release_lock() {
    rm -f "${LOCK_FILE}"
    log "Lock released"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "Cleanup started (exit code: ${exit_code})"
    
    release_lock
    
    # Clean up temporary files
    find "${WORKDIR}" -name "*.root" -mtime +1 -delete 2>/dev/null || true
    
    if [[ ${exit_code} -ne 0 ]]; then
        send_notification "FAILED" "Profiling cron job failed with exit code ${exit_code}. Check ${LOG_FILE} for details."
    fi
    
    log "Cleanup completed"
    exit ${exit_code}
}

# Set up cleanup trap
trap cleanup EXIT

# Main execution
main() {
    log "Starting CMS profiling cron job"
    
    # Acquire lock
    acquire_lock
    
    # Source CMSSW environment
    if [[ -f /cvmfs/cms.cern.ch/cmsset_default.sh ]]; then
        # shellcheck source=/dev/null
        source /cvmfs/cms.cern.ch/cmsset_default.sh
    else
        log_error "CMSSW environment not found"
        exit 1
    fi
    
    # Read last processed nightly build
    local last_nightly=""
    if [[ -f "${WORKDIR}/last-nightly" ]]; then
        last_nightly=$(cat "${WORKDIR}/last-nightly" 2>/dev/null || echo "")
    fi
    log "Last processed nightly: ${last_nightly:-none}"
    
    # Get latest nightly build
    local latest_nightly
    latest_nightly=$(scram list CMSSW_1 | grep CMSSW_ | sort | tail -1 | awk '{print $2}' 2>/dev/null || echo "")
    
    if [[ -z "${latest_nightly}" ]]; then
        log_error "Failed to get latest nightly build"
        exit 1
    fi
    
    log "Latest nightly build: ${latest_nightly}"
    
    # Check if we need to process a new build
    if [[ "${last_nightly}" == "${latest_nightly}" ]]; then
        log "No new nightly build to process"
        exit 0
    fi
    
    log "Processing new nightly build: ${latest_nightly}"
    
    # Change to working directory
    cd "${WORKDIR}" || {
        log_error "Failed to change to working directory: ${WORKDIR}"
        exit 1
    }
    
    # Run profiling workflow generation
    if [[ -x "${WORKDIR}/ServiceWork/Gen_tool/workflow_generator.sh" ]]; then
        log "Running workflow generator (refactored version)"
        "${WORKDIR}/ServiceWork/Gen_tool/workflow_generator.sh" "${latest_nightly}" || {
            log_error "Workflow generation failed"
            exit 1
        }
    else
        log "Running legacy workflow generator"
        "${WORKDIR}/ServiceWork/Gen_tool/Gen.sh" "${latest_nightly}" || {
            log_error "Legacy workflow generation failed"
            exit 1
        }
    fi
    
    # Run memory profiling
    log "Running memory profiling"
    "${WORKDIR}/ServiceWork/Gen_tool/runall_mem.sh" "${latest_nightly}" || {
        log_error "Memory profiling failed"
        exit 1
    }
    
    # Run CPU profiling
    log "Running CPU profiling"
    "${WORKDIR}/ServiceWork/Gen_tool/runall_cpu.sh" "${latest_nightly}" || {
        log_error "CPU profiling failed"
        exit 1
    }
    
    # Run TimeMemory profiling if available
    local timememory_dir="${WORKDIR}/${latest_nightly}/src/TimeMemory"
    if [[ -d "${timememory_dir}" && -x "${timememory_dir}/profile.sh" ]]; then
        log "Running TimeMemory profiling"
        cd "${timememory_dir}" || {
            log_error "Failed to change to TimeMemory directory"
            exit 1
        }
        
        ./profile.sh || {
            log_error "TimeMemory profiling failed"
            exit 1
        }
        
        cd "${WORKDIR}" || {
            log_error "Failed to return to working directory"
            exit 1
        }
    else
        log "TimeMemory profiling not available"
    fi
    
    # Update last processed nightly
    echo "${latest_nightly}" > "${WORKDIR}/last-nightly" || {
        log_error "Failed to update last-nightly file"
        exit 1
    }
    
    # Copy results to web directory
    local results_dir="${EOSWWWDIR}/results/${latest_nightly}"
    log "Copying results to ${results_dir}"
    
    mkdir -p "${results_dir}" || {
        log_error "Failed to create results directory: ${results_dir}"
        exit 1
    }
    
    # Copy .res files
    local timememory_results="${WORKDIR}/${latest_nightly}/src/TimeMemory"
    if [[ -d "${timememory_results}" ]]; then
        find "${timememory_results}" -name "*.res" -exec cp -pv {} "${results_dir}/" \; || {
            log_error "Failed to copy .res files"
            exit 1
        }
        
        # Copy .sql3 files to CGI data directory
        mkdir -p "${EOSWWWDIR}/cgi-bin/data" || {
            log_error "Failed to create CGI data directory"
            exit 1
        }
        
        find "${timememory_results}" -name "*.sql3" -exec cp -pv {} "${EOSWWWDIR}/cgi-bin/data/" \; || {
            log_error "Failed to copy .sql3 files"
            exit 1
        }
    else
        log_error "TimeMemory results directory not found: ${timememory_results}"
        exit 1
    fi
    
    log_success "Profiling completed successfully for ${latest_nightly}"
    send_notification "SUCCESS" "Profiling completed successfully for ${latest_nightly}"
}

# Run main function
main "$@"
