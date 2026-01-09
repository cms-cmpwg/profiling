#!/bin/bash 
#
# Unified Profiling Runner
# Replaces multiple runall_*.sh scripts with a single configurable runner

#
# Usage: ./unified_profiling_runner.sh [PROFILING_TYPE] [CMSSW_VERSION]
#
# PROFILING_TYPE can be: cpu, mem, mem_gc, mem_tc, gpu, gpu_igmp, gpu_igpp, gpu_nsys, nvprof, timemem, allocmon, vtune, jemal, fasttimer
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
declare -A profiling_commands=(
    ["cpu"]="igprof -pp -d -t cmsRun -z"
    ["mem"]="igprof -mp -t cmsRun -z"
    ["mem_gc"]="igprof -mp -t cmsRunGlibC -z"
    ["mem_tc"]="igprof -mp -t cmsRunTCMalloc -z"
    ["gpu"]="cmsRun"
    ["gpu_igmp"]="igprof -mp -t cmsRunGlibC -z"
    ["gpu_igpp"]="igprof -pp -d -t cmsRun -z"
    ["gpu_nsys"]="nsys profile --kill=sigkill --export=sqlite --stats=true"
    ["nvprof"]="nvprof -o"
    ["timemem"]="cmsRun"
    ["allocmon"]="edmModuleAllocMonitoryAnalyze.py -j"
    ["vtune"]="amplxe-cl -collect hotspots -r"
    ["jemal"]="igprof -mp -t cmsRun -z"
    ["fasttimer"]="cmsRun"
)

declare -A DEFAULT_WORKFLOWS=(
    ["cpu"]="13034.21"
    ["mem"]="13034.21"
    ["mem_gc"]="13034.21"
    ["mem_tc"]="13034.21"
    ["gpu"]="13034.21"
    ["gpu_igmp"]="13034.21"
    ["gpu_igpp"]="13034.21"
    ["gpu_nsys"]="13034.21"
    ["nvprof"]="13034.21"
    ["timemem"]="13034.21"
    ["allocmon"]="13034.21"
    ["vtune"]="13034.21"
    ["jemal"]="13034.21"
    ["fasttimer"]="13034.21"
)

declare -A setup_functions=(
    ["cpu"]="setup_igprof_env"
    ["mem"]="setup_igprof_env"
    ["mem_gc"]="setup_igprof_env"
    ["mem_tc"]="setup_igprof_env"
    ["gpu"]="setup_fasttimer_env"
    ["gpu_igmp"]="setup_gpu_igprof_env"
    ["gpu_igpp"]="setup_gpu_igprof_env"
    ["gpu_nsys"]="setup_gpu_nsys_env"
    ["nvprof"]="setup_nvprof_env"
    ["timemem"]="setup_timemem_env"
    ["allocmon"]="setup_allocmon_env"
    ["vtune"]="setup_vtune_env"
    ["jemal"]="setup_igprof_env"
    ["fasttimer"]="setup_fasttimer_env"
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
#    setup_tensorflow_env
    
    # Set environment variables for optimal performance
    export TF_ENABLE_ZENDNN_OPTS=1
    export OMP_NUM_THREADS=1
    export MALLOC_CONF=zero:true
    export TF_ENABLE_ONEDNN_OPTS=0
    
    log "igprof environment configured"
}

# GPU IgProf Environment Setup
setup_gpu_igprof_env() {
    log "Setting up GPU IgProf environment"
    
    # Set up base IgProf environment first
    setup_igprof_env
    
    # GPU-specific environment variables for performance optimization
    # Override some base settings for GPU profiling
    export TF_ENABLE_ONEDNN_OPTS=1  # Enable for GPU
    export ONEDNN_MAX_CPU_ISA=AVX2
    export ONEDNN_CPU_ISA_HINTS=PREFER_YMM
    export ONEDNN_JIT_PROFILE=14
    export JITDUMPDIR=.
    
    log "GPU IgProf environment configured with performance optimizations"
}

# GPU Nsight Systems Environment Setup
setup_gpu_nsys_env() {
    log "Setting up GPU Nsight Systems environment"
    
    # Add CUDA toolkit paths
    if [[ -d "/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin" ]]; then
        PATH="$PATH:/cvmfs/patatrack.cern.ch/externals/x86_64/rhel8/nvidia/cuda-11.8.0/bin"
        log "Added CUDA toolkit from patatrack CVMFS to PATH"
    elif [[ -d "/opt/nvidia/nsight-systems/bin" ]]; then
        PATH="$PATH:/opt/nvidia/nsight-systems/bin"
        log "Added local Nsight Systems to PATH"
    fi
    export PATH
    
    # Set GPU profiling timeout (shorter than default)
    export TIMEOUT="${TIMEOUT:-7200}"
    
    # Validate nsys command availability
    if ! command -v nsys >/dev/null 2>&1; then
        log_error "nsys command not found. Ensure NVIDIA Nsight Systems is installed and in PATH."
        return 1
    fi
    
    log "GPU Nsight Systems environment configured"
}

setup_vtune_env() {
    log "Setting up VTune environment"
    validate_command "vtune" || return 1
    
    # Set up TensorFlow environment for VTune profiling
#    setup_tensorflow_env
    
    # Set environment variables for VTune
    export TF_ENABLE_ZENDNN_OPTS=1
    export OMP_NUM_THREADS=1
    export MALLOC_CONF=zero:true
    export TF_ENABLE_ONEDNN_OPTS=0
    
    log "VTune environment configured"
}

setup_tensorflow_env() {
        log "Setting up TensorFlow for ${CMSSW_VERSION}"
        scram tool info tensorflow

        local base_version=""
        if [[ "${CMSSW_VERSION}" =~ ^(CMSSW_[0-9]+_[0-9]+_) ]]; then
            base_version="${BASH_REMATCH[1]}"
        fi
        local tf_file
        tf_file=$(ls -1 /cvmfs/cms-ib.cern.ch/sw/x86_64/nweek-*/${SCRAM_ARCH}/cms/cmssw/${base_version}MKLDNN0_*/config/toolbox/${SCRAM_ARCH}/tools/selected/tensorflow.xml 2>/dev/null | tail -1)
        
        if [[ -f "${tf_file}" ]]; then
            log "Found TensorFlow config: ${tf_file}"
            scram setup "${tf_file}" || log_warn "Failed to setup TensorFlow"
            scram b ToolUpdated || log_warn "Failed to update TensorFlow tools"
            scram tool info tensorflow
        else
            log_warn "TensorFlow config not found for ${CMSSW_VERSION}"
        fi

}

setup_fasttimer_env() {
    log "Setting up FastTimer environment"
    
    # Set up TensorFlow environment
#    setup_tensorflow_env
    
    log "FastTimer environment configured"
}

setup_nvprof_env() {
    log "Setting up nvprof environment"
    
    # Validate nvprof command availability
    if ! command -v nvprof >/dev/null 2>&1; then
        log_error "nvprof command not found. Ensure CUDA toolkit is installed."
        return 1
    fi
    
    log "nvprof environment configured"
}

setup_timemem_env() {
    log "Setting up TimeMemoryService environment"
    
    # No special setup required for TimeMemoryService
    log "TimeMemoryService environment configured"
}

setup_allocmon_env() {
    log "Setting up AllocMonitor environment"
    # AllocMonitor requires edmModuleAllocJsonToCircles.py for post-processing
    validate_command "edmModuleAllocJsonToCircles.py" || { log_error "edmModuleAllocJsonToCircles.py not found"; return 1; }
    log "AllocMonitor environment configured"
}

#==============================================================================
# Profiling Functions
#==============================================================================

# Run profiling steps based on type
run_profiling_steps() {
    local profiling_type=$1
    local cmd_prefix="${profiling_commands[${profiling_type}]:-}"
    
    if [[ -z "${cmd_prefix}" ]]; then
        log_error "Unknown profiling type: ${profiling_type}"
        return 1
    fi
    
    log "Starting ${profiling_type} profiling"
    
    # Source the appropriate command file
    local cmd_file
    case "${profiling_type}" in
        "cpu"|"mem"|"mem_gc"|"mem_tc"|"gpu_igmp"|"gpu_igpp") cmd_file="cmd_ig.sh" ;;
        "jemal") cmd_file="cmd_je.sh" ;;
        "vtune"|"timemem") cmd_file="cmd_ts.sh" ;;
        "gpu"|"fasttimer") cmd_file="cmd_ft.sh" ;;
        "gpu_nsys") cmd_file="cmd_nsys.sh" ;;
        "nvprof") cmd_file="cmd_np.sh" ;;
        "allocmon") cmd_file="cmd_am.sh" ;;
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
    
    # Special handling for mem_gc, mem_tc, and gpu_igprof profiling types
    if [[ "${profiling_type}" == "mem_gc" || "${profiling_type}" == "mem_tc" || "${profiling_type}" == "gpu_igmp" || "${profiling_type}" == "gpu_igpp" ]]; then
        # GlibC, tcmalloc memory profiling, and GPU IgProf have specific step requirements
        if [[ "X${RUNALLSTEPS:-}" != "X" ]]; then
            run_step "${profiling_type}" "step1" && ((steps_run++))
            run_step "${profiling_type}" "step2" && ((steps_run++))
        fi
        
        # Always run step3 for these profiling types
        run_step "${profiling_type}" "step3" && ((steps_run++))
        
        # Step4 and Step5 are commented out in original mem_GC, mem_TC, and GPU IgProf scripts
        log "Note: step4 and step5 are disabled for ${profiling_type} profiling type"
    else
        # Standard step execution for other profiling types
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
        "mem_gc")
            run_mem_gc_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "mem_tc")
            run_mem_tc_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "gpu_igmp")
            run_gpu_igmp_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "gpu_igpp")
            run_gpu_igpp_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "gpu_nsys")
            run_gpu_nsys_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "nvprof")
            run_nvprof_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "timemem")
            run_timemem_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
            ;;
        "allocmon")
            run_allocmon_step "${step_name}" "${config_file}" "${log_file}" "${job_report}"
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
        "cpu"|"mem"|"mem_gc"|"mem_tc") echo "igprof" ;;
        "gpu_igmp"|"gpu_igpp") echo "gpu_igprof" ;;
        "jemal") echo "jeprof" ;;
        "vtune"|"timemem") echo "timememoryinfo" ;;
        "gpu") echo "gpu_fasttimer" ;;
        "gpu_nsys") echo "gpu_nvprof" ;;
        "nvprof") echo "nvprof" ;;
        "allocmon") echo "allocmon" ;;
        "fasttimer") echo "fasttimer" ;;
        *) echo "igprof" ;;
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
            igprof -pp -d -t cmsRun -z -o "${output_file}" -- cmsRun "${config_file}" 2>&1 | tee "${log_file}"
        
        # Rename igprof files
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofCPU_${step_name}"
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
            igprof -mp -t cmsRun -z -o "${output_file}" -- cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Rename igprof files
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofMEM_${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_mem_gc_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with igprof GlibC memory profiling"
        local output_file="./igprofMEM_GC_${step_name}.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof MEM_GC ${step_name}" \
            igprof -mp -t cmsRunGlibC -z -o "${output_file}" -- cmsRunGlibC "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Rename igprof files for GlibC profiling
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofMEM_GC_${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

# GPU IgProf Memory Profiling Step
run_gpu_igmp_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if [[ -f "${config_file}" ]]; then
        log "${step_name} GPU IgProf Memory Profiling"
        local output_file="./igprofMEM_${step_name}.mp.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof GPU MEM ${step_name}" \
            igprof -mp -t cmsRunGlibC -z -o "${output_file}" -- \
            cmsRunGlibC "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Rename output files
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofMEM_${step_name}"
    else
        log "missing ${config_file}"
    fi
}

# GPU IgProf Performance Profiling Step
run_gpu_igpp_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if [[ -f "${config_file}" ]]; then
        log "${step_name} GPU IgProf Performance Profiling"
        local output_file="./igprofCPU_${step_name}.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof GPU CPU ${step_name}" \
            igprof -pp -d -t cmsRun -z -o "${output_file}" -- \
            cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Rename output files
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofCPU_${step_name}"
    else
        log "missing ${config_file}"
    fi
}

# GPU Nsight Systems Profiling Step
run_gpu_nsys_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if [[ -f "${config_file}" ]]; then
        log "${step_name} GPU Nsight Systems Profiler"
        local output_file="${step_name}_gpu_nsys"
        local stats_file="${step_name}_gpu_nsys.txt"
        
        # Run Nsight Systems profiling
        execute_with_timeout "${TIMEOUT}" "nsys GPU ${step_name}" \
            nsys profile --kill=sigkill --output="${output_file}" --export=sqlite --stats=true \
            --trace=cuda,nvtx,osrt,openmp,mpi,oshmem,ucx --mpi-impl=openmpi --show-output=true \
            cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Generate statistics if profiling succeeded
        if [[ -f "${output_file}.nsys-rep" ]]; then
            log "Generating GPU statistics for ${step_name}"
            nsys stats -f csv --report gpukernsum,gpumemtimesum,gpumemsizesum "${output_file}.nsys-rep" > "${stats_file}" 2>/dev/null || \
                log "Warning: Failed to generate statistics for ${step_name}"
        fi
    else
        log "missing ${config_file}"
    fi
}

run_mem_tc_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with igprof tcmalloc memory profiling"
        local output_file="./igprofMEM_TC_${step_name}.gz"
        
        execute_with_timeout "${TIMEOUT}" "igprof MEM_TC ${step_name}" \
            igprof -mp -t cmsRunTC -z -o "${output_file}" -- cmsRunTC "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Rename igprof files for tcmalloc profiling
        rename_profiling_files "IgProf*.gz" "IgProf" "igprofMEM_TC_${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_nvprof_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with NVIDIA Profiler (nvprof)"
        local output_file="${step_name}.nvprof"
        
        execute_with_timeout "${TIMEOUT}" "nvprof ${step_name}" \
            nvprof -o "${output_file}" -s cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        log "NVIDIA Profiler output saved to: ${output_file}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_timemem_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with TimeMemoryService profiling"
        
        execute_with_timeout "${TIMEOUT}" "TimeMemory ${step_name}" \
            cmsRun "${config_file}" 2>&1 | tee "${log_file}"

        log "TimeMemoryService profiling completed for ${step_name}"
        
        # Generate event size information if ROOT files exist
        generate_event_sizes "${step_name}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_allocmon_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    local job_report=$4
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with AllocMonitor profiling"
        
        # Create moduleAllocMonitor log for analysis
        local module_alloc_log="moduleAllocMonitor.log"
        local step_module_alloc_log="${step_name}_${module_alloc_log}"

        execute_with_timeout "${TIMEOUT}" "AllocMonitor ${step_name}" \
            env LD_PRELOAD=libPerfToolsAllocMonitorPreload.so cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"

        # Copy relevant log content for module analysis (if needed)
        if [[ -f "${module_alloc_log}" ]]; then
            cp "${module_alloc_log}" "${step_module_alloc_log}"
        fi

        log "AllocMonitor profiling completed for ${step_name}"
        
        # Run edmModuleAllocMonitorAnalyze post-processing
        run_edmmodule_allocmonitor_analyze "${step_name}"

        # Check for AllocMonitor output files
        if ls *${module_alloc_log} >/dev/null 2>&1; then
            log "AllocMonitor output files generated:"
            for file in *${module_alloc_log}; do
                log "  - ${file}"
            done
        fi

        # Check for module analysis output
        if [[ -f "${step_name}_moduleAllocMonitor.json" ]]; then
            log "Module AllocMonitor analysis completed: ${step_name}_moduleAllocMonitor.json"
        fi

        # Check for circles analysis output
        if [[ -f "${step_name}_moduleAllocMonitor.circles.json" ]]; then
            log "Module AllocMonitor circles analysis completed: ${step_name}_moduleAllocMonitor.circles.json"
        fi
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

generate_event_sizes() {
    local step_name=$1
    local root_file="${step_name}.root"
    local sizes_file="${step_name}_sizes_${PROFILING_WORKFLOW}.txt"
    
    if [[ -f "${root_file}" ]]; then
        log "Generating event sizes for ${root_file}"
        execute_with_timeout 300 "edmEventSize ${step_name}" \
            edmEventSize -v "${root_file}" > "${sizes_file}" || {
            log_warn "Failed to generate event sizes for ${root_file}"
            return 1
        }
        log "Event sizes saved to: ${sizes_file}"
    else
        log_debug "No ${root_file} found, skipping event size generation"
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
            env MALLOC_CONF="${MALLOC_CONF}" cmsRunJEProf "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"
        
        # Rename jemalloc files
        rename_profiling_files "jeprof.*.heap" "jeprof" "${step_name}_jeprof"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

run_vtune_step() {
    local step_name=$1
    local config_file=$2
    local log_file=$3
    
    if validate_file "${config_file}"; then
        log "Running ${step_name} with VTune profiling"
        local result_dir="r-${step_name}-${PROFILING_WORKFLOW}-hs"
        local output_csv="${step_name}-${PROFILING_WORKFLOW}.top-down.csv"
        
        # Run VTune collection
        execute_with_timeout "${TIMEOUT}" "VTune ${step_name}" \
            vtune -collect hotspots -r "${result_dir}" -data-limit=0 \
                -knob enable-stack-collection=true -knob stack-size=4096 \
                -knob sampling-mode=sw -- cmsRun "${config_file}" 2>&1 | tee "${log_file/_/-}"
        
        # Generate top-down report
        vtune -report top-down -r "${result_dir}" -format=csv \
            -column="CPU time:total" -column="CPU time:self" -column="function" -show-as=values \
            -csv-delimiter=semicolon -report-output "${output_csv}" || {
            log_warn "Failed to generate VTune top-down report for ${step_name}"
        }
        local sorted_file="sorted_RES_CPU_${step_name}.html"
        python3 ${SCRIPT_DIR}/extract_children.py "${output_csv}" --html "${sorted_file}" || log_warn "Failed to extract children in VTune top-down report for ${step_name}"
        # Compress the CSV
        gzip "${output_csv}" || log_warn "Failed to compress VTune top-down CSV for ${step_name}"
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
            cmsRun "${config_file}" -j "${job_report}" 2>&1 | tee "${log_file}"
    else
        log_warn "Missing ${config_file} for ${step_name}"
        return 1
    fi
}

# Run edmModuleAllocMonitorAnalyze for AllocMonitor post-processing
run_edmmodule_allocmonitor_analyze() {
    local step_name=$1
    local input_log="${step_name}_moduleAllocMonitor.log"
    local output_json="${step_name}_moduleAllocMonitor.json"
    local circles_json="${step_name}_moduleAllocMonitor.circles.json"

    if [[ -f "${input_log}" ]]; then
        log "Running edmModuleAllocMonitorAnalyze for ${step_name}"

        # Run without execute_with_timeout to avoid log messages in JSON output
        if timeout 300 edmModuleAllocMonitorAnalyze.py -j "${input_log}" > "${output_json}"; then
            log "AllocMonitor analysis output saved to: ${output_json}"
        else
            log_warn "Failed to run edmModuleAllocMonitorAnalyze for ${step_name}"
            return 1
        fi

        # Convert JSON to circles format if the analysis succeeded
        if [[ -f "${output_json}" ]]; then
            log "Running edmModuleAllocJsonToCircles for ${step_name}"

            # Run without execute_with_timeout to avoid log messages in JSON output
            if timeout 300 edmModuleAllocJsonToCircles.py "${output_json}" > "${circles_json}"; then
                log "AllocMonitor circles output saved to: ${circles_json}"
            else
                log_warn "Failed to run edmModuleAllocJsonToCircles for ${step_name}"
                return 1


            fi
            gzip -f "${output_json}" || log_warn "Failed to compress output JSON for ${step_name}"
        else
            log_warn "JSON file not found for circles conversion: ${output_json}"
            return 1
        fi
    else
        log_warn "AllocMonitor log file not found: ${input_log}"
        return 1
    fi
}

# Run igprof post-processing with SQL analysis
run_igprof_post_processing() {
    local profiling_type=$1
    local gzip_names=""
    local report_name=""
    case "${profiling_type}" in
        "cpu") gzip_names=(igprofCPU_step*.gz);;
        "mem") gzip_names=(igprofMEM_step*.gz);;
        "mem_gc") gzip_names=(igprofMEM_GC_step*.gz); report_name="-r MEM_LIVE";;
        "mem_tc") gzip_names=(igprofMEM_TC_step*.gz); report_name="-r MEM_LIVE";;
        "gpu_igmp") gzip_names=(igprofMEM_step*.gz); report_name="-r MEM_LIVE";;
        "gpu_igpp") gzip_names=(igprofCPU_step*.gz);;
        *) 
            log_error "Invalid profiling type for igprof post-processing: ${profiling_type}"
            return 1
            ;;
    esac

    log "Running igprof post-processing for ${profiling_type}"
    # Process all igprof .gz files
    for gz_file in "${gzip_names}"; do
        if [[ -f "${gz_file}" ]]; then
            log "Processing igprof file: ${gz_file}"
            
            # Generate SQL database file
            local sql_file="${gz_file%.gz}.sql3"
            local log_file="${gz_file%.gz}.log"
            local res_file="RES_${gz_file#igprof}"
            local txt_file="${res_file%.gz}.txt.gz"
            
            # Run igprof-analyse for SQL output with fix-igprof-sql.py
            log "Generating SQL database: ${sql_file}"
            if igprof-analyse --sqlite -v -d ${report_name} -g "${gz_file}" 2>> "${log_file}" | \
               "${SCRIPT_DIR}/fix-igprof-sql.py" /dev/stdin | \
               sqlite3 "${sql_file}" 2>> "${log_file}"; then
                log "SQL database generated: ${sql_file}"
            else
                log_warn "Failed to generate SQL database for ${gz_file}"
            fi
            
            # Run igprof-analyse for text output
            log "Generating text report: ${txt_file}"
            if igprof-analyse -v -d ${report_name} -g "${gz_file}" 2>> "${log_file}" | gzip -c > "${txt_file}"; then
                log "Text report generated: ${txt_file}"
            else
                log_warn "Failed to generate text report for ${gz_file}"
            fi
        fi
    done
    
    # Process step3 CPU results if available
    if [[ -f "RES_CPU_step3.txt.gz" ]]; then
        log "Processing step3 CPU results for doEvent analysis"
        
        local igrep_file="RES_CPU_step3.txt"
        local sorted_file="sorted_RES_CPU_step3.txt"
        
        # Extract and process step3 results
        if gzip -dc "RES_CPU_step3.txt.gz" > "${igrep_file}"; then
            # Run AWK processing for doEvent module analysis
            awk -v module=doEvent '
                BEGIN { total = 0; }
                {
                    if(substr($0,0,1)=="-") { good = 0; }
                    if(good && length($0)>0) { print $0; total += $3; }
                    if(substr($0,0,1)=="[" && index($0,module)!=0) { good = 1; }
                }
                END { print "Total: "total }
            ' "${igrep_file}" | \
            sort -n -r -k1 | \
            awk '{
                if(index($0,"Total: ")!=0) { total=$0; }
                else { print $0; }
            }
            END { print total; }' > "${sorted_file}" 2>&1
            
            # Clean up temporary file
            rm -f "${igrep_file}"
            
            log "doEvent analysis completed: ${sorted_file}"
        else
            log_warn "Failed to extract RES_CPU_step3.txt.gz"
        fi
    fi
    
    log "igprof post-processing completed"
}

# Run post-processing specific to profiling type
run_post_processing() {
    local profiling_type=$1
    
    case "${profiling_type}" in
        "cpu"|"mem"|"mem_gc"|"mem_tc"|"gpu_igmp"|"gpu_igpp")
            run_igprof_post_processing "${profiling_type}"
            ;;
        "fasttimer"|"gpu")
            generate_event_sizes
            ;;
        "timemem")
            generate_timemem_event_sizes
            ;;
        "allocmon")
            log "AllocMonitor post-processing completed during step execution"
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

# Generate event size files specifically for timemem profiling
generate_timemem_event_sizes() {
    log "Generating TimeMemory event size files"
    
    for step in step3 step4 step5; do
        local root_file="${step}.root"
        local size_file="${step}_sizes_${PROFILING_WORKFLOW}.txt"
        
        if [[ -f "${root_file}" ]]; then
            log "Generating event sizes for ${root_file}"
            execute_with_timeout 300 "edmEventSize ${step}" \
                edmEventSize -v "${root_file}" > "${size_file}" || {
                log_warn "Failed to generate event sizes for ${root_file}"
                continue
            }
            log "Generated TimeMemory event sizes: ${size_file}"
        else
            log "No ${root_file} found for TimeMemory profiling"
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
    if [[ -z "${profiling_commands[${profiling_type}]:-}" ]]; then
        log_error "Invalid profiling type: ${profiling_type}"
        log_error "Valid types: ${!profiling_commands[*]}"
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
    local env_setup_func="${setup_functions[${profiling_type}]:-}"
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
