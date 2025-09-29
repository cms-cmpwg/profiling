#!/bin/bash -x
#
# VTune Workflow Generator - Refactored
# Generates VTune profiling configurations for CMSSW workflows
#
# This script replaces Gen_vtune.sh with improved structure and error handling
#

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"

# Set up error handling
setup_error_handling

#==============================================================================
# Configuration
#==============================================================================

readonly DEFAULT_WORKFLOW="13034.21"
readonly DEFAULT_NTHREADS=1
readonly DEFAULT_EVENTS=10
readonly MATRIX_WHAT_FLAGS='-w upgrade,cleanedupgrade,standard,highstats,pileup,generator,extendedgen,production,identity,ged,machine,premix,nano,gpu,2017,2026'

# VTune paths and configuration
readonly VTUNE_PATHS=(
    "/cvmfs/projects.cern.ch/intelsw/oneAPI/linux/x86_64/2024/vtune/latest/vtune-vars.sh"
    "/opt/intel/oneapi/vtune/latest/vtune-vars.sh"
)

readonly VTUNE_COLLECT_OPTIONS=(
    "hotspots"
    "memory-consumption"
)

#==============================================================================
# VTune-Specific Functions
#==============================================================================

setup_vtune_environment() {
    log "Setting up VTune environment"
    
    local vtune_found=false
    for vtune_path in "${VTUNE_PATHS[@]}"; do
        if [[ -f "${vtune_path}" ]]; then
            log "Found VTune at: ${vtune_path}"
            # shellcheck source=/dev/null
            source "${vtune_path}" || {
                log_error "Failed to source VTune environment from: ${vtune_path}"
                continue
            }
            vtune_found=true
            break
        fi
    done
    
    if ! ${vtune_found}; then
        log_error "VTune environment not found in any of the expected paths:"
        for path in "${VTUNE_PATHS[@]}"; do
            log_error "  ${path}"
        done
        return 1
    fi
    
    # Validate VTune installation
    if ! validate_command "vtune"; then
        log_error "VTune command not available after sourcing environment"
        return 1
    fi
    
    # Get VTune version for logging
    local vtune_version
    vtune_version=$(vtune --version 2>/dev/null | head -1) || vtune_version="Unknown"
    log "VTune version: ${vtune_version}"
    
    log_success "VTune environment setup complete"
}

generate_vtune_analysis_script() {
    local script_name="vtune_analysis.sh"
    
    log "Generating VTune analysis script: ${script_name}"
    
    cat > "${script_name}" << 'EOF'
#!/bin/bash
#
# Generated VTune Analysis Script
# This script contains the VTune profiling commands for CMSSW workflow analysis
#

# Exit on error
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find cmsRun and vtune executables
CMSRUN=$(which cmsRun)
VTUNE=$(which vtune)

echo "Using cmsRun: ${CMSRUN}"
echo "Using VTune: ${VTUNE}"

# VTune collection options
VTUNE_HOTSPOT_OPTS="-collect hotspots -collect-with runss -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw"
VTUNE_MEMORY_OPTS="-collect memory-consumption"

# Function to run VTune profiling
run_vtune_profile() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local profile_type=${4:-hotspots}
    
    if [[ ! -f "${config_file}" ]]; then
        echo "Warning: Configuration file not found: ${config_file}"
        return 1
    fi
    
    echo "Running VTune ${profile_type} analysis for ${step_name}"
    echo "  Config: ${config_file}"
    echo "  Log: ${log_file}"
    
    if [[ "${profile_type}" == "hotspots" ]]; then
        ${VTUNE} ${VTUNE_HOTSPOT_OPTS} -- ${CMSRUN} "${config_file}" > "${log_file}" 2>&1
    elif [[ "${profile_type}" == "memory" ]]; then
        ${VTUNE} ${VTUNE_MEMORY_OPTS} -- ${CMSRUN} "${config_file}" > "${log_file}" 2>&1
    else
        echo "Error: Unknown profile type: ${profile_type}"
        return 1
    fi
    
    echo "Completed VTune analysis for ${step_name}"
}

# Function to generate VTune reports
generate_vtune_reports() {
    echo "Generating VTune reports"
    
    # Find all VTune result directories
    local result_dirs=(r???hs)
    
    for result_dir in "${result_dirs[@]}"; do
        if [[ -d "${result_dir}" ]]; then
            echo "Generating report for ${result_dir}"
            ${VTUNE} -report gprof-cc -r "${result_dir}" -format=csv -csv-delimiter=semicolon > "${result_dir}.gprof_cc.csv"
            gzip "${result_dir}.gprof_cc.csv"
            echo "Report generated: ${result_dir}.gprof_cc.csv.gz"
        fi
    done
}

# Main analysis execution
main() {
    echo "Starting VTune CMSSW workflow analysis"
    echo "Working directory: $(pwd)"
    
    # Run hotspots analysis for each step
    echo "=== Running hotspots analysis ==="
    
    # Step 1 (TTbar generation)
    if ls TTbar*.py >/dev/null 2>&1; then
        run_vtune_profile "step1" "$(ls TTbar*.py | head -1)" "step1.log" "hotspots"
    fi
    
    # Steps 2-5
    for step in 2 3 4 5; do
        if ls step${step}*.py >/dev/null 2>&1; then
            run_vtune_profile "step${step}" "$(ls step${step}*.py | head -1)" "step${step}.log" "hotspots"
        fi
    done
    
    # Run memory consumption analysis for reconstruction steps
    echo "=== Running memory analysis ==="
    
    for step in 3 4; do
        if ls step${step}*.py >/dev/null 2>&1; then
            run_vtune_profile "step${step}-mem" "$(ls step${step}*.py | head -1)" "step${step}-mem.log" "memory"
        fi
    done
    
    # Generate reports
    generate_vtune_reports
    
    echo "VTune analysis completed successfully"
}

# Run main function
main "$@"
EOF

    chmod +x "${script_name}"
    log_success "Generated VTune analysis script: ${script_name}"
}

setup_vtune_workflow_parameters() {
    # VTune-specific workflow parameters
    if [[ "X${PROFILING_WORKFLOW:-}" == "X" ]]; then
        export PROFILING_WORKFLOW="${DEFAULT_WORKFLOW}"
    fi
    
    if [[ "X${NTHREADS:-}" == "X" ]]; then
        export NTHREADS="${DEFAULT_NTHREADS}"
    fi
    
    if [[ "X${EVENTS:-}" == "X" ]]; then
        export EVENTS="${DEFAULT_EVENTS}"
    fi
    
    log "VTune Workflow parameters:"
    log "  PROFILING_WORKFLOW: ${PROFILING_WORKFLOW}"
    log "  NTHREADS: ${NTHREADS}"
    log "  EVENTS: ${EVENTS}"
}

validate_vtune_workflow() {
    local workflow=$1
    
    log "Validating VTune workflow: ${workflow}"
    
    # Check if workflow exists in matrix
    if runTheMatrix.py -n | grep -q "^${workflow}" 2>/dev/null; then
        log "VTune workflow found in default matrix"
        return 0

    # Check with extended flags
    elif runTheMatrix.py -n ${MATRIX_WHAT_FLAGS} | grep -q "^${workflow}"; then
        log "VTune workflow found in extended matrix"
        return 0
    fi

    log_error "VTune workflow ${workflow} not found in matrix"
    return 1
}

generate_vtune_workflow_configs() {
    local workflow=$1
    
    log "Generating VTune workflow configurations for: ${workflow}"
    
    # Determine command based on environment
    local matrix_cmd="runTheMatrix.py"
    local matrix_args=()
    
    if [[ "X${WORKSPACE:-}" != "X" ]]; then
        # Jenkins mode
        matrix_args+=(${MATRIX_WHAT_FLAGS} -l "${workflow}")
        matrix_args+=(--command="--number=${EVENTS} --nThreads=${NTHREADS} --no_exec")
    else
        # Local mode with dynamic CPU detection
        local ncpu
        ncpu=$(grep -c processor /proc/cpuinfo)
        local local_nthreads=$((ncpu / 2))
        local local_events=$((local_nthreads * 10))
        
        matrix_args+=(${MATRIX_WHAT_FLAGS} -l "${workflow}" --ibeos)
        matrix_args+=(--command="--number=${local_events} --nThreads=${local_nthreads} --no_exec")
    fi
    
    log "Running VTune matrix command: ${matrix_cmd} ${matrix_args[*]}"
    
    execute_with_timeout 300 "runTheMatrix VTune workflow generation" \
        "${matrix_cmd}" "${matrix_args[@]}" || {
        log_error "Failed to generate VTune workflow configurations"
    }
    
    setup_vtune_workflow_directory "${workflow}"
}

setup_vtune_workflow_directory() {
    local workflow=$1
    
    # Find the generated directory
    local generated_dirs
    mapfile -t generated_dirs < <(find . -maxdepth 1 -name "${workflow}*" -type d 2>/dev/null)
    
    if [[ ${#generated_dirs[@]} -eq 0 ]]; then
        log_error "No VTune workflow directory generated for ${workflow}"
        return 1
    fi
    
    local outdir="${generated_dirs[0]}"
    workflow_dir="${outdir}"
    log "Found VTune workflow directory: ${outdir}"
    
    # Handle existing workflow directory
    if [[ -d "${workflow}" ]]; then
        local backup_dir="${workflow}.1"
        log "Backing up existing VTune workflow directory to ${backup_dir}"
        rm -rf "${backup_dir}" 2>/dev/null || true
        mv "${workflow}" "${backup_dir}"
    fi
    
    # Move generated directory to standard name
    mv "${outdir}" "${workflow}" || {
        log_error "Failed to rename VTune workflow directory"
        return 1
    }
    
    cd "${workflow}" || {
        log_error "Failed to enter VTune workflow directory"
        return 1
    }
    
    log_success "VTune workflow directory setup complete: $(pwd)"
}

check_vtune_workflow_compatibility() {
    local workflow_dir=$1
    
    log "Checking VTune workflow compatibility"
    
    # VTune works with most workflows, but some specific configurations
    # might need special handling
    if [[ -f "cmdLog" ]]; then
        local num_steps
        num_steps=$(grep -c cmsDriver.py cmdLog)
        log "VTune workflow has ${num_steps} steps"
        
        if [[ ${num_steps} -eq 0 ]]; then
            log_error "No valid steps found in VTune workflow"
            return 1
        fi
    else
        log_warn "cmdLog not found, cannot verify VTune workflow steps"
    fi
    
    log_success "VTune workflow compatibility check passed"
}

#==============================================================================
# Main Function
#==============================================================================

main() {
    local cmssw_version=${1:-${CMSSW_VERSION}}
    
    print_header "${BASH_SOURCE[0]}" "VTune CMSSW Workflow Generator (Refactored)"
    
    # Validate inputs
    if [[ -z "${cmssw_version}" ]]; then
        log_error "CMSSW version must be provided either as argument or CMSSW_VERSION environment variable"
        exit 1
    fi
    
    # Setup environment
    setup_cmssw_version "${cmssw_version}" || exit 1
    setup_scram_arch
    setup_vtune_workflow_parameters
    
    # Validate required commands
    local required_commands=("runTheMatrix.py" "scram" "grep" "cut")
    for cmd in "${required_commands[@]}"; do
        validate_command "${cmd}" || exit 1
    done
    
    # Setup CMSSW environment
    setup_cmssw_environment "${CMSSW_VERSION}" || exit 1
    
    # Setup VTune environment
    setup_vtune_environment || {
        log_warn "VTune environment setup failed, generating analysis script only"
    }
    
    # Validate and generate VTune workflow
    validate_vtune_workflow "${PROFILING_WORKFLOW}" || exit 1
    generate_vtune_workflow_configs "${PROFILING_WORKFLOW}" || exit 1
    
    # Check workflow compatibility and generate analysis script
    check_vtune_workflow_compatibility "${workflow_dir}" || exit 1
    generate_vtune_analysis_script || exit 1
    
    log_success "VTune workflow generation completed successfully"
    
    log "Next steps for VTune analysis:"
    log "  1. Ensure VTune is available in your environment"
    log "  2. Run the generated analysis script: ./vtune_analysis.sh"
    log "  3. Review VTune results and generated reports"
    
    print_footer 0
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    log_debug "Cleaning up VTune workflow generator"
    return ${exit_code}
}

# Parse command line arguments and run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi