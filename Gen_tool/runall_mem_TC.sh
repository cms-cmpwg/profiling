#!/bin/bash
#
# runall_mem_TC.sh - Wrapper for tcmalloc Memory Profiling with IgProf
# This script has been refactored to use the unified profiling runner
#
# Executes tcmalloc memory profiling using IgProf across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_mem_TC.sh: Using unified profiling runner for tcmalloc memory profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="mem_tc"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "mem_tc" "$@"
