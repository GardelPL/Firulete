# Firulete Agent Prompt Template

Use this template when asking an AI agent to formalize a new algorithm or data structure in `firulete/`.

---

```markdown
You are formalizing `<ALGORITHM_NAME>` in idiomatic **Gardel** for the `firulete` project (`c:\home\Learn\Gardel\firulete`).

### Context to Read First
1. Read `gardelc/guide/GUIDE.md` (especially §3 Numerics, §6 Contracts, §9 Termination & Known Limits, §12 Concepts, §15 AI Verification Workflow).
2. Read existing verified examples:
   - `firulete/src/insertion_sort.gdl`
   - `gardelc/stdlib/collections/key_order.gdl`
   - `gardelc/stdlib/collections/seq.gdl`

### Task
Implement `module <MODULE_NAME>` in `firulete/src/<module_name>.gdl` implementing `<ALGORITHM_NAME>` (algorithmic idea from CLRS; write clean-room idiomatic pure Gardel—do not copy book text or pseudocode).

### Required Specification Strength (No Sloppy Specs)
Specify and prove full functional correctness, including:
- `<Property 1, e.g. sortedness / heap order / found element equals target>`
- `<Property 2, e.g. multiset count preservation / absent element proof>`
- Overflow safety and termination (`variant`) on every recursive routine.

### Gardel Verification Idioms (Follow Strictly)
- **Avoid `require` clauses that call recursive functions** on helper/lemma routines (`GUIDE.md` §9): prefer total routines whose `ensure` expresses `hyp implies conclusion` so the SMT solver can unfold definitions cleanly.
- **Name intermediate `LIST` / `SEQ` results with `let`** before chaining `.prepend`, `.append`, `.head`, `.tail`, or `.length` (`GUIDE.md` §9).
- **Use `MATH_INT`** for ghost specification counts/sums that are not bounded by 64-bit machine integers; use `lo + (hi - lo) / 2` for midpoint arithmetic on `NAT`/`I64`.
- **Factor inductive proofs** into separate `BOOL` lemma routines with `ensure holds: Result` and call them in `check <unique_tag>: ... end` blocks (give each `check` item a distinct tag name for precise diagnostics).
- **For `K: ORD`**: remember `ORD` laws (`irreflexive`, `transitive`, `total`) do not automatically equate `equals` with `less_than` congruence; use strict `x.less_than(y)` / `not y.less_than(x)` carefully as in `INSERTION_SORT`.
- **Zero `assume` blocks.**

### Verification Loop
Run:
```powershell
$env:Z3_EXE = (Resolve-Path gardelc/tools/dafny/z3/bin/z3.exe).Path
gardelc --project firulete --strict --json-diagnostics
```
Iterate on counterexamples and failed VCs until the output is `[]` with exit code `0`, and verify `gardelc --project firulete --strict` prints `0 errors, 0 warnings`.

### Deliverable
1. `firulete/src/<module_name>.gdl`
2. Update `firulete/README.md` catalog table.
3. Summarize the proved specification clauses and flag any assumptions or preconditions for human spec review.
```

