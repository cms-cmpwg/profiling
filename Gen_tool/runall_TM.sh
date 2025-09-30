#!/bin/bash
#
# runall_TM.sh - Wrapper for TimeMemory Profiling with TimeMemoryService
# This script has been refactored to use the unified profiling runner
#
# Executes time and memory profiling using TimeMemoryService and generates event size reports

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_TM.sh: Using unified profiling runner for TimeMemory profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="timemem"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "timemem" "$@"
