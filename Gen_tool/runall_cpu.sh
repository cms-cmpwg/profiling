#!/bin/bash
#
# runall_cpu.sh - Wrapper for CPU Profiling with IgProf
# This script has been refactored to use the unified profiling runner
#
# Executes CPU profiling using IgProf across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall_cpu.sh: Using unified profiling runner for CPU profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="cpu"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "cpu" "$@"

