#!/bin/bash
#
# runall_mem_JE.sh - Wrapper for Jemalloc Memory Profiling
# This script has been refactored to use the unified profiling runner
#
# Executes jemalloc memory profiling using jeprof across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_mem_JE.sh: Using unified profiling runner for jemalloc memory profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="jemal"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "jemal" "$@"
