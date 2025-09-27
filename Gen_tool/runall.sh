#!/bin/bash
#
# runall.sh - Wrapper for FastTimer Profiling
# This script has been refactored to use the unified profiling runner
#
# Executes FastTimer profiling across CMSSW workflow steps

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "runall.sh: Using unified profiling runner for FastTimer profiling"

# Set profiling type and call unified runner
export PROFILING_TYPE="fasttimer"
exec "${SCRIPT_DIR}/unified_profiling_runner.sh" "fasttimer" "$@"
