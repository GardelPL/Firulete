# Firulete

> Verified classic algorithms and data structures in **Gardel**, inspired by [AutoCLRS](https://risemsr.github.io/blog/2026-03-06-autoclrs/).

Firulete treats the AutoCLRS catalog as a prioritized roadmap—not a line-by-line port of F*/Pulse—reimplemented in idiomatic, pure, total Gardel with Hoare-style contracts discharged statically by Boogie/Z3.

## Core Principles

1. **Idiomatic Gardel first**: Pure functions, algebraic representations, structural/arithmetic `variant` termination metrics, and `ORD` / `EQ` / `CANONICAL_EQ` concept bounds.
2. **Specification quality is the primary bottleneck**: Proofs are mechanically checked; every module must be audited so contracts capture full functional correctness (e.g., sortedness **and** multiset preservation, not sortedness alone).
3. **Zero trust escapes**: Everything in `firulete` must verify under `gardelc --strict` (no `assume` blocks, no `--bounded-check`).
4. **Clean-room algorithmic provenance**: Implement algorithms from standard public algorithmic knowledge (citing CLRS where relevant for the algorithm name/idea); do not copy protected text or pseudocode.

## Verified Catalog

| # | Module | Target Properties | Status |
| :--- | :--- | :--- | :--- |
| 1 | `INSERTION_SORT[K: ORD]` (`src/insertion_sort.gdl`) | Sortedness (`is_sorted`), length preservation, multiset preservation (`sort_count`) | Verified (`--strict`) |
| 2 | `BINARY_SEARCH[K: ORD]` (`src/binary_search.gdl`) | Bounds safety (`lo + (hi - lo) / 2`), found index matches target, `None` implies target absent | Verified (`--strict`) |
| 3 | `BINARY_HEAP[K: ORD]` (`src/binary_heap.gdl`) | Persistent heap-ordered binary tree with skew-heap `merge`: heap order kept by `insert` / `merge` / `delete_min` / `from_list`, ghost `size` and `count_of` bookkeeping (`delete_min` removes exactly one minimum); `find_min` least under congruence | Verified (`--strict`) |
| 3b | `BOUNDED_QUEUE[A]` (`src/bounded_queue.gdl`) | Persistent batched (two-list) FIFO queue: type invariant `size <= capacity`, `enqueue` appends to / `dequeue` drops the head of / `peek` returns the head of the ghost model `contents`, `enqueue` requires `not is_full`, capacity kept | Verified (`--strict`) |
| 4 | `MAX_SUBARRAY` (`src/max_subarray.gdl`) | Kadane scan over `LIST[I64]`: witness `0 <= lo < hi <= length` with `sum = seg(xs, lo, hi)` (ghost `MATH_INT` slice sum), and the law `maximal`: every non-empty slice sum `<= sum`; no `I64` overflow under `fits` | Verified (`--strict`) |
| 5 | `MERGE_SORT[K: ORD]` (`src/merge_sort.gdl`) | Adjacent sortedness, length and multiset preservation (`forall y` counts, in `sort`'s own contract); full `INSERTION_SORT.is_sorted` under `equals`/`less_than` congruence | Verified (`--strict`) |
| 6 | `QUICKSORT[K: ORD]` (`src/quicksort.gdl`) | Full `INSERTION_SORT.is_sorted` for **every** `ORD` (no congruence needed), length and multiset preservation (`forall y` counts) in `sort`'s own contract | Verified (`--strict`) |
| 7 | `MIN_MAX[K: ORD]` (`src/min_max.gdl`) | `minimum` / `maximum`: an element of the list (`count_of >= 1`) that no element is below (`all_ge`) / above (`all_le`), for every `ORD` | Verified (`--strict`) |
| 8 | `SIMULTANEOUS_MIN_MAX[K: ORD]` (`src/simultaneous_min_max.gdl`) | Pairwise scan (3n/2 comparisons): `lo` and `hi` are elements for every `ORD`; least / greatest under congruence | Verified (`--strict`) |
| 9 | `BOUNDED_STACK[A]` (`src/bounded_stack.gdl`) | LIFO against the ghost model `contents`, type invariant `size <= capacity`, `push` requires `not is_full` | Verified (`--strict`) |
| 10 | `GCD` (`src/gcd.gdl`) | Euclid (subtraction form): `gcd` divides both inputs, the law `greatest` (every common divisor divides it), Bezout's identity with ghost `MATH_INT` coefficients | Verified (`--strict`) |
| 11 | `NAIVE_STRING_MATCH[A: EQ]` (`src/naive_string_match.gdl`) | Exactly the matching shifts (`forall s` counts against `occurs_at`), in increasing order | Verified (`--strict`) |
| 12 | `LINKED_LIST_OPS[A: EQ]` (`src/linked_list_ops.gdl`) | `insert` / `search` (first match, `None` iff absent) / `delete` (first match) with exact `forall y` counts | Verified (`--strict`) |
| 13 | `HEAPSORT[K: ORD]` (`derived/src/heapsort.gdl`) | `BINARY_HEAP.from_list` then `BINARY_HEAP.drain`: permutation and length for every `ORD`, sortedness under congruence | Verified (`--strict`) |

## Roadmap (from AutoCLRS)

The [AutoCLRS](https://risemsr.github.io/blog/2026-03-06-autoclrs/) catalog ([code](https://github.com/FStarLang/AutoCLRS)) covers 52 algorithms and data structures in 22 CLRS chapters. Entries already in the verified table are not repeated. AutoCLRS works on mutable arrays and pointers (Pulse). Firulete is pure, so array and pointer algorithms become persistent versions over `LIST`, trees and `MAP`, as `BINARY_HEAP` and `BOUNDED_QUEUE` already are. Complexity bounds are out of scope everywhere, as for the verified modules.

Tiers:
- **T1**: fits the existing list and ordering infrastructure. Next up.
- **T2**: needs a new persistent structure or a dynamic-programming recurrence as the spec.
- **T3**: needs a graph, flow or geometry model first (shared `GRAPH` spec module, exact integer geometry).
- **Covered** / **N/A**: already handled by a verified module, or meaningless without mutation.
- **Blocked**: waits on a verifier limitation.

| CLRS | Module (planned) | Target Properties | Tier |
| :--- | :--- | :--- | :--- |
| §4.1 | `MAX_SUBARRAY_DC` | Divide-and-conquer result equals the maximum slice sum (cross-checked against `MAX_SUBARRAY`'s `seg` / `maximal`) | T1 |
| §4.2 | `MATRIX_MULTIPLY` | `LIST[LIST[I64]]` matrices: dimensions, every entry `C[i][j] = sum_k A[i][k] * B[k][j]` (ghost `MATH_INT`), overflow bound | T2 |
| §4.2 | `STRASSEN` | Equals `MATRIX_MULTIPLY` on `2^k` square matrices | T3 |
| §7.1 | `QUICKSORT.below` / `at_or_above` | Partition: bounds and multiset (`partition_parts`) | Covered |
| §8.2 | `COUNTING_SORT` | `NAT` keys below a bound `k`: sorted, permutation, **stable** (records with equal keys keep input order) | T1 |
| §8.3 | `RADIX_SORT` | Digit-wise stable passes give a sorted permutation (lexicographic digit lemma) | T2 |
| §8.4 | `BUCKET_SORT` | Sorted permutation via per-bucket sorts and concatenation | T2 |
| §9.2 | `QUICKSELECT[K: ORD]` | Result is the `k`-th element of `sort(xs)` (`k` elements below / not above); reuses `QUICKSORT`'s partition | T1 |
| §9.2 | `PARTIAL_SELECTION_SORT[K: ORD]` | First `k` outputs are sorted, permutation kept, the `k`-th is the `k`-th smallest | T1 |
| §10.2 | Doubly linked list | Pointer segments have no pure analogue | N/A |
| §11.4 | `HASH_TABLE[K: KEY, V]` | Persistent buckets (chaining instead of linear probing): `get` after `put` / `remove`, like `MAP`'s laws | T2 |
| §12.1–3 | `BST[K: ORD]` | Persistent BST: search-tree invariant, key set (ghost `count_of`) after `insert` / `delete`, `search` sound and complete (array-based variant N/A) | T2 |
| §13.1–4 | `RB_TREE[K: ORD]` | Okasaki-style insert: BST invariant, red-black invariants (no red-red, equal black height), key set; delete as a stretch goal | T2 |
| §15.1 | `ROD_CUTTING` | Bottom-up table equals the optimal-revenue recurrence; returned cut list achieves it | T2 |
| §15.2 | `MATRIX_CHAIN` | Table equals the minimum-cost recurrence; parenthesization achieves it | T2 |
| §15.4 | `LCS[K: EQ]` | Length equals the LCS recurrence; returned list is a common subsequence of that length | T2 |
| §16.1 | `ACTIVITY_SELECTION` | Greedy selection is pairwise compatible and of maximum size (exchange argument) | T2 |
| §16.3 | `HUFFMAN` | Prefix-free code tree over the symbols with minimum weighted path length | T3 |
| §21.3 | `UNION_FIND` | Persistent forest (`MAP` of parents): `find` returns a root, `union` merges exactly the two classes, `same_set` is an equivalence | T2 |
| §22.2 | `BFS` | Distances are shortest edge counts; parent tree is consistent | T3 |
| §22.3 | `DFS` | Discovery/finish timestamps nest (parenthesis theorem); edge classification | T3 |
| §22.4 | `TOPOLOGICAL_SORT` | Kahn's order is a permutation of the vertices with every edge forward; cycle reported otherwise | T3 |
| §23.1 | `MST_THEORY` | Cut property (light edge across a cut is safe) | T3 |
| §23.2 | `KRUSKAL` | Result is a spanning forest of minimum weight (via `UNION_FIND` and the cut property) | T3 |
| §23.2 | `PRIM` | Spanning tree of minimum weight; keys correct | T3 |
| §24.1 | `BELLMAN_FORD` | Shortest-path distances, or a negative cycle detected | T3 |
| §24.3 | `DIJKSTRA` | Non-negative weights: distances equal shortest paths; predecessor tree is a shortest-path tree | T3 |
| §25.2 | `FLOYD_WARSHALL` | All-pairs distances equal shortest paths through intermediate vertices `< k` | T3 |
| §26.2 | `EDMONDS_KARP` | Result is a valid flow and maximum (no augmenting path / min-cut equality) | T3 |
| §31.6 | `MOD_EXP` | Repeated squaring: result `= b^e mod m` against a ghost power, no overflow (`m` bounded) | Blocked: `%` by a variable is unprovable (see Compiler Limitations); partial proof in `wip/mod_exp.gdl` |
| §32.2 | `RABIN_KARP` | Same match set as naive; hash collisions rechecked | T2 |
| §32.4 | `KMP[A: EQ]` | Prefix-function correctness; same match set as naive | T2 |
| §33.1 | `SEGMENTS` | Exact `I64` cross products (overflow-bounded): orientation and intersection test correct | T3 |
| §33.3 | `GRAHAM_SCAN` | Output is convex (all left turns) and contains every input point | T3 |
| §33.3 | `JARVIS_MARCH` | Same hull guarantees as Graham scan | T3 |
| §35.1 | `VERTEX_COVER_APPROX` | Result covers every edge and is at most twice an optimal cover (maximal matching bound) | T3 |

AutoCLRS leaves out chapters that hold only mathematical background, and randomized and multithreaded algorithms. Firulete follows the same scope.

## Verifying and Running Tests

From the directory that contains both `firulete/` and `gardelc/` (`test.ps1` auto-discovers the repo's bundled Z3 if `z3` is not on `PATH`):

```powershell
./firulete/test.ps1                          # verify library and derived, prove spec tests, run all suites
./firulete/test.ps1 binary_search            # same, but run only the named suite(s)
./firulete/test.ps1 -JsonDiagnostics         # machine-readable verifier output for repair loops
```

Output is one line per suite (`PASS insertion_sort`, `FAIL binary_search (case 7)`, `SKIP …`). Exit code `0` means everything passed, `1` means a suite failed, and `2` means no suite matched the filter. Any verification failure stops the script with the verifier's exit code.

Or run `gardelc` directly once `z3` is on `PATH` (or `Z3_EXE` is set):

```powershell
$env:PATH = "$((Resolve-Path gardelc/tools/dafny/z3/bin).Path);$env:PATH"
gardelc --project firulete --strict                   # the library
gardelc --project firulete/derived --strict           # algorithms built on library structures
gardelc --project firulete/tests --strict --run       # spec tests + all run tests
gardelc --inspect firulete/src/insertion_sort.gdl     # public contract (Eiffel `short` view)
```

## Package Layout

- `firulete/` (`src/`): the library.
- `firulete/derived/` (`src/`): algorithms built on a library data structure, e.g. `HEAPSORT` on `BINARY_HEAP`. A separate package depends on `firulete` and so sees its modules **through their contracts only**. Inside one package the solver also sees function bodies, and unfolding `drain` through `from_list` / `merge` did not finish; across the package boundary the same proof takes seconds.
- `firulete/tests/`: the spec and run tests (depends on both).
- `firulete/wip/`: unverified work in progress, in no package.

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
  Gardel.toml                 # depends on firulete (path "..") and firulete-derived (path "../derived")
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
    min_max_test.gdl          # functions MIN_MAX_TEST (and likewise for the suites below)
    simultaneous_min_max_test.gdl
    bounded_stack_test.gdl
    gcd_test.gdl
    naive_string_match_test.gdl
    linked_list_ops_test.gdl
    heapsort_test.gdl         # tests `derived/` (1500-element cross-check against QUICKSORT)
    test_data.gdl             # functions TEST_DATA: generated inputs (`scrambled`, `ascending`)
```

### Adding tests for a new algorithm

1. Create `tests/src/<algo>_test.gdl` declaring `functions <ALGO>_TEST`.
2. Add **spec tests**: at least one concrete `check` per public routine, plus one universal routine per headline guarantee (e.g. sorted **and** permutation; found **and** absent).
3. Add **run tests** in `run: NAT`: empty, singleton, already-processed input, the worst case (e.g. reverse sorted), duplicates, negatives/boundaries, and at least two `K` instantiations (e.g. `I64` plus `STRING`). Number the cases `1..n` locally and return `0` on success.
4. Register the suite in `main` of `tests/src/firulete_test.gdl` by adding its `wanted`, `rc`, `failed` and `print_line` lines, and its name to the "known suites" message.
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

- `SIMULTANEOUS_MIN_MAX`'s least / greatest clauses need the congruence hypothesis, and this is inherent to the pairwise trick: with `a`, `b` tied (neither less), `b < lo` and `a` tied with `lo`, the pair step keeps `a` as the pair's minimum and so keeps `lo`. `MIN_MAX` compares every element with the running minimum and needs no hypothesis. `spec_bounds_i64` discharges it.
- `HEAPSORT.sort`'s sortedness inherits `BINARY_HEAP.find_min`'s congruence hypothesis (`spec_sorted_i64` discharges it); permutation and length are unconditional.
- `GCD` uses Euclid's subtraction form, so it takes up to `max(a, b)` steps instead of `O(log)`, and its Bezout coefficients are ghost (`MATH_INT`), not computed at run time. Both follow from the `%` limitation below.
- `NAIVE_STRING_MATCH.matches`, `LINKED_LIST_OPS.search` and `HEAPSORT.sort` require `length < 2^64` (`addressable`): the verifier does not know that a list's length fits in `NAT`. The requirement holds for every list that fits in memory.
- `MOD_EXP` is not verified (Roadmap: Blocked).

## Compiler Limitations Hit (worked around)

- `.equals` on an `OPTION` returned by a generic module's feature (e.g. `heap.find_min.equals(Some(2))`) fails verifier translation (`E0199`, undeclared `fn_equals`). Compare with a `match` helper instead (`BINARY_HEAP_TEST.holds_i64`).
- A local annotation naming the module's own generic type inside a feature (`let one: BINARY_HEAP[K] = …`) verifies, but breaks the C backend ("used at `K`, which does not satisfy ORD"). Leave the type to inference.
- A representation field named `first` (or `second`) collides with the verifier's tuple accessors (`E0199`: "invalid type for argument 0 in application of Tuple2_first"). Pick other names (`MAX_SUBARRAY` uses `from_ix` / `upto_ix`).
- In generic code, an unannotated `let one = LIST.empty.prepend(x)` is typed `LIST[int]` by the verifier (`E0199`, "cannot assign Seq A to int"), while the annotated `let one: LIST[A] = …` breaks the C backend (as above). Use a small helper with a typed signature (`BOUNDED_QUEUE.single(x): LIST[A]`).
- `%` (and `/`) by a variable is effectively unprovable: even `x % m = x` for `x < m` times out (`wip/percent_repro.gdl` is a minimal reproduction for an upstream report). By a constant (`e % 2`) it is fine. Workarounds: subtraction-based definitions (`GCD.divides`) and remainders carried with a ghost quotient (`wip/mod_exp.gdl`).
- A routine returning `TUPLE[...]` gets no postcondition axiom, so neither callers nor its own recursive calls see its `ensure`. Return a small result record instead (`SIMULTANEOUS_MIN_MAX` is its own result type, with `lo` / `hi`).
- The `.equals` failure above also hits values read from a generic module's result in run code (e.g. `MIN_MAX.minimum(strs).equals("a")`), and a negative literal compared with such a value (`minimum(xs) != -1`) cannot be typed. Compare through a typed helper (`MIN_MAX_TEST.same_str`, `same_i64`).
- A `NAT` read out of an `OPTION` (`o.get`) is not known to be non-negative in a client. State `0 <= Result.get` in the contract (`LINKED_LIST_OPS.search`).
- A list's `length` is not known to be below `2^64`, so passing it as a `NAT` argument needs the `addressable` precondition (see Known Spec Gaps).
- `STRING.chars` is ghost-only (no C code), so run tests cannot turn a string into a list; use number lists.
- A lemma with `require` clauses publishes no `ensure` axiom; state its hypotheses as an implication (`GUIDE.md` section 9). And a contract is trusted only once its own proof succeeds, so a lemma's timeout makes every client of it fail.
