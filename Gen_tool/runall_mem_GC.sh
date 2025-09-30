#!/bin/bash
#
# runall_mem_GC.sh - Wrapper for GlibC Memory Profiling with IgProf
# This script has been refactored to use the unified profiling runner
#
# Executes GlibC memory profiling using IgProf across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_mem_GC.sh: Using unified profiling runner for GlibC memory profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="mem_gc"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "mem_gc" "$@"
