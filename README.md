# Firulete

> Verified classic algorithms and data structures in **Gardel**, inspired by [AutoCLRS](https://risemsr.github.io/blog/2026-03-06-autoclrs/).

Firulete treats the AutoCLRS catalog as a prioritized roadmap—not a line-by-line port of F*/Pulse—reimplemented in idiomatic, pure, total Gardel with Hoare-style contracts discharged statically by Boogie/Z3.

## Core Principles

1. **Idiomatic Gardel first**: Pure functions, algebraic representations, structural/arithmetic `variant` termination metrics, and `ORD` / `EQ` / `CANONICAL_EQ` concept bounds.
2. **Specification quality is the primary bottleneck**: Proofs are mechanically checked; every module must be audited so contracts capture full functional correctness (e.g., sortedness **and** multiset preservation, not sortedness alone).
3. **Zero trust escapes**: Everything in `firulete` must verify under `gardelc --strict` (no `assume` blocks, no `--bounded-check`).
4. **Clean-room algorithmic provenance**: Implement algorithms from standard public algorithmic knowledge (citing CLRS where relevant for the algorithm name/idea); do not copy protected text or pseudocode.

## Prioritized Initial Catalog

| Priority | Module | Target Properties | Status |
| :--- | :--- | :--- | :--- |
| 1 | `INSERTION_SORT[K: ORD]` (`src/insertion_sort.gdl`) | Sortedness (`is_sorted`), length preservation, multiset preservation (`sort_count`) | Verified (`--strict`) |
| 2 | `BINARY_SEARCH[K: ORD]` (`src/binary_search.gdl`) | Bounds safety (`lo + (hi - lo) / 2`), found index matches target, `None` implies target absent | Verified (`--strict`) |
| 3 | `BINARY_HEAP[K: ORD]` (`src/binary_heap.gdl`) | Persistent heap-ordered binary tree with skew-heap `merge`: heap order kept by `insert` / `merge` / `delete_min` / `from_list`, ghost `size` and `count_of` bookkeeping (`delete_min` removes exactly one minimum); `find_min` least under congruence | Verified (`--strict`) |
| 3b | `BOUNDED_QUEUE[A]` (`src/bounded_queue.gdl`) | Persistent batched (two-list) FIFO queue: type invariant `size <= capacity`, `enqueue` appends to / `dequeue` drops the head of / `peek` returns the head of the ghost model `contents`, `enqueue` requires `not is_full`, capacity kept | Verified (`--strict`) |
| 4 | `MAX_SUBARRAY` (`src/max_subarray.gdl`) | Kadane scan over `LIST[I64]`: witness `0 <= lo < hi <= length` with `sum = seg(xs, lo, hi)` (ghost `MATH_INT` slice sum), and the law `maximal`: every non-empty slice sum `<= sum`; no `I64` overflow under `fits` | Verified (`--strict`) |
| 5 | `MERGE_SORT[K: ORD]` (`src/merge_sort.gdl`) | Adjacent sortedness, length and multiset preservation (`forall y` counts, in `sort`'s own contract); full `INSERTION_SORT.is_sorted` under `equals`/`less_than` congruence | Verified (`--strict`) |
| 6 | `QUICKSORT[K: ORD]` (`src/quicksort.gdl`) | Full `INSERTION_SORT.is_sorted` for **every** `ORD` (no congruence needed), length and multiset preservation (`forall y` counts) in `sort`'s own contract | Verified (`--strict`) |

## Verifying and Running Tests

From `c:\home\Learn\Gardel` (auto-discovers the repo's bundled Z3 if `z3` is not on `PATH`):

```powershell
./firulete/test.ps1                          # verify library, prove spec tests, run all suites
./firulete/test.ps1 binary_search            # same, but run only the named suite(s)
./firulete/test.ps1 -JsonDiagnostics         # machine-readable verifier output for repair loops
```

Output is one line per suite (`PASS insertion_sort`, `FAIL binary_search (case 7)`, `SKIP …`). Exit code `0` means everything passed, `1` means a suite failed, and `2` means no suite matched the filter. Any verification failure stops the script with the verifier's exit code.

Or run `gardelc` directly once `z3` is on `PATH` (or `Z3_EXE` is set):

```powershell
$env:PATH = "$((Resolve-Path gardelc/tools/dafny/z3/bin).Path);$env:PATH"
gardelc --project firulete --strict                   # the library
gardelc --project firulete/tests --strict --run       # spec tests + all run tests
gardelc --inspect firulete/src/insertion_sort.gdl     # public contract (Eiffel `short` view)
```

## Testing Model

In a verified library, the proof already shows that the code meets its contract. What it cannot show is whether the contract says what we *meant*. Each algorithm's tests therefore check the contract as well as the code, in two layers.

`tests/` is a separate package that depends on `firulete`, so it **sees only contracts, never bodies**.

| Layer | Where | Checked by | What it catches |
| :--- | :--- | :--- | :--- |
| **Spec tests** (`spec_*` routines) | `tests/src/<algo>_test.gdl` | `gardelc --strict` at compile time | Contracts too weak to be useful: a client cannot derive the expected answer from the published `ensure` clauses (e.g. `sort([3,1,2]) = [1,2,3]`, `search` finds a present key), or a helper the spec relies on is opaque |
| **Run tests** (`run: NAT`) | `tests/src/<algo>_test.gdl` | Native executable (`--run` / `test.ps1`) | Code generation / runtime bugs, unsatisfiable or awkward preconditions, and plain examples for readers |

Spec tests come in two shapes:
- **Concrete**: `check` that the contract alone determines a specific output. If a contract only promised sortedness (and not the multiset), `spec_sort_concrete` would fail.
- **Universal**: a `BOOL` routine whose `ensure` restates the guarantee a client needs (e.g. `spec_none_is_absent`: `None` implies the target is at no index). The routine shows that the guarantee can be used from outside the module, including any hints a client must supply.

Layout:

```
tests/
  Gardel.toml                 # depends on firulete = { path = ".." }
  src/
    firulete_test.gdl         # program FIRULETE_TEST: runs suites, filters by name, reports
    test_list.gdl             # TEST_LIST[A: EQ]: shared helpers (`same`, `has`)
    insertion_sort_test.gdl   # functions INSERTION_SORT_TEST: spec_* + run
    binary_search_test.gdl    # functions BINARY_SEARCH_TEST: spec_* + run
    merge_sort_test.gdl       # functions MERGE_SORT_TEST: spec_* + run (1500-element cross-check)
    quicksort_test.gdl        # functions QUICKSORT_TEST: spec_* + run (worst-case ascending input)
    binary_heap_test.gdl      # functions BINARY_HEAP_TEST: spec_* + run (heapsort drain cross-check)
    bounded_queue_test.gdl    # functions BOUNDED_QUEUE_TEST: spec_* + run (1500-element fill/drain, interleaved churn)
    max_subarray_test.gdl     # functions MAX_SUBARRAY_TEST: spec_* + run (O(n^2) brute-force cross-check)
    test_data.gdl             # functions TEST_DATA: generated inputs (`scrambled`, `ascending`)
```

### Adding tests for a new algorithm

1. Create `tests/src/<algo>_test.gdl` declaring `functions <ALGO>_TEST`.
2. Add **spec tests**: at least one concrete `check` per public routine, plus one universal routine per headline guarantee (e.g. sorted **and** permutation; found **and** absent).
3. Add **run tests** in `run: NAT`: empty, singleton, already-processed input, the worst case (e.g. reverse sorted), duplicates, negatives/boundaries, and at least two `K` instantiations (e.g. `I64` plus `STRING`). Number the cases `1..n` locally and return `0` on success.
4. Register the suite in `main` of `tests/src/firulete_test.gdl` by adding its `wanted`, `rc`, `failed` and `print_line` lines.
5. Check that the tests can fail: temporarily break one expected value in a spec test and one in a run test, and confirm that `test.ps1` fails.

## Spec Review Checklist

Before marking any module complete:
- Does `ensure` rule out trivial implementations (e.g. returning an empty list for sort, or `None` for search)?
- Are numeric overflow and division-by-zero checks satisfied without weakening inputs unnaturally?
- Are all inductive lemmas proved (`check ... end`) with zero `assume` blocks?
- Does every spec predicate a client needs (e.g. `count_of`, `is_sorted`) carry `ensure` clauses that characterize it? Bodies are invisible to dependents.
- Do the suite's spec tests prove concrete outputs from the contract alone?
- Does `./firulete/test.ps1` exit `0`?

## Known Spec Gaps (to revisit)

- `INSERTION_SORT.sort`'s own `ensure` states sortedness and length. Multiset preservation lives in the separate lemma `sort_count`, which a client must call (see `spec_sort_is_permutation`).
- `MERGE_SORT.sort` proves full sortedness (`INSERTION_SORT.is_sorted`) only under the `equals`/`less_than` congruence hypothesis. Unconditionally it proves `adjacent_sorted`. This is not a proof weakness: the `ORD` laws don't link `equals` to `less_than`, and for a non-congruent `ORD` instance merging two equivalent heads can really produce output where a later element is less than an earlier one. `spec_sorted_i64` shows a client discharging the hypothesis. A future `ORD` law tying `equals` to `less_than` would remove this gap and the two below.
- `BINARY_HEAP.find_min` is proved not greater than every element only under the same congruence hypothesis, for the same reason (a root can sit above an "equal" child that has a strictly smaller descendant). Unconditionally, `is_heap` is the local parent/child order. `spec_min_is_least_i64` shows a client discharging the hypothesis.
- `BINARY_SEARCH`'s completeness clauses take an `equals`/`less_than` congruence hypothesis. A client using them on a concrete list has to state that fact for `I64` and give an `LIST_OPS.at` hint (see `spec_search_concrete`).

- `MAX_SUBARRAY.of` requires `fits(xs)`: at most 1,000,000 elements, each in [-10^12, 10^12], so every slice sum fits in `I64`. This is a deliberate input bound, not a proof gap (an unbounded version would need `BIGNAT`-style arithmetic). Maximality is published as the triggered law `maximal`, not as a `forall i. forall j.` clause in `of`'s `ensure` (see the template idiom); clients use it with no hints (`spec_optimal`).

## Compiler Limitations Hit (worked around)

- `.equals` on an `OPTION` returned by a generic module's feature (e.g. `heap.find_min.equals(Some(2))`) fails verifier translation (`E0199`, undeclared `fn_equals`). Compare with a `match` helper instead (`BINARY_HEAP_TEST.holds_i64`).
- A local annotation naming the module's own generic type inside a feature (`let one: BINARY_HEAP[K] = …`) verifies, but breaks the C backend ("used at `K`, which does not satisfy ORD"). Leave the type to inference.
- A representation field named `first` (or `second`) collides with the verifier's tuple accessors (`E0199`: "invalid type for argument 0 in application of Tuple2_first"). Pick other names (`MAX_SUBARRAY` uses `from_ix` / `upto_ix`).
- In generic code, an unannotated `let one = LIST.empty.prepend(x)` is typed `LIST[int]` by the verifier (`E0199`, "cannot assign Seq A to int"), while the annotated `let one: LIST[A] = …` breaks the C backend (as above). Use a small helper with a typed signature (`BOUNDED_QUEUE.single(x): LIST[A]`).
