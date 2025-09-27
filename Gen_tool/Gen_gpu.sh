#!/bin/bash
#
# Gen_gpu.sh - Legacy wrapper for GPU workflow generation
# This script has been refactored - it now calls the improved gpu_workflow_generator.sh
#
# ARCHITECTURE, RELEASE_FORMAT and PROFILING_WORKFLOW are defined in Jenkins job
# voms-proxy-init is run in Jenkins Singularity wrapper script.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities for logging
# shellcheck source=common_utils.sh
source "${SCRIPT_DIR}/common_utils.sh"
log "Gen_gpu.sh: Using refactored GPU workflow generator"

# Call the new refactored GPU workflow generator
exec "${SCRIPT_DIR}/gpu_workflow_generator.sh" "$@"
