# ICP-1 Integration Checkpoint - Status

**Last Updated:** 2025-11-18
**Status:** 🟡 Blocked on Action Layer Implementation

---

## Summary

ICP-1 validates the minimal viable integration between AGX, AGQ, and AGW. As of 2025-11-18:

- ✅ **AGX** - Schema aligned, `PLAN submit` working
- ✅ **AGQ** - Schema aligned, validates and stores plans correctly
- ✅ **AGW** - Connects to AGQ and authenticates successfully
- ✅ **Test Infrastructure** - Fixtures and helpers updated and working
- 🚧 **Action Layer** - ACTION.SUBMIT not yet implemented (blocked)

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

### Action Layer (AGX + AGQ)

The ICP-1 tests incorrectly tried to skip from Plan → Job execution directly. The correct flow requires the **Action layer**:

**Correct workflow:**
```
1. AGX: PLAN submit (store Plan template in AGQ)
2. AGX: ACTION submit (Plan + data inputs → creates Jobs)
3. AGQ: Fan out Action → N Jobs, enqueue to workers
4. AGW: Pull Job, execute Plan with data
5. AGX: Query results
```

**Current implementation status:**
- ✅ Step 1: `PLAN submit` working (AGX-054 completed)
- ❌ Step 2: `ACTION submit` not implemented (AGX-055)
- ❌ Step 3: `ACTION.SUBMIT` handler missing in AGQ (AGQ-020)
- ❌ Step 3: Job dispatch to workers not implemented
- ❌ Step 4: Workers connect but receive no jobs
- ❌ Step 5: Job status queries not implemented

**Blocked on:**
- **AGQ-020:** Implement ACTION.SUBMIT (job fan-out, queue management)
- **AGX-055:** Implement ACTION submit command

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

### 1. Implement Action Layer (Priority: High)

**AGQ-020: ACTION.SUBMIT in AGQ**
- [ ] Add `actions` and `jobs` tables to redb
- [ ] Implement ACTION.SUBMIT RESP handler
- [ ] Fan out Action → N Jobs (1 per input)
- [ ] Enqueue jobs to `queue:ready`
- [ ] Implement BRPOP for workers to pull jobs
- [ ] Track job status (pending → assigned → running → completed/failed)

**AGX-055: ACTION submit in AGX**
- [ ] Add `agx ACTION submit` CLI command
- [ ] Accept --plan-id, --input, --inputs-file flags
- [ ] Send ACTION.SUBMIT payload to AGQ
- [ ] Display action_id and job_ids

### 2. Update ICP-1 Tests
Once Action layer is implemented:
- [ ] Update test scripts to use ACTION.SUBMIT workflow
- [ ] Test fixtures should specify data inputs
- [ ] Tests verify: Plan → Action → Jobs → Results

### 3. Run Full ICP-1 Test Suite
```bash
cd /Users/lewis/work/agenix-sh/agenix/tests/integration/icp-1
./run_all.sh
```

Expected flow:
1. AGX: Generate Plan, submit to AGQ (`PLAN submit`)
2. AGX: Submit Action with data (`ACTION submit --input {...}`)
3. AGQ: Create Job from Plan + input, enqueue to workers
4. AGW: Pull Job via BRPOP, execute tasks with data
5. AGW: Report results to AGQ
6. AGX: Query job status and output
7. Tests verify output matches expected results

### 4. Deploy to DGX (After ICP-1 Passes)
Validate the full stack on Nvidia DGX infrastructure.

---

## Known Issues

### Fixed
- ✅ Schema mismatch (AGQ-019) - AGQ now uses canonical schema
- ✅ AGX schema alignment (AGX-054) - AGX generates canonical schema
- ✅ CLI argument mismatch - Helper scripts updated
- ✅ Session key mismatch - Fixed in config.sh
- ✅ PLAN.SUBMIT working - Plans stored successfully in AGQ

### Outstanding
- 🚧 ACTION.SUBMIT not implemented in AGQ (AGQ-020)
- 🚧 ACTION submit command not in AGX (AGX-055)
- 🚧 Job dispatch mechanism missing
- 🚧 Worker job pulling (BRPOP) not implemented
- 🚧 Job status tracking not implemented

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
