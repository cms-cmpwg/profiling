#!/bin/bash
#
# Unified Profiling Runner
# Replaces multiple runall_*.sh scripts with a single configurable runner
#
# Usage: ./unified_profiling_runner.sh [PROFILING_TYPE] [CMSSW_VERSION]
#
# PROFILING_TYPE can be: cpu, mem, gpu, vtune, jemal, fasttimer
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

# Profiling type configuration
declare -A PROFILING_CONFIGS=(
    ["cpu"]="igprof -pp -d -t cmsRun -z"
    ["mem"]="igprof -mp -t cmsRun -z"
    ["gpu"]="cmsRun"
    ["vtune"]="vtune -collect hotspots -data-limit=0 -knob enable-stack-collection=true -knob stack-size=4096 -knob sampling-mode=sw --"
    ["jemal"]="cmsRunJEProf"
    ["fasttimer"]="cmsRun"
)

declare -A DEFAULT_WORKFLOWS=(
    ["cpu"]="29834.21"
    ["mem"]="23834.21"
    ["gpu"]="23834.21"
    ["vtune"]="29834.21"
    ["jemal"]="23834.21"
    ["fasttimer"]="23834.21"
)

declare -A ENV_SETUPS=(
    ["jemal"]="setup_jemalloc_env"
    ["cpu"]="setup_igprof_env"
    ["mem"]="setup_igprof_env"
    ["vtune"]="setup_vtune_env"
)

#==============================================================================
# Environment Setup Functions
#==============================================================================

setup_jemalloc_env() {
    log "Setting up jemalloc environment"
    scram setup jemalloc-prof || {
        log_error "Failed to setup jemalloc-prof"
        return 1
    }
    scram b ToolUpdated || {
        log_warn "Failed to update tools, continuing anyway"
    }
    export MALLOC_CONF="prof_leak:true,lg_prof_sample:10,prof_final:true"
    log "jemalloc environment configured"
}

setup_igprof_env() {
    log "Setting up igprof environment"
    
    # Ensure compiler include paths are added to ROOT_INCLUDE_PATH
    local include_paths
    include_paths=$(LC_ALL=C g++ -xc++ -E -v /dev/null 2>&1 | sed -n -e '/^.include/,${' -e '/^ \/.*++/p' -e '}')
    for path in ${include_paths}; do 
        ROOT_INCLUDE_PATH="${path}:${ROOT_INCLUDE_PATH:-}"
    done
    export ROOT_INCLUDE_PATH
    
    # Set up TensorFlow environment for newer CMSSW versions
    setup_tensorflow_env
    
    # Set environment variables for optimal performance
    export TF_ENABLE_ZENDNN_OPTS=1
    export OMP_NUM_THREADS=1
    export MALLOC_CONF=zero:true
    export TF_ENABLE_ONEDNN_OPTS=0
    
    log "igprof environment configured"
}

setup_vtune_env() {
    log "Setting up VTune environment"
    validate_command "vtune" || return 1
    
    # Set up TensorFlow environment for VTune profiling
    setup_tensorflow_env
    
    # Set environment variables for VTune
    export TF_ENABLE_ZENDNN_OPTS=1
    export OMP_NUM_THREADS=1
    export MALLOC_CONF=zero:true
    export TF_ENABLE_ONEDNN_OPTS=0
    
    log "VTune environment configured"
}

setup_tensorflow_env() {
    if [[ "${CMSSW_VERSION}" =~ CMSSW_15_1_.* ]]; then
        log "Setting up TensorFlow for CMSSW 15.1.x"
        scram tool info tensorflow
        
        local tf_file
        tf_file=$(ls -1 "/cvmfs/cms-ib.cern.ch/sw/x86_64/nweek-*/${SCRAM_ARCH}/cms/cmssw/CMSSW_15_1_MKLDNN0_*/config/toolbox/${SCRAM_ARCH}/tools/selected/tensorflow.xml" 2>/dev/null | tail -1)
        
        if [[ -f "${tf_file}" ]]; then
            log "Found TensorFlow config: ${tf_file}"
            scram setup "${tf_file}" || log_warn "Failed to setup TensorFlow"
            scram b ToolUpdated || log_warn "Failed to update TensorFlow tools"
            scram tool info tensorflow
        else
            log_warn "TensorFlow config not found for CMSSW 15.1.x"
        fi
    fi
}

#==============================================================================
# Profiling Functions
#==============================================================================

# Run profiling steps based on type
run_profiling_steps() {
    local profiling_type=$1
    local cmd_prefix="${PROFILING_CONFIGS[${profiling_type}]}"
    
    if [[ -z "${cmd_prefix}" ]]; then
        log_error "Unknown profiling type: ${profiling_type}"
        return 1
    fi
    
    log "Starting ${profiling_type} profiling"
    
    # Source the appropriate command file
    local cmd_file
    case "${profiling_type}" in
        "cpu"|"mem") cmd_file="cmd_ig.sh" ;;
        "jemal") cmd_file="cmd_je.sh" ;;
        "vtune") cmd_file="cmd_ts.sh" ;;
        "gpu"|"fasttimer") cmd_file="cmd_ft.sh" ;;
        *) 
            log_error "No command file mapping for profiling type: ${profiling_type}"
            return 1
            ;;
    esac
    
    if validate_file "${cmd_file}"; then
        # shellcheck source=/dev/null
        source "${cmd_file}" || {
            log_error "Failed to source ${cmd_file}"
            return 1
        }
    else
        log_error "Command file not found: ${cmd_file}"
        return 1
    fi
    
    # Run profiling steps
    local steps_run=0
    
    # Check if we should run all steps or limited steps
    if [[ "X${RUNALLSTEPS:-}" != "X" ]]; then
        run_step "${profiling_type}" "step1" && ((steps_run++))
        run_step "${profiling_type}" "step2" && ((steps_run++))
    fi
    
    # Always run step3 and step4
    run_step "${profiling_type}" "step3" && ((steps_run++))
    run_step "${profiling_type}" "step4" && ((steps_run++))
    
    # Check for step5
    if ls step5_*.py &>/dev/null; then
        run_step "${profiling_type}" "step5" && ((steps_run++))
    else
        log "No step5 in workflow ${PROFILING_WORKFLOW}"
    fi
    
    log "Completed ${steps_run} profiling steps"
    
    # Run post-processing
    run_post_processing "${profiling_type}"
}

# Run individual profiling step
run_step() {
    local profiling_type=$1
    local step_name=$2
    
    local config_file="${step_name}_$(get_config_suffix "${profiling_type}").py"
    local log_file="${step_name}_${profiling_type}.log"
    local job_report="${step_name}_${profiling_type}_JobReport.xml"
    
    case "${profiling_type}" in
        "cpu")
            run_cpu_step "${step_name}" "${config_file}" "${log_file}"
            ;;
        "mem")
            run_mem_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "jemal")
            run_jemal_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "vtune")
            run_vtune_step "${step_name}" "${config_file}" "${log_file}"
            ;;
        "gpu"|"fasttimer")
            run_fasttimer_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        *)
            log_error "Unknown profiling type for step execution: ${profiling_type}"
            return 1
            ;;
    esac
}

# Get config file suffix for profiling type
get_config_suffix() {
    local profiling_type=$1
    case "${profiling_type}" in
        "cpu"|"mem") echo "igprof" ;;
        "jemal") echo "jeprof" ;;
        "vtune") echo "timememoryinfo" ;;
        "gpu") echo "gpu_fasttimer" ;;
        "fasttimer") echo "fasttimer" ;;
        *) echo "unknown" ;;
    esac
}

# Specific step runners
run_cpu_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with igprof CPU profiling"
        local output_file="./igprofCPU_${step_name}.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof CPU ${step_name}" \
            igprof -pp -d -t cmsRun -z -o "${output_file}" -- cmsRun "${config_file}" >& "${log_file}"
        
        # Rename igprof files
        rename_profiling_files "IgProf*.gz" "igprofCPU_${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_mem_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with igprof memory profiling"
        local output_file="./igprofMEM_${step_name}.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof MEM ${step_name}" \
            igprof -mp -t cmsRun -z -o "${output_file}" -- cmsRun "${config_file}" -j "${job_report}" >& "${log_file}"
        
        # Rename igprof files
        rename_profiling_files "IgProf*.gz" "igprofMEM_${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_jemal_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with jemalloc profiling"
        
        execute_with_timeout "${TIMEOUT}" "jemalloc ${step_name}" \
            env MALLOC_CONF="${MALLOC_CONF}" cmsRunJEProf "${config_file}" -j "${job_report}" >& "${log_file}"
        
        # Rename jemalloc files
        rename_profiling_files "jeprof.*.heap" "${step_name}_jeprof"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_vtune_step() {
    local step_name=$1
    local config_file $2
    local log_file=$3
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with VTune profiling"
        local result_dir="r-${step_name}-${PROFILING_WORKFLOW}-hs"
        local output_csv="${step_name}-${PROFILING_WORKFLOW}.gprof-cc.csv"
        
        # Run VTune collection
        execute_with_timeout "${TIMEOUT}" "VTune ${step_name}" \
            vtune -collect hotspots -r "${result_dir}" -data-limit=0 \
                -knob enable-stack-collection=true -knob stack-size=4096 \
                -knob sampling-mode=sw -- cmsRun "${config_file}" >& "${log_file}"
        
        # Generate report
        vtune -report gprof-cc -r "${result_dir}" -format=csv \
            -csv-delimiter=semicolon -report-output "${output_csv}" || {
            log_warn "Failed to generate VTune report for ${step_name}"
        }
        
        # Compress the CSV
        gzip "${output_csv}" || log_warn "Failed to compress VTune CSV for ${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_fasttimer_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with FastTimer"
        
        execute_with_timeout "${TIMEOUT}" "FastTimer ${step_name}" \
            cmsRun "${config_file}" -j "${job_report}" >& "${log_file}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

# Run post-processing specific to profiling type
run_post_processing() {
    local profiling_type=$1
    
    case "${profiling_type}" in
        "fasttimer"|"gpu")
            generate_event_sizes
            ;;
        "jemal")
            unset MALLOC_CONF
            log "Unset MALLOC_CONF after jemalloc profiling"
            ;;
    esac
}

# Generate event size files
generate_event_sizes() {
    log "Generating event size files"
    
    for step in step3 step4 step5; do
        local root_file="${step}.root"
        local size_file="${step}_sizes_${PROFILING_WORKFLOW}.txt"
        
        if [[ -f "${root_file}" ]]; then
            edmEventSize -v "${root_file}" > "${size_file}" || {
                log_warn "Failed to generate event size for ${root_file}"
            }
            log "Generated event sizes: ${size_file}"
        else
            log_debug "No ${root_file} found, skipping event size generation"
        fi
    done
}

#==============================================================================
# Main Function
#==============================================================================

main() {
    local profiling_type=${1:-"cpu"}
    local cmssw_version=${2:-""}
    
    print_header "${BASH_SOURCE[0]}" "Unified CMS Profiling Runner"
    
    # Validate profiling type
    if [[ -z "${PROFILING_CONFIGS[${profiling_type}]}" ]]; then
        log_error "Invalid profiling type: ${profiling_type}"
        log_error "Valid types: ${!PROFILING_CONFIGS[*]}"
        exit 1
    fi
    
    log "Profiling type: ${profiling_type}"
    
    # Setup environment
    setup_cmssw_version "${cmssw_version}" || exit 1
    setup_scram_arch
    setup_profiling_workflow "${DEFAULT_WORKFLOWS[${profiling_type}]}"
    setup_workspace "${CMSSW_VERSION}" || exit 1
    setup_common_env
    
    # Setup profiling-specific environment
    local env_setup_func="${ENV_SETUPS[${profiling_type}]:-}"
    if [[ -n "${env_setup_func}" ]]; then
        ${env_setup_func} || exit 1
    fi
    
    # Run profiling
    run_profiling_steps "${profiling_type}" || exit 1
    
    print_footer 0
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    log_debug "Cleaning up unified profiling runner"
    
    # Unset environment variables that might affect other scripts
    unset MALLOC_CONF 2>/dev/null || true
    
    return ${exit_code}
}

# Parse command line arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi