# Verify `firulete` and run `firulete/tests` with automatic Z3 discovery.
param(
    [switch]$JsonDiagnostics
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

Write-Host "[1/2] Verifying firulete (--strict)..." -ForegroundColor Cyan
if ($JsonDiagnostics) {
    gardelc --project $firuleteDir --strict --json-diagnostics
} else {
    gardelc --project $firuleteDir --strict
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/2] Verifying and running firulete/tests (--strict --run)..." -ForegroundColor Cyan
if ($JsonDiagnostics) {
    gardelc --project $testsDir --strict --run --json-diagnostics
} else {
    gardelc --project $testsDir --strict --run
}
exit $LASTEXITCODE

