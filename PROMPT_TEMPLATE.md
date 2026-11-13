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
- **Avoid `forall q` bound-preservation clauses on recursive routines that call themselves on derived lists** (e.g. `forall q. all_lt(q, xs) implies all_lt(q, sort(xs))`): they send Z3 into a matching loop (QUICKSORT timed out even at 100M rlimit). Prove them per `q` in a lemma, and when the routine itself needs the lemma, put both in one mutual-recursion group with lexicographic variants: `sort` uses `xs.length, 0`, and the lemma, which mentions `sort(ys)`, uses `ys.length, 1`. `forall y` count clauses (`count_of(y, Result) = ...`) did not loop and are fine.
- **Keep `f(xs.tail)` out of `f`'s own contract.** A clause like `scan(xs).sum >= scan(xs.tail).sum` in `scan`'s `ensure` makes the solver unfold `scan` down the whole list (timeout, even in unrelated callers). Put such one-step facts in a separate lemma (`MAX_SUBARRAY.scan_step`) and call it where a proof needs it.
- **Publish a two-index `forall` as a triggered law.** A `forall i. forall j.` clause cannot be proved from a per-`(i, j)` lemma inside the module (nested quantifiers give the outer one no trigger), and a module's own laws are not visible to its own routines. Prove the per-`(i, j)` lemma, then export `law maximal(xs, i, j) trigger seg(xs, i, j) do lemma(xs, i, j) ensure ... end` in `specify {ANY}`: clients get the fact wherever `seg(xs, i, j)` appears (as `LIST_OPS.at_append` does).
- **Build large modules incrementally**: when trivial routines time out, a heavy axiom elsewhere in the module is to blame. Strip back to the core, verify (seconds), and add one layer at a time. Spell out a failing lemma's proof as tagged `check` steps (`unfold_*`, `step_*`) to locate the gap.
- **Bound machine-integer inputs explicitly** when a result sums them (e.g. `fits`: length `<= 10^6`, elements in `[-10^12, 10^12]`), carry `|value| <= B * length` clauses through the recursion, and keep the specification sums in ghost `MATH_INT`.
- **State `>= 0` on ghost `MATH_INT` measures** (`size`, `count_of`) explicitly; nothing else says they are non-negative.
- **Keep heavy hypotheses and arithmetic out of widely used contracts.** A congruence hypothesis in a clause of `drain`, or `count_of >= 0` on `INSERTION_SORT.count_of`, entered every client proof and made unrelated proofs (`HEAPSORT.sort`, `QUICKSORT.sort`) fail under some Z3 seeds. Put such facts in separate lemmas (`BINARY_HEAP.drain_sorted`, `MIN_MAX.count_nonneg`) and call them where needed.
- **Make polynomial lemma conclusions match the goal's terms.** For a step like Bezout's, pass the target terms as arguments (`bez_step(a, b, x, y, cx, cy, g)` concluding `a * cx + b * cy = g`) so the solver need not rewrite products; a lemma over intermediate names made it seed-fragile.
- **Algorithms built on a library data structure go in `firulete/derived/`**, a separate package that sees the structure through its contracts only (see README "Package Layout"). Inside one package the solver unfolds the structure's bodies and can loop.
- **Avoid `%` and `/` by a variable** (see README "Compiler Limitations"); use subtraction-based definitions or a ghost quotient.
- **Return a record, not a `TUPLE`**, from routines whose `ensure` matters.
- **Check robustness:** verify with `--verify-deps` (uncached) and `--z3-seed 1`, `2`, `3`; every module must pass all of them.
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
3. Update `firulete/README.md`: add a row to "Verified Catalog", remove the module's row from "Roadmap", and update "Known Spec Gaps" if needed.
4. Summarize the proved specification clauses and flag any assumptions or preconditions for human spec review.
```

