#!/bin/bash
# ICP-1 Test 1: Simple Single-Task Job
#
# Tests basic job submission and execution with a single echo command.
# This validates the minimal viable path: AGX → AGQ → AGW → AGQ

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/config.sh"

echo "========================================"
echo "ICP-1 Test 1: Simple Single-Task Job"
echo "========================================"

# Check prerequisites
check_binaries || exit 2
check_port || exit 2

# Cleanup any previous test runs
"$HELPERS_DIR/cleanup.sh" 2>/dev/null || true

# Start AGQ
log_info "Step 1: Starting AGQ..."
source "$HELPERS_DIR/start_agq.sh"

# Start AGW
log_info "Step 2: Starting AGW..."
source "$HELPERS_DIR/start_agw.sh" "test-worker-1"

# Wait for initialization
sleep 2

# Submit job via AGX
log_info "Step 3: Submitting simple job..."
JOB_FILE="$FIXTURES_DIR/simple-job.json"

# NOTE: This command structure is placeholder and will need to be updated
# based on final AGX CLI interface for job submission
# Expected: agx submit <job.json> --agq-addr <addr> --session-key <key>
# Returns: job_id

JOB_ID=$(cat "$JOB_FILE" | jq -r '.job_id')
log_info "Submitting job: $JOB_ID"

# TODO: Replace with actual AGX submission command once AGX-009 is done
# For now, this is a placeholder that shows the expected interface
if ! "$AGX_BIN" job submit \
    --file "$JOB_FILE" \
    --agq-addr "127.0.0.1:$TEST_PORT" \
    --session-key "$TEST_SESSION_KEY" \
    >/dev/null 2>&1; then
    log_error "Job submission failed"
    "$HELPERS_DIR/cleanup.sh"
    exit 1
fi

log_info "Job submitted: $JOB_ID"

# Wait for job completion
log_info "Step 4: Waiting for job to complete..."
if ! source "$HELPERS_DIR/wait_for_status.sh" "$JOB_ID" 30; then
    log_error "Job did not complete successfully"
    log_error "AGQ log:"
    tail -20 "$AGQ_LOG" >&2
    log_error "AGW log:"
    tail -20 "$AGW_LOG" >&2
    "$HELPERS_DIR/cleanup.sh"
    exit 1
fi

# Verify output
log_info "Step 5: Verifying job output..."

# TODO: Replace with actual AGX query command
# Expected: agx job stdout <job-id> --agq-addr <addr> --session-key <key>
STDOUT=$("$AGX_BIN" job stdout "$JOB_ID" \
    --agq-addr "127.0.0.1:$TEST_PORT" \
    --session-key "$TEST_SESSION_KEY" 2>/dev/null || echo "")

EXPECTED="hello world"

if [[ "$STDOUT" == "$EXPECTED" ]]; then
    log_info "✅ Output matches expected: '$EXPECTED'"
else
    log_error "❌ Output mismatch"
    log_error "Expected: '$EXPECTED'"
    log_error "Got: '$STDOUT'"
    "$HELPERS_DIR/cleanup.sh"
    exit 1
fi

# Cleanup
log_info "Step 6: Cleanup..."
"$HELPERS_DIR/cleanup.sh"

echo ""
log_info "========================================"
log_info "✅ Test 1 PASSED"
log_info "========================================"
exit 0
