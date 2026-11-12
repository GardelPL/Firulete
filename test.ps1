# Verify `firulete`, prove the spec tests in `firulete/tests`, then run the run tests.
#
#   ./firulete/test.ps1                                # all suites
#   ./firulete/test.ps1 insertion_sort binary_search   # only the named suites
#   ./firulete/test.ps1 -JsonDiagnostics               # machine-readable verifier output
#
# Spec tests are always proved for every suite (the verifier checks the whole package); the
# suite names only filter which run tests execute.
param(
    [switch]$JsonDiagnostics,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Suites = @()
)

$ErrorActionPreference = "Stop"

$firuleteDir = $PSScriptRoot
$repoRoot = Split-Path -Parent $firuleteDir
$testsDir = Join-Path $firuleteDir "tests"

function Resolve-Z3 {
    if ($env:Z3_EXE -and (Test-Path $env:Z3_EXE)) {
        return (Resolve-Path $env:Z3_EXE).Path
    }
    $cmd = Get-Command "z3" -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    $candidates = @(
        (Join-Path $repoRoot "gardelc\tools\dafny\z3\bin\z3.exe"),
        (Join-Path $repoRoot "tools\dafny\z3\bin\z3.exe"),
        (Join-Path $repoRoot "gardelc\tools\dafny\z3\bin\z3"),
        (Join-Path $repoRoot "tools\dafny\z3\bin\z3")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw "Z3 executable not found. Install Z3 on PATH, set Z3_EXE, or run gardelc/scripts/install_tools.ps1."
}

$z3Exe = Resolve-Z3
$z3Dir = Split-Path -Parent $z3Exe
$env:Z3_EXE = $z3Exe
if ($env:PATH -notlike "*$z3Dir*") {
    $env:PATH = "$z3Dir;$env:PATH"
}

# gardelc writes progress to stderr; in Windows PowerShell 5.1 "Stop" would turn that into a
# terminating error. Failures are detected through $LASTEXITCODE below instead.
$ErrorActionPreference = "Continue"

$flags = @("--strict")
if ($JsonDiagnostics) { $flags += "--json-diagnostics" }

Push-Location $firuleteDir
try {
    Write-Host "[1/3] Verifying the firulete library (--strict)..." -ForegroundColor Cyan
    gardelc --project $firuleteDir @flags
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "[2/3] Proving spec tests and building firulete/tests (--strict)..." -ForegroundColor Cyan
    # Never run a binary left over from an earlier (possibly failed) build.
    $exe = Join-Path $firuleteDir "build\firulete_test_bin.exe"
    if (Test-Path $exe) { Remove-Item $exe -Force }
    gardelc --project $testsDir @flags
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if ($JsonDiagnostics) {
        # `--json-diagnostics` verifies but does not build; build once more (cached proofs, fast).
        gardelc --project $testsDir --strict | Out-Null
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    Write-Host "[3/3] Running run tests..." -ForegroundColor Cyan
    if (-not (Test-Path $exe)) { Write-Host "Test executable not found at $exe" -ForegroundColor Red; exit 3 }
    & $exe @Suites
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
