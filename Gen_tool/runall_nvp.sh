#!/bin/bash
#
# runall_nvp.sh - Wrapper for NVIDIA GPU Profiling with nvprof
# This script has been refactored to use the unified profiling runner
#
# Executes NVIDIA GPU profiling using nvprof across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_nvp.sh: Using unified profiling runner for NVIDIA GPU profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="nvprof"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "nvprof" "$@"
