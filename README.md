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
| 3 | `BOUNDED_QUEUE[A]` / `BINARY_HEAP[K: ORD]` | FIFO / heap-order invariants, size preservation, extract-min correctness | Planned |
| 4 | `MAX_SUBARRAY` | Divide-and-conquer or Kadane sum >= every contiguous slice, witness bounds | Planned |
| 5 | `MERGE_SORT` / `QUICKSORT` | Sortedness + multiset preservation on `SEQ` / `LIST` | Planned |

## Verifying and Running Tests

From `c:\home\Learn\Gardel` (auto-discovers the repo's bundled Z3 if `z3` is not on `PATH`):

```powershell
./firulete/test.ps1
```

Or run `gardelc` directly once `z3` is on `PATH` (or `Z3_EXE` is set):

```powershell
# Add the bundled Z3 directory to PATH for this session:
$z3Dir = (Resolve-Path gardelc/tools/dafny/z3/bin).Path
$env:PATH = "$z3Dir;$env:PATH"

# Strict verification of the library (fails on any error, warning, or assume):
gardelc --project firulete --strict

# Verify and execute the test suite covering all verified algorithms:
gardelc --project firulete/tests --strict --run

# Machine-readable diagnostics for autonomous AI repair loops:
gardelc --project firulete --strict --json-diagnostics

# Inspect public contract interface (Eiffel `short` view):
gardelc --inspect firulete/src/insertion_sort.gdl
```

The test harness lives in `tests/` (`Gardel.toml` + `tests/src/firulete_test.gdl`). Every new algorithm module added under `src/` should have corresponding test cases added in `tests/src/firulete_test.gdl`.

## Spec Review Checklist

Before marking any module complete:
- Does `ensure` rule out trivial implementations (e.g. returning an empty list for sort, or `None` for search)?
- Are numeric overflow and division-by-zero checks satisfied without weakening inputs unnaturally?
- Are all inductive lemmas proved (`check ... end`) with zero `assume` blocks?
- Does `gardelc --project firulete --strict` exit `0` with `0 errors, 0 warnings`?

