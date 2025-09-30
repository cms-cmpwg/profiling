#!/bin/bash
#
# runall_vtune.sh - Wrapper for VTune Profiling
# This script has been refactored to use the unified profiling runner
#
# Executes Intel VTune profiling across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_vtune.sh: Using unified profiling runner for VTune profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="vtune"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "vtune" "$@"

