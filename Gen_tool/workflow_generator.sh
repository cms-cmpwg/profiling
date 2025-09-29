#!/bin/bash -x
#
# Refactored CMSSW Workflow Generator
# Generates CMSSW profiling configurations with better error handling and modularity
#
# This script replaces Gen.sh with improved structure and error handling
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

readonly DEFAULT_WORKFLOW="29834.21"
readonly DEFAULT_NTHREADS=1
readonly MATRIX_WHAT_FLAGS='-w cleanedupgrade,standard,highstats,pileup,generator,extendedgen,production,identity,ged,machine,premix,nano,gpu,2017,2026'

# Command file names
readonly CMD_FILES=(
    "cmd_ft.sh"     # FastTimer
    "cmd_ig.sh"     # IgProf  
    "cmd_ts.sh"     # TimeMemory
    "cmd_je.sh"     # JeProf
    "cmd_am.sh"     # AllocMonitor
)

#==============================================================================
# Environment Setup Functions  
#==============================================================================

setup_cmssw_environment() {
    local cmssw_version=$1
    
    log "Setting up CMSSW environment for version: ${cmssw_version}"
    
    if [[ "X${RELEASE_FORMAT:-}" == "X" && "X${CMSSW_IB:-}" == "X" && "X${ARCHITECTURE:-}" == "X" ]]; then
        # Local installation mode
        setup_local_cmssw "${cmssw_version}"
    else
        # Jenkins/Workspace mode
        setup_workspace_cmssw "${cmssw_version}"
    fi
}

setup_local_cmssw() {
    local cmssw_version=$1
    
    export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
    # shellcheck source=/dev/null
    source "${VO_CMS_SW_DIR}/cmsset_default.sh" || {
        log_error "Failed to source CMSSW default setup"
        return 1
    }
    
    log "Installing CMSSW ${cmssw_version}..."
    if ! validate_command "voms-proxy-init"; then
        log_warn "voms-proxy-init not available, continuing without proxy"
    else
        voms-proxy-init || log_warn "Failed to initialize VOMS proxy"
    fi
    
    scram project "${cmssw_version}" || {
        log_error "Failed to create SCRAM project for ${cmssw_version}"
        return 1
    }
    
    cd "${cmssw_version}" || {
        log_error "Failed to enter CMSSW directory"
        return 1
    }
    
    eval "$(scram runtime -sh)" || {
        log_error "Failed to set up SCRAM runtime"
        return 1
    }
    
    log_success "CMSSW environment set up successfully"
}

setup_workspace_cmssw() {
    local cmssw_version=$1
    
    if [[ ! -d "${WORKSPACE}/${cmssw_version}" ]]; then
        log_error "CMSSW workspace directory not found: ${WORKSPACE}/${cmssw_version}"
        return 1
    fi
    
    cd "${WORKSPACE}/${cmssw_version}" || {
        log_error "Failed to enter workspace CMSSW directory"
        return 1
    }
    
    log "Using existing CMSSW workspace: ${WORKSPACE}/${cmssw_version}"
}

setup_workflow_parameters() {
    # Set up workflow parameters with validation
    if [[ "X${PROFILING_WORKFLOW:-}" == "X" ]]; then
        export PROFILING_WORKFLOW="${DEFAULT_WORKFLOW}"
    fi
    
    if [[ "X${NTHREADS:-}" == "X" ]]; then
        export NTHREADS="${DEFAULT_NTHREADS}"
    fi
    
    if [[ "X${EVENTS:-}" == "X" ]]; then
        export EVENTS=$((NTHREADS * 10))
    fi
    
    log "Workflow parameters:"
    log "  PROFILING_WORKFLOW: ${PROFILING_WORKFLOW}"
    log "  NTHREADS: ${NTHREADS}"
    log "  EVENTS: ${EVENTS}"
}

#==============================================================================
# Workflow Generation Functions
#==============================================================================

validate_workflow() {
    local workflow=$1
    
    log "Validating workflow: ${workflow}"
    
    # Check if workflow exists in matrix
    if runTheMatrix.py -n | grep -q "^${workflow}" 2>/dev/null; then
        log "Workflow found in default matrix"
        return 0
    
    # Check with extended flags
    elif runTheMatrix.py -n ${MATRIX_WHAT_FLAGS} | grep -q "^${workflow}"; then
        log "Workflow found in extended matrix"
        return 0
    fi

    log_error "Workflow ${workflow} not found in matrix"
    return 1
}

generate_workflow_configs() {
    local workflow=$1
    
    log "Generating workflow configurations for: ${workflow}"
    
    # Determine command based on environment
    local matrix_cmd="runTheMatrix.py"
    local matrix_args=()
    
    if [[ "X${WORKSPACE:-}" != "X" ]]; then
        # Jenkins mode
        matrix_args+=(${MATRIX_WHAT_FLAGS} -l "${workflow}" --ibeos)
        matrix_args+=(--command="--number=${EVENTS} --nThreads=${NTHREADS} --no_exec")
    else
        # Local mode
        local ncpu
        ncpu=$(grep -c processor /proc/cpuinfo)
        local local_nthreads=$((ncpu / 2))
        local local_events=$((local_nthreads * 10))
        
        matrix_args+=(${MATRIX_WHAT_FLAGS} -l "${workflow}" --ibeos)
        matrix_args+=(--command="--number=${local_events} --nThreads=${local_nthreads} --no_exec")
    fi
    
    log "Running matrix command: ${matrix_cmd} ${matrix_args[*]}"
    
    execute_with_timeout 300 "runTheMatrix workflow generation" \
        "${matrix_cmd}" "${matrix_args[@]}" || {
        log_error "Failed to generate workflow configurations"
    }
    
    setup_workflow_directory "${workflow}"
}

setup_workflow_directory() {
    local workflow=$1
    
    # Find the generated directory
    local generated_dirs
    mapfile -t generated_dirs < <(find . -maxdepth 1 -name "${workflow}_*" -type d 2>/dev/null)
    
    if [[ ${#generated_dirs[@]} -eq 0 ]]; then
        log_error "No workflow directory generated for ${workflow}"
        return 1
    fi
    
    local outdir="${generated_dirs[0]}"
    log "Found generated directory: ${outdir}"
    
    # Handle existing workflow directory
    if [[ -d "${workflow}" ]]; then
        local backup_dir="${workflow}.old"
        log "Backing up existing workflow directory to ${backup_dir}"
        rm -rf "${backup_dir}" 2>/dev/null || true
        mv "${workflow}" "${backup_dir}"
    fi
    
    # Move generated directory to standard name
    mv "${outdir}" "${workflow}" || {
        log_error "Failed to rename workflow directory"
        return 1
    }
    
    cd "${workflow}" || {
        log_error "Failed to enter workflow directory"
        return 1
    }
    
    log_success "Workflow directory setup complete: $(pwd)"
}

#==============================================================================
# Command Generation Functions
#==============================================================================

extract_workflow_steps() {
    local steps_file="cmdLog"
    
    if ! validate_file "${steps_file}"; then
        log_error "Workflow steps file not found: ${steps_file}"
        return 1
    fi
    
    log "Extracting workflow steps from ${steps_file}"
    
    # Extract cmsDriver commands and store in array
    mapfile -t workflow_steps < <(grep cmsDriver.py "${steps_file}" | cut -d'>' -f1)
    
    if [[ ${#workflow_steps[@]} -eq 0 ]]; then
        log_error "No workflow steps found in ${steps_file}"
        return 1
    fi
    
    log "Found ${#workflow_steps[@]} workflow steps:"
    for i in "${!workflow_steps[@]}"; do
        log "  Step $((i+1)): ${workflow_steps[i]}"
    done
    
    export workflow_steps
}

generate_command_files() {
    log "Generating command files"
    
    # Initialize command files
    for cmd_file in "${CMD_FILES[@]}"; do
        echo "#!/bin/bash" > "${cmd_file}"
        chmod +x "${cmd_file}"
        log "Initialized ${cmd_file}"
    done
    
    # Check if this is a reHLT workflow
    local is_rehlt_workflow=false
    if [[ "${workflow_dir}" =~ 136\. ]] || [[ "${workflow_dir}" =~ 141\. ]]; then
        is_rehlt_workflow=true
        log "Detected reHLT workflow, adjusting step numbering"
    fi
    
    # Generate commands for each step
    for step_idx in "${!workflow_steps[@]}"; do
        local step_cmd="${workflow_steps[step_idx]}"
        local step_number
        
        if [[ "${is_rehlt_workflow}" == "true" ]]; then
            step_number=$((step_idx + 2))
        else
            step_number=$((step_idx + 1))
        fi
        
        generate_step_commands "${step_cmd}" "${step_number}"
    done
    
    # Add special handling for step2 in non-reHLT workflows
    if [[ "${is_rehlt_workflow}" == "false" ]]; then
        add_step2_modifications
    fi
    
    # Generate FastTimer commands
    generate_fasttimer_commands "${is_rehlt_workflow}"
    
    log_success "All command files generated successfully"
}

generate_step_commands() {
    local base_cmd=$1
    local step_num=$2
    
    log_debug "Generating commands for step ${step_num}"
    
    # TimeMemory command
    {
        echo "${base_cmd} --customise=Validation/Performance/TimeMemorySummary.py"
        echo "  --python_filename=step${step_num}_timememoryinfo.py"
    } >> cmd_ts.sh
    
    # IgProf command  
    {
        echo "${base_cmd} --customise Validation/Performance/IgProfInfo.customise"
        echo "  --customise_commands \"$(get_output_customizations);"
        echo "  process.options.numberOfThreads = 1;"
        echo "  process.add_(cms.Service('ZombieKillerService', secondsBetweenChecks = cms.untracked.uint32(10), numberOfAllowedFailedChecksInARow = cms.untracked.uint32(6)))\""
        echo "  --python_filename=step${step_num}_igprof.py"
    } >> cmd_ig.sh
    
    # JeProf command
    {
        echo "${base_cmd} --customise Validation/Performance/JeProfInfo.customise"
        echo "  --customise_commands \"$(get_output_customizations);"
        echo "  process.options.numberOfThreads = 1\""
        echo "  --python_filename=step${step_num}_jeprof.py"
    } >> cmd_je.sh
}

get_output_customizations() {
    cat << 'EOF'
process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands)
EOF
}

add_step2_modifications() {
    log "Adding step2 modifications for EOS access"
    
    for cmd_file in cmd_ts.sh cmd_ig.sh cmd_je.sh; do
        echo "perl -p -i -e 's!/store/relval!root://eoscms.cern.ch//store/user/cmsbuild/store/relval!g' step2_*.py" >> "${cmd_file}"
    done
}

generate_fasttimer_commands() {
    local is_rehlt_workflow=$1
    
    log "Generating FastTimer commands"
    
    local step_offset=1
    if [[ "${is_rehlt_workflow}" == "true" ]]; then
        step_offset=2
    fi
    
    for step_idx in "${!workflow_steps[@]}"; do
        local step_cmd="${workflow_steps[step_idx]}"
        local step_num=$((step_idx + step_offset))
        
        {
            echo "${step_cmd}"
            echo "  --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob"
            echo "  --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);"
            echo "  process.FastTimerService.jsonFileName = cms.untracked.string('step${step_num}_cpu.resources.json');"
            echo "  process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);"
            echo "  process.options.numberOfConcurrentLuminosityBlocks = 1\""
            echo "  --python_filename=step${step_num}_fasttimer.py"
        } >> cmd_ft.sh
        
        # Add AllocMonitor command
        {
            echo "${step_cmd}"
            echo "  --customise PerfTools/AllocMonitor/ModuleAllocMonitor.customise"
            echo "  --customise_commands \"process.options.numberOfThreads = 1\""
            echo "  --python_filename=step${step_num}_allocmon.py"
        } >> cmd_am.sh
    done
    
    # Add EOS modifications for step2 in FastTimer and AllocMonitor
    if [[ "${is_rehlt_workflow}" == "false" ]]; then
        for cmd_file in cmd_ft.sh cmd_am.sh; do
            echo "perl -p -i -e 's!/store/relval!root://eoscms.cern.ch//store/user/cmsbuild/store/relval!g' step2_*.py" >> "${cmd_file}"
        done
    fi
}

#==============================================================================
# Main Function
#==============================================================================

main() {
    local cmssw_version=${1:-${CMSSW_VERSION}}
    
    print_header "${BASH_SOURCE[0]}" "CMSSW Workflow Generator (Refactored)"
    
    # Validate inputs
    if [[ -z "${cmssw_version}" ]]; then
        log_error "CMSSW version must be provided either as argument or CMSSW_VERSION environment variable"
        exit 1
    fi
    
    # Setup environment
    setup_cmssw_version "${cmssw_version}" || exit 1
    setup_scram_arch
    setup_workflow_parameters
    
    # Validate required commands
    local required_commands=("runTheMatrix.py" "scram" "grep" "cut")
    for cmd in "${required_commands[@]}"; do
        validate_command "${cmd}" || exit 1
    done
    
    # Setup CMSSW environment
    setup_cmssw_environment "${CMSSW_VERSION}" || exit 1
    
    # Validate and generate workflow
    validate_workflow "${PROFILING_WORKFLOW}" || exit 1
    generate_workflow_configs "${PROFILING_WORKFLOW}" || exit 1
    
    # Extract steps and generate command files
    extract_workflow_steps || exit 1
    generate_command_files || exit 1
    
    log_success "Workflow generation completed successfully"
    log "Generated command files:"
    for cmd_file in "${CMD_FILES[@]}"; do
        if [[ -f "${cmd_file}" ]]; then
            log "  ✓ ${cmd_file} ($(wc -l < "${cmd_file}") lines)"
        else
            log_warn "  ✗ ${cmd_file} (not generated)"
        fi
    done
    
    print_footer 0
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    log_debug "Cleaning up workflow generator"
    return ${exit_code}
}

# Parse command line arguments and run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi