#!/bin/bash
#
# GPU Workflow Generator - Refactored
# Generates GPU-enabled CMSSW profiling configurations
#
# This script replaces Gen_gpu.sh with improved structure and error handling
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

readonly DEFAULT_WORKFLOW="11834.59621"
readonly DEFAULT_NTHREADS=2
readonly MATRIX_WHAT_FLAGS='-w cleanedupgrade,standard,highstats,pileup,generator,extendedgen,production,identity,ged,machine,premix,nano,gpu,2017,2026'

# GPU-specific command file names
readonly GPU_CMD_FILES=(
    "cmd_ft.sh"     # FastTimer
    "cmd_ig.sh"     # IgProf  
    "cmd_ts.sh"     # TimeMemory
    "cmd_np.sh"     # NVProf/NVIDIA Profiler
)

#==============================================================================
# GPU-Specific Functions
#==============================================================================

check_gpu_workflow_support() {
    local workflow_dir=$1
    
    # Check if workflow supports GPU modules
    if [[ "${workflow_dir}" =~ 136\. ]] || [[ "${workflow_dir}" =~ 141\. ]]; then
        log_warn "Workflow ${workflow_dir} has no GPU enabled modules"
        return 1
    fi
    
    log "Workflow ${workflow_dir} supports GPU modules"
    return 0
}

clean_workflow_steps() {
    local step_idx=$1
    local step_cmd="${workflow_steps[step_idx]}"
    
    # Clean up validation and DQM flags that interfere with GPU workflows
    local cleaned_cmd="${step_cmd}"
    cleaned_cmd="${cleaned_cmd/:@phase2Validation+@miniAODValidation,DQM:@phase2+@miniAODDQM/}"
    cleaned_cmd="${cleaned_cmd/,VALIDATION/}"
    cleaned_cmd="${cleaned_cmd/,DQMIO/}"
    cleaned_cmd="${cleaned_cmd/,DQM/}"
    
    workflow_steps[step_idx]="${cleaned_cmd}"
    log_debug "Cleaned step $((step_idx + 1)): ${workflow_steps[step_idx]}"
}

generate_gpu_command_files() {
    log "Generating GPU-specific command files"
    
    # Initialize command files
    for cmd_file in "${GPU_CMD_FILES[@]}"; do
        echo "#!/bin/bash" > "${cmd_file}"
        chmod +x "${cmd_file}"
        log "Initialized ${cmd_file}"
    done
    
    # Clean all workflow steps first
    for step_idx in "${!workflow_steps[@]}"; do
        clean_workflow_steps "${step_idx}"
    done
    
    # Check if workflow supports GPU
    if ! check_gpu_workflow_support "${workflow_dir}"; then
        log_warn "Skipping GPU command generation for unsupported workflow"
        return 0
    fi
    
    # Generate commands for each step
    for step_idx in "${!workflow_steps[@]}"; do
        local step_num=$((step_idx + 1))
        generate_gpu_step_commands "${workflow_steps[step_idx]}" "${step_num}"
    done
    
    # Generate FastTimer commands (different structure)
    generate_gpu_fasttimer_commands
    
    # Execute generated command files
    execute_gpu_command_files
    
    log_success "GPU command files generated and executed successfully"
}

generate_gpu_step_commands() {
    local base_cmd=$1
    local step_num=$2
    
    log_debug "Generating GPU commands for step ${step_num}"
    
    # TimeMemory command
    {
        echo "${base_cmd} --fileout file:step${step_num}_gpu.root"
        echo "  --customise=Validation/Performance/TimeMemorySummary.py"
        echo "  --python_filename=step${step_num}_gpu_timememoryinfo.py"
    } >> cmd_ts.sh
    
    # IgProf command for GPU
    {
        echo "${base_cmd} --fileout file:step${step_num}_gpu.root"
        echo "  --customise Validation/Performance/IgProfInfo.customise"
        echo "  --customise_commands \"$(get_gpu_output_customizations)\""
        echo "  --python_filename=step${step_num}_gpu_igprof.py"
    } >> cmd_ig.sh
    
    # NVProf command for GPU profiling
    {
        echo "${base_cmd} --fileout file:step${step_num}_gpu.root"
        echo "  --customise Validation/Performance/IgProfInfo.customise"
        echo "  --customise_commands \"$(get_gpu_output_customizations);"
        echo "  process.options.numberOfConcurrentLuminosityBlocks = 1;"
        echo "  process.add_(cms.Service('NVProfilerService', highlightModules = cms.untracked.vstring('siPixelClustersPreSplittingCUDA')))\""
        echo "  --python_filename=step${step_num}_gpu_nvprof.py"
    } >> cmd_np.sh
}

get_gpu_output_customizations() {
    cat << 'EOF'
process.FEVTDEBUGoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGEventContent.outputCommands);process.FEVTDEBUGHLToutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.FEVTDEBUGHLTEventContent.outputCommands);process.RECOSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.RECOSIMEventContent.outputCommands);process.AODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.AODSIMEventContent.outputCommands);process.MINIAODSIMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.MINIAODSIMEventContent.outputCommands);process.DQMoutput = cms.OutputModule('AsciiOutputModule',outputCommands = process.DQMEventContent.outputCommands)
EOF
}

generate_gpu_fasttimer_commands() {
    log "Generating GPU FastTimer commands"
    
    if ! check_gpu_workflow_support "${workflow_dir}"; then
        log_warn "Skipping GPU FastTimer generation for workflow 136.XYZ (no GPU modules)"
        return 0
    fi
    
    # Generate FastTimer commands for each step
    for step_idx in "${!workflow_steps[@]}"; do
        local step_cmd="${workflow_steps[step_idx]}"
        local step_num=$((step_idx + 1))
        
        {
            echo "${step_cmd} --fileout file:step${step_num}_gpu.root"
            echo "  --customise=HLTrigger/Timer/FastTimer.customise_timer_service_singlejob"
            echo "  --customise_commands \"process.FastTimerService.writeJSONSummary = cms.untracked.bool(True);"
            echo "  process.FastTimerService.jsonFileName = cms.untracked.string('step${step_num}_gpu.resources.json');"
            echo "  process.FastTimerService.enableDQMbyLumiSection = cms.untracked.bool(False);"
            echo "  process.options.numberOfConcurrentLuminosityBlocks = 1\""
            echo "  --python_filename=step${step_num}_gpu_fasttimer.py"
        } >> cmd_ft.sh
    done
    
    # Add special handling for 5th step if it exists
    if [[ ${#workflow_steps[@]} -gt 4 ]]; then
        log "Adding step 5 FastTimer configuration"
        # Step 5 configuration already included in the loop above
    fi
}

execute_gpu_command_files() {
    log "Executing generated GPU command files"
    
    # Execute in order: TimeMemory, FastTimer, IgProf, NVProf
    local execution_order=("cmd_ts.sh" "cmd_ft.sh" "cmd_ig.sh" "cmd_np.sh")
    
    for cmd_file in "${execution_order[@]}"; do
        if validate_file "${cmd_file}"; then
            log "Executing ${cmd_file}"
            # shellcheck source=/dev/null
            source "${cmd_file}" || {
                log_error "Failed to execute ${cmd_file}"
                return 1
            }
            log_success "Completed execution of ${cmd_file}"
        else
            log_warn "Command file not found: ${cmd_file}"
        fi
    done
}

setup_gpu_workflow_parameters() {
    # GPU-specific workflow parameters
    if [[ "X${PROFILING_WORKFLOW:-}" == "X" ]]; then
        export PROFILING_WORKFLOW="${DEFAULT_WORKFLOW}"
    fi
    
    if [[ "X${NTHREADS:-}" == "X" ]]; then
        export NTHREADS="${DEFAULT_NTHREADS}"
    fi
    
    if [[ "X${EVENTS:-}" == "X" ]]; then
        export EVENTS=$((NTHREADS * 10))
    fi
    
    log "GPU Workflow parameters:"
    log "  PROFILING_WORKFLOW: ${PROFILING_WORKFLOW}"
    log "  NTHREADS: ${NTHREADS}"
    log "  EVENTS: ${EVENTS}"
}

validate_gpu_workflow() {
    local workflow=$1
    
    log "Validating GPU workflow: ${workflow}"
    
    # Check if workflow exists in matrix
    if runTheMatrix.py -n | grep -q "^${workflow} " 2>/dev/null; then
        log "GPU workflow found in default matrix"
        return 0
    fi
    
    # Check with extended flags
    if runTheMatrix.py -n ${MATRIX_WHAT_FLAGS} | grep -q "^${workflow}"; then
        log "GPU workflow found in extended matrix"
        return 0
    fi
    
    log_error "GPU workflow ${workflow} not found in matrix"
    return 1
}

generate_gpu_workflow_configs() {
    local workflow=$1
    
    log "Generating GPU workflow configurations for: ${workflow}"
    
    # Determine command based on environment
    local matrix_cmd="runTheMatrix.py"
    local matrix_args=()
    
    if [[ "X${WORKSPACE:-}" != "X" ]]; then
        # Jenkins mode - no --ibeos flag for GPU workflows in workspace
        matrix_args+=(${MATRIX_WHAT_FLAGS} -l "${workflow}")
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
    
    log "Running GPU matrix command: ${matrix_cmd} ${matrix_args[*]}"
    
    execute_with_timeout 300 "runTheMatrix GPU workflow generation" \
        "${matrix_cmd}" "${matrix_args[@]}" || {
        log_error "Failed to generate GPU workflow configurations"
        return 1
    }
    
    setup_gpu_workflow_directory "${workflow}"
}

setup_gpu_workflow_directory() {
    local workflow=$1
    
    # Find the generated directory
    local generated_dirs
    mapfile -t generated_dirs < <(find . -maxdepth 1 -name "${workflow}*" -type d 2>/dev/null)
    
    if [[ ${#generated_dirs[@]} -eq 0 ]]; then
        log_error "No GPU workflow directory generated for ${workflow}"
        return 1
    fi
    
    local outdir="${generated_dirs[0]}"
    workflow_dir="${outdir}"
    log "Found GPU workflow directory: ${outdir}"
    
    # Handle existing workflow directory
    if [[ -d "${workflow}" ]]; then
        local backup_dir="${workflow}.1"
        log "Backing up existing GPU workflow directory to ${backup_dir}"
        rm -rf "${backup_dir}" 2>/dev/null || true
        mv "${workflow}" "${backup_dir}"
    fi
    
    # Move generated directory to standard name
    mv "${outdir}" "${workflow}" || {
        log_error "Failed to rename GPU workflow directory"
        return 1
    }
    
    cd "${workflow}" || {
        log_error "Failed to enter GPU workflow directory"
        return 1
    }
    
    log_success "GPU workflow directory setup complete: $(pwd)"
}

extract_gpu_workflow_steps() {
    local steps_file="cmdLog"
    
    if ! validate_file "${steps_file}"; then
        log_error "GPU workflow steps file not found: ${steps_file}"
        return 1
    fi
    
    log "Extracting GPU workflow steps from ${steps_file}"
    
    # Extract cmsDriver commands and store in array
    mapfile -t workflow_steps < <(grep cmsDriver.py "${steps_file}" | cut -d'>' -f1)
    
    if [[ ${#workflow_steps[@]} -eq 0 ]]; then
        log_error "No GPU workflow steps found in ${steps_file}"
        return 1
    fi
    
    log "Found ${#workflow_steps[@]} GPU workflow steps:"
    for i in "${!workflow_steps[@]}"; do
        log "  Step $((i+1)): ${workflow_steps[i]}"
    done
    
    export workflow_steps
    export workflow_dir
}

#==============================================================================
# Main Function
#==============================================================================

main() {
    local cmssw_version=${1:-${CMSSW_VERSION}}
    
    print_header "${BASH_SOURCE[0]}" "GPU CMSSW Workflow Generator (Refactored)"
    
    # Validate inputs
    if [[ -z "${cmssw_version}" ]]; then
        log_error "CMSSW version must be provided either as argument or CMSSW_VERSION environment variable"
        exit 1
    fi
    
    # Setup environment
    setup_cmssw_version "${cmssw_version}" || exit 1
    setup_scram_arch
    setup_gpu_workflow_parameters
    
    # Validate required commands
    local required_commands=("runTheMatrix.py" "scram" "grep" "cut")
    for cmd in "${required_commands[@]}"; do
        validate_command "${cmd}" || exit 1
    done
    
    # Setup CMSSW environment
    setup_cmssw_environment "${CMSSW_VERSION}" || exit 1
    
    # Validate and generate GPU workflow
    validate_gpu_workflow "${PROFILING_WORKFLOW}" || exit 1
    generate_gpu_workflow_configs "${PROFILING_WORKFLOW}" || exit 1
    
    # Extract steps and generate GPU command files
    extract_gpu_workflow_steps || exit 1
    generate_gpu_command_files || exit 1
    
    log_success "GPU workflow generation completed successfully"
    log "Generated GPU command files:"
    for cmd_file in "${GPU_CMD_FILES[@]}"; do
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
    log_debug "Cleaning up GPU workflow generator"
    return ${exit_code}
}

# Parse command line arguments and run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi