#!/bin/bash
#
# runall_gpu_igpp.sh - Wrapper for GPU IgProf Performance Profiling  
# This script has been refactored to use the unified profiling runner
#
# Executes GPU performance profiling using IgProf with cmsRun across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_gpu_igpp.sh: Using unified profiling runner for GPU IgProf performance profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="gpu_igpp"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "gpu_igpp" "$@"

