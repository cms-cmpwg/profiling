#!/bin/bash
#
# runall_eventallocmon.sh - Wrapper for EventAllocMonitor Memory Profiling
# This script executes EventAllocMonitor profiling using CMSSW's ModuleEventAllocMonitor
#
# AllocMonitor provides detailed memory allocation tracking for CMSSW modules
# and generates JSON output files with allocation statistics.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
if [[ -f "${SCRIPT_DIR}/common_utils.sh" ]]; then
    source "${SCRIPT_DIR}/common_utils.sh"
    log "runall_eventallocmon.sh: Using unified profiling runner for AllocMonitor profiling"
    
    # Set profiling type and call unified runner
    export PROFILING_TYPE="eventallocmon"
    exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "eventallocmon" "$@"
else
    echo "Error: common_utils.sh not found"
    echo "This script requires the refactored profiling infrastructure."
    echo "Please ensure all refactored files are present in the same directory."
    exit 1
fi