<#
.SYNOPSIS
    Starts the evaluation session in eval\ with the normal Claude Code configuration.

.DESCRIPTION
    Called as   C:\ABAP-Experiment\kit\collect\eval_start.ps1
    Refuses to start when CLAUDE_CONFIG_DIR is set for this process, for the
    user or for the machine: the evaluation must run in the normal
    configuration (it runs acceptance tests and ATC, which the run
    configuration denies, and it must not write into the run configuration's
    history). Then it creates eval\results\ if needed and starts claude in
    eval\.

    Windows PowerShell 5.1 syntax; not executed when written.
#>
param(
    [string]$Root = 'C:\ABAP-Experiment'
)

$ErrorActionPreference = 'Stop'

$scopes = @{
    'process' = $env:CLAUDE_CONFIG_DIR
    'user'    = [Environment]::GetEnvironmentVariable('CLAUDE_CONFIG_DIR', 'User')
    'machine' = [Environment]::GetEnvironmentVariable('CLAUDE_CONFIG_DIR', 'Machine')
}
$set = @($scopes.Keys | Where-Object { $scopes[$_] })
if ($set.Count -gt 0) {
    Write-Error ("CLAUDE_CONFIG_DIR is set (" + ($set -join ', ') + "). Open a new window without it; the evaluation runs in the normal configuration.")
    exit 1
}

$evalDir = Join-Path $Root 'eval'
if (-not (Test-Path -LiteralPath $evalDir -PathType Container)) { throw "Evaluation folder missing: $evalDir" }
$resultsDir = Join-Path $evalDir 'results'
if (-not (Test-Path -LiteralPath $resultsDir)) { New-Item -ItemType Directory -Path $resultsDir | Out-Null }

Write-Host 'CLAUDE_CONFIG_DIR: not set. Starting the evaluation session in eval\.'
Write-Host 'Paste kit\collect\evaluation-prompt.md with the placeholders filled, one run at a time.'
Push-Location -LiteralPath $evalDir
try {
    & claude
} finally {
    Pop-Location
}
