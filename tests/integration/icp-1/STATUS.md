# ICP-1 Integration Checkpoint - Status

**Last Updated:** 2025-11-18
**Status:** 🟡 Partially Complete (Blocked on AGX)

---

## Summary

ICP-1 validates the minimal viable integration between AGX, AGQ, and AGW. As of 2025-11-18:

- ✅ **AGQ** - Schema aligned, validates and stores plans correctly
- ✅ **AGW** - Connects to AGQ and authenticates successfully
- ✅ **Test Infrastructure** - Fixtures and helpers updated and working
- 🚧 **AGX** - Job submission CLI commands not yet implemented (blocked)

---

## What's Working

### AGQ (Queue Manager)
- ✅ Schema alignment complete (AGQ-019)
- ✅ Validates plans using canonical schema:
  - `task_number` (not `id`)
  - `command` (not `tool`)
  - `args`, `timeout_secs`, `input_from_task`
- ✅ `PLAN.SUBMIT` endpoint working
- ✅ Successfully stores plans in redb

**Test Result:**
```bash
$ python3 test_plan_submit.py
AUTH Response: +OK
PLAN.SUBMIT Response: plan_72dcaee3519b4edc90f0f5c47210eadc
```

### AGW (Worker)
- ✅ Connects to AGQ on startup
- ✅ Authenticates with session key
- ✅ Sends heartbeat messages
- ✅ Graceful shutdown implemented (AGW-009)

**Test Result:**
```
AGW v0.1.0 starting...
Initializing worker with ID: test-worker-1
Connected to AGQ at 127.0.0.1:6379
```

### Test Infrastructure
- ✅ Fixtures use canonical schema (`simple-job.json`, `pipeline-job.json`, etc.)
- ✅ Helper scripts updated for current CLI:
  - `start_agq.sh` - Uses `--bind` instead of `--port`
  - `start_agw.sh` - Uses `--agq-address` instead of `--agq-addr`
  - `config.sh` - Fixed session key sharing issue
- ✅ Cleanup scripts working

---

## What's Blocked

### AGX (Planner/Orchestrator)
The ICP-1 tests expect AGX to provide job submission and query commands:

**Required commands (not yet implemented):**
```bash
# Submit a job to AGQ
agx job submit --file <job.json> --agq-addr <addr> --session-key <key>

# Query job output
agx job stdout <job-id> --agq-addr <addr> --session-key <key>

# Query job status
agx job status <job-id> --agq-addr <addr> --session-key <key>
```

**Blocked on:**
- AGX-045: Echo model integration (plan generation)
- AGX-046: Delta model integration (plan validation)

---

## Test Results

### Current State (2025-11-18)

```bash
$ ./run_all.sh
========================================
Tests Run:    3
Tests Passed: 0
Tests Failed: 3
========================================

All tests fail at "Job submission failed" because AGX job submission
commands don't exist yet.
```

**Failure point:** Line 48 of `test_1_simple_job.sh`
```bash
if ! "$AGX_BIN" job submit \
    --file "$JOB_FILE" \
    --agq-addr "127.0.0.1:$TEST_PORT" \
    --session-key "$TEST_SESSION_KEY" \
    >/dev/null 2>&1; then
    log_error "Job submission failed"  # ← Tests fail here
```

---

## Next Steps

### 1. Complete AGX Integration (Priority: High)
- [ ] AGX-045: Implement Echo model for plan generation
- [ ] AGX-046: Implement Delta model for plan validation
- [ ] Add AGX CLI commands:
  - `agx job submit`
  - `agx job status`
  - `agx job stdout`

### 2. Run Full ICP-1 Test Suite
Once AGX is ready:
```bash
cd /Users/lewis/work/agenix-sh/agenix/tests/integration/icp-1
./run_all.sh
```

Expected flow:
1. AGX reads job JSON → submits to AGQ via `PLAN.SUBMIT`
2. AGQ stores plan → assigns to AGW
3. AGW executes tasks → reports results to AGQ
4. AGX queries AGQ for job status and output
5. Tests verify output matches expected results

### 3. Deploy to DGX (After ICP-1 Passes)
Validate the full stack on Nvidia DGX infrastructure.

---

## Known Issues

### Fixed
- ✅ Schema mismatch (AGQ-019) - AGQ now uses canonical schema
- ✅ CLI argument mismatch - Helper scripts updated
- ✅ Session key mismatch - Fixed in config.sh

### Outstanding
- 🚧 AGX job submission commands missing (blocked on AGX-045, AGX-046)

---

## Files Modified

**Agenix Repository:**
- `tests/integration/icp-1/helpers/config.sh` - Fixed session key
- `tests/integration/icp-1/helpers/start_agq.sh` - Updated to `--bind`
- `tests/integration/icp-1/helpers/start_agw.sh` - Updated to `--agq-address`

**AGQ Repository:**
- `src/server.rs` - Schema validation updated (AGQ-019)
- `CLAUDE.md` - Replaced embedded schemas with canonical references

**AGW Repository:**
- `CLAUDE.md` - Replaced embedded nomenclature with canonical references

**AGX Repository:**
- `CLAUDE.md` - Fixed canonical documentation paths

---

## Contact

For questions about ICP-1 status:
- Schema issues: See `agenix/specs/README.md` and `agenix/docs/architecture/job-schema.md`
- AGQ issues: Open issue in `agenix-sh/agq` repository
- AGW issues: Open issue in `agenix-sh/agw` repository
- AGX issues: Open issue in `agenix-sh/agx` repository (focus on AGX-045, AGX-046)
