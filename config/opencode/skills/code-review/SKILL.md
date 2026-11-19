---
name: Code Review
description: Audit diffs, PRs, or modules for correctness bugs, security risks, race conditions, and maintainability issues
---

## Review Checklist
1. **Correctness & Edge Cases:** null/undefined handling, off-by-one bounds, empty inputs, async error propagation, stale closures, resource cleanup.
2. **Security:** injection (shell, SQL, XSS, template), path traversal, hardcoded credentials, overly permissive file/network access, missing auth/permission checks.
3. **Concurrency & State:** race conditions, double-execution, missing idempotency, leaked timers/listeners/processes.
4. **Performance:** N+1 queries, unnecessary re-renders, blocking main/UI threads, unbounded memory/cache growth.
5. **Consistency:** adherence to local project conventions, types, naming, and existing helper utilities.

## Output Format
Group findings by severity (`Critical`, `Important`, `Suggestion`), citing exact `file:line` references and concrete fixes rather than vague advice.
