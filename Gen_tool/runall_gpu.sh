#!/bin/bash
#
# runall_gpu.sh - Wrapper for GPU Profiling with FastTimer
# This script has been refactored to use the unified profiling runner
#
# Executes GPU profiling using FastTimer across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_gpu.sh: Using unified profiling runner for GPU profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="gpu"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "gpu" "$@"
