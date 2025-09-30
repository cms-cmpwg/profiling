#!/bin/bash
#
# runall_gpu_nvp.sh - Wrapper for GPU Nsight Systems Profiling
# This script has been refactored to use the unified profiling runner
#
# Executes GPU profiling using NVIDIA Nsight Systems (nsys) across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_gpu_nvp.sh: Using unified profiling runner for GPU Nsight Systems profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="gpu_nsys"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "gpu_nsys" "$@"
