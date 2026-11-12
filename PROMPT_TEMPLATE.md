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
  If a property genuinely needs congruence (e.g. full sortedness after `merge` takes from two equivalent heads), prove an unconditional weaker form (e.g. `adjacent_sorted`) and the full form as `<congruence hypothesis> implies ...`, then record it under README "Known Spec Gaps".
- **Write quantified hypotheses in guarded form** (as in `BINARY_SEARCH` / `MERGE_SORT`): `forall a: K. (a.equals(a) implies (forall b: K. (b.equals(b) implies (forall c: K. ...))))`. Unguarded nested `forall a. forall b. forall c.` gives Z3 no trigger and cannot be used. To apply the hypothesis to concrete elements `x`, `z`, first state `check refl_x: x.equals(x)  refl_z: z.equals(z) end` so the guards fire.
- **No parameterless ghost predicates in generic modules**: a `specify` query gets an implicit `Current` argument, and a static query must mention `K` in its arguments (Boogie: "type variable must occur in function arguments"). Inline the formula in each clause instead.
- **Reuse the shared spec predicates** (`INSERTION_SORT.is_sorted`, `INSERTION_SORT.count_of`) for sorting algorithms, so every sort is specified against the same notion of sortedness and multiset.
- **Zero `assume` blocks.**

- **Publish `ensure` clauses on every spec predicate** (`count_of`, `is_sorted`, …) that characterize it (empty/cons cases). The test package sees contracts only, so a predicate without them is opaque to every client.

### Tests (see README "Testing Model")
Create `firulete/tests/src/<module_name>_test.gdl` declaring `functions <MODULE_NAME>_TEST`, with:
- **Spec tests** (`spec_*`, proved statically from contracts only): a concrete `check` per public routine (e.g. `sort([3,1,2]) = [1,2,3]`) and a universal routine per headline guarantee. If one fails, strengthen the module's contract. Do not weaken the test.
- **Run tests** (`run: NAT`, returns `0` or the first failing case number): empty, singleton, already-processed input, worst case, duplicates, boundaries, and at least two `K` instantiations.
- Register the suite in `main` of `firulete/tests/src/firulete_test.gdl`.
- Check that the tests can fail: break one spec expectation and one run expectation, confirm each fails, then restore them.

### Verification Loop
Run (from `c:\home\Learn\Gardel`):
```powershell
./firulete/test.ps1 -JsonDiagnostics <module_name>
```
Iterate on counterexamples and failed VCs until both verification steps print `[]` and the run step prints `PASS <module_name>` with exit code `0`.

### Deliverable
1. `firulete/src/<module_name>.gdl`
2. `firulete/tests/src/<module_name>_test.gdl`, registered in `firulete_test.gdl`.
3. Update `firulete/README.md` catalog table (and "Known Spec Gaps" if any).
4. Summarize the proved specification clauses and flag any assumptions or preconditions for human spec review.
```

