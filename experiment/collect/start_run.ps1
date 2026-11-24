<#
.SYNOPSIS
    Starts one experiment run with the dedicated run configuration and records it in runs.csv.

.DESCRIPTION
    Called from C:\ABAP-Experiment as   .\start_run.ps1 -RunId B3
    (pilot runs: -RunId PB1). The script

    1. sets CLAUDE_CONFIG_DIR for its own process only and restores the
       previous value when it ends;
    2. compares claude-config\settings.json with kit\claude-config\settings.json
       and restores the kit's file if they differ (reported on screen and in
       the notes column);
    3. checks that no CLAUDE.md, CLAUDE.local.md or .claude\CLAUDE.md exists
       in the run folder or above it, except the condition's own
       runs\[P\]<condition>\CLAUDE.md (conditions B and C, identical to the
       kit's file), and that claude-config\ holds no CLAUDE.md;
    4. checks that eval\prompts\<RunId>.txt exists, copies it into the run
       folder as TASK.md and checks that the copy is byte-identical (K20;
       the run folder must be empty before the copy);
    5. writes model, claude --version and the start time into eval\runs.csv
       (every field quoted, UTF-8 without byte order mark);
    6. starts claude in the run folder with the fixed model,
       --permission-mode dontAsk (the option is checked in claude --help first)
       and the initial message
       "Read TASK.md in this folder and carry out the task in it exactly."
       (positional [prompt] argument of claude; the session stays interactive);
    7. after claude exits, writes the end time, an end reason chosen from a
       menu, the number of "Decide yourself." answers and optional notes.

    T1 runs and pilot runs are refused: they used the pasted prompt (K20).

    -DryRun does every check, copies the prompt into a temporary folder as
    TASK.md, compares the copy, deletes the temporary folder and stops. It
    changes nothing: settings.json is compared but not restored, runs.csv is
    not written, claude is not started (only claude --help is read).

    -RepairOnly rewrites eval\runs.csv with the same CSV writer and starts
    nothing. It also splits rows that were saved as one quoted field.

    Windows PowerShell 5.1 syntax. Written for the experiment kit; check it
    on your machine before the first run (it was not executed when written).

.EXAMPLE
    .\start_run.ps1 -RunId B3
.EXAMPLE
    .\start_run.ps1 -RunId B3 -DryRun
.EXAMPLE
    .\start_run.ps1 -RepairOnly
#>
[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Run')]
    [ValidatePattern('^P?[ABC][1-6]$')]
    [string]$RunId,

    [Parameter(ParameterSetName = 'Run')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Repair')]
    [switch]$RepairOnly,

    [string]$Root = 'C:\ABAP-Experiment',

    [string]$Model = 'claude-opus-5-5'
)

$ErrorActionPreference = 'Stop'

$Columns = @('run_id', 'condition', 'task', 'folder', 'model', 'claude_code_version',
             'start_time', 'end_time', 'end_reason', 'questions_answered', 'notes')
$RunsCsv = Join-Path $Root 'eval\runs.csv'
# K20: the same initial message for every run; no double quotes in it (Windows PowerShell 5.1 argument passing)
$InitialMessage = 'Read TASK.md in this folder and carry out the task in it exactly.'

function ConvertTo-CsvLine([string[]]$Values) {
    ($Values | ForEach-Object { '"' + ([string]$_).Replace('"', '""') + '"' }) -join ','
}

function Read-Runs {
    if (-not (Test-Path -LiteralPath $RunsCsv)) { return @() }
    $rows = @()
    foreach ($row in (Import-Csv -LiteralPath $RunsCsv -Encoding UTF8)) {
        $entry = [ordered]@{}
        foreach ($c in $Columns) {
            $value = $null
            if ($row.PSObject.Properties[$c]) { $value = $row.$c }
            if ($null -eq $value) { $value = '' }
            $entry[$c] = [string]$value
        }
        # A row saved as one quoted field: everything sits in run_id.
        if ($entry['run_id'].Contains(',') -and -not $entry['condition'] -and -not $entry['folder']) {
            $parts = $entry['run_id'].Split([char[]]@(','), $Columns.Count)
            for ($i = 0; $i -lt $Columns.Count; $i++) {
                if ($i -lt $parts.Count) { $entry[$Columns[$i]] = $parts[$i] } else { $entry[$Columns[$i]] = '' }
            }
        }
        $rows += , $entry
    }
    return $rows
}

function Write-Runs($Rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add((ConvertTo-CsvLine $Columns))
    foreach ($r in $Rows) { $lines.Add((ConvertTo-CsvLine ($Columns | ForEach-Object { $r[$_] }))) }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($RunsCsv, (($lines -join "`n") + "`n"), $utf8)
}

function Set-RunRow($Rows, [string]$Id, [hashtable]$Values) {
    $found = $null
    foreach ($r in $Rows) { if ($r['run_id'] -eq $Id) { $found = $r } }
    if ($null -eq $found) {
        $found = [ordered]@{}
        foreach ($c in $Columns) { $found[$c] = '' }
        $found['run_id'] = $Id
        $Rows += , $found
    }
    foreach ($k in $Values.Keys) { $found[$k] = [string]$Values[$k] }
    return , $Rows
}

function Add-Note($Rows, [string]$Id, [string]$Note) {
    foreach ($r in $Rows) {
        if ($r['run_id'] -eq $Id) {
            if ($r['notes']) { $r['notes'] = $r['notes'] + '; ' + $Note } else { $r['notes'] = $Note }
        }
    }
}

if ($RepairOnly) {
    $rows = @(Read-Runs)
    Write-Runs $rows
    Write-Host "runs.csv rewritten with quoted fields: $RunsCsv ($($rows.Count) rows)"
    return
}

# --- run identity --------------------------------------------------------
$RunId = $RunId.ToUpperInvariant()
$pilot = $RunId.StartsWith('P')
$condition = $RunId.Substring($RunId.Length - 2, 1)
$task = 'T' + $RunId.Substring($RunId.Length - 1, 1)
if ($pilot) { $conditionDir = Join-Path $Root "runs\P\$condition" } else { $conditionDir = Join-Path $Root "runs\$condition" }
$runDir = Join-Path $conditionDir $RunId
$configDir = Join-Path $Root 'claude-config'
$kitDir = Join-Path $Root 'kit'
$promptFile = Join-Path $Root "eval\prompts\$RunId.txt"

if ($pilot -or $task -eq 'T1') { throw "$RunId used the pasted prompt (T1 and pilot runs; K20). This version starts T2-T6 runs only." }
if (-not (Test-Path -LiteralPath $runDir -PathType Container)) { throw "Run folder missing: $runDir" }
# must stay before the copy of TASK.md
if (@(Get-ChildItem -LiteralPath $runDir -Force).Count -gt 0) { throw "Run folder is not empty: $runDir" }
if (-not (Test-Path -LiteralPath $promptFile -PathType Leaf)) { throw "Prompt file missing: $promptFile" }

$projectName = ($runDir -replace '[^A-Za-z0-9]', '-')
$projectDir = Join-Path $configDir "projects\$projectName"
if (Test-Path -LiteralPath $projectDir) { throw "A transcript folder for this run exists already ($projectDir). A run is never started twice." }

$rows = @(Read-Runs)
foreach ($r in $rows) {
    if ($r['run_id'] -eq $RunId -and $r['start_time']) { throw "runs.csv has a start time for $RunId already." }
}

$notes = New-Object System.Collections.Generic.List[string]
$previousConfigDir = $env:CLAUDE_CONFIG_DIR

try {
    # 1. configuration directory for this process only
    $env:CLAUDE_CONFIG_DIR = $configDir

    # 2. settings.json
    $kitSettings = Join-Path $kitDir 'claude-config\settings.json'
    $runSettings = Join-Path $configDir 'settings.json'
    $same = (Test-Path -LiteralPath $runSettings) -and
            ((Get-FileHash -LiteralPath $kitSettings).Hash -eq (Get-FileHash -LiteralPath $runSettings).Hash)
    if (-not $same -and $DryRun) {
        Write-Warning "claude-config\settings.json differs from the kit's file; a real run would restore it (dry run: not restored)."
    } elseif (-not $same) {
        Copy-Item -LiteralPath $kitSettings -Destination $runSettings -Force
        Write-Warning "claude-config\settings.json differed from the kit's file and was restored."
        $notes.Add('settings.json restored from kit by start_run.ps1')
    } else {
        Write-Host 'settings.json: identical to the kit.'
    }

    # 3. context files
    $allowed = $null
    if ($condition -ne 'A') {
        $allowed = Join-Path $conditionDir 'CLAUDE.md'
        $kitContext = Join-Path $kitDir "conditions\$condition\CLAUDE.md"
        if (-not (Test-Path -LiteralPath $allowed)) { throw "Condition file missing: $allowed" }
        if ((Get-FileHash -LiteralPath $allowed).Hash -ne (Get-FileHash -LiteralPath $kitContext).Hash) {
            throw "$allowed differs from $kitContext"
        }
    }
    $found = @()
    $dir = Get-Item -LiteralPath $runDir
    while ($null -ne $dir) {
        foreach ($name in @('CLAUDE.md', 'CLAUDE.local.md', '.claude\CLAUDE.md')) {
            $candidate = Join-Path $dir.FullName $name
            if ((Test-Path -LiteralPath $candidate) -and ($candidate -ne $allowed)) { $found += $candidate }
        }
        $dir = $dir.Parent
    }
    foreach ($name in @('CLAUDE.md', 'CLAUDE.local.md')) {
        $candidate = Join-Path $configDir $name
        if (Test-Path -LiteralPath $candidate) { $found += $candidate }
    }
    if ($found.Count -gt 0) { throw ("Unexpected context files: " + ($found -join ', ')) }
    Write-Host "Context files: OK (condition $condition)."

    # 5a. the permission option must exist in this version
    $help = (& claude --help) -join "`n"
    if ($help -notmatch '--permission-mode' -or $help -notmatch 'dontAsk') {
        throw 'claude --help lists no --permission-mode option with the value dontAsk; stop and update the protocol.'
    }
    if ($help -notmatch '\[prompt\]') {
        throw 'claude --help shows no positional [prompt] argument; stop and update the protocol.'
    }
    Write-Host 'claude --help: --permission-mode dontAsk and [prompt] available.'

    # 4. TASK.md (K20): byte-identical copy of the prompt file
    $promptHash = (Get-FileHash -LiteralPath $promptFile).Hash
    if ($DryRun) {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("start_run_dry_" + $RunId + "_" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            $tempTask = Join-Path $tempDir 'TASK.md'
            Copy-Item -LiteralPath $promptFile -Destination $tempTask
            if ((Get-FileHash -LiteralPath $tempTask).Hash -ne $promptHash) { throw "Copy of $promptFile is not byte-identical." }
            Write-Host "TASK.md: copy into $tempDir is byte-identical (SHA256 $promptHash)."
        } finally {
            Remove-Item -LiteralPath $tempDir -Recurse -Force
        }
        Write-Host ''
        Write-Host "Dry run $RunId passed. A real run would start in $runDir with:"
        Write-Host ('  claude --model ' + $Model + ' --permission-mode dontAsk "' + $InitialMessage + '"')
        Write-Host 'Nothing was changed.'
        return
    }
    $taskFile = Join-Path $runDir 'TASK.md'
    Copy-Item -LiteralPath $promptFile -Destination $taskFile
    if ((Get-FileHash -LiteralPath $taskFile).Hash -ne $promptHash) { throw "TASK.md in $runDir is not byte-identical to $promptFile." }
    Write-Host "TASK.md: copied to $runDir, byte-identical."

    # 5. runs.csv: model, version, start time
    $version = ((& claude --version) -join ' ').Trim()
    $start = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $rows = Set-RunRow $rows $RunId @{
        condition = $condition; task = $task; folder = $runDir
        model = $Model; claude_code_version = $version; start_time = $start
    }
    foreach ($n in $notes) { Add-Note $rows $RunId $n }
    Write-Runs $rows
    Write-Host "runs.csv: $RunId started $start, $version, model $Model."

    # 6. start the session with the initial message (do not paste anything)
    Write-Host ''
    Write-Host 'The session starts with the message to read TASK.md. Do not paste anything.'
    Write-Host 'Answer a question only with "Decide yourself." (count it).'
    Write-Host 'Never press Shift+Tab during a run: it changes the permission mode.'
    Write-Host ''
    Push-Location -LiteralPath $runDir
    try {
        & claude --model $Model --permission-mode dontAsk $InitialMessage
    } finally {
        Pop-Location
    }

    # 7. end of run
    $end = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $reasons = @{ '1' = 'done'; '2' = 'cap'; '3' = 'timeout'; '4' = 'other' }
    do {
        $choice = Read-Host 'End reason: 1 done (object list given), 2 cap (5 failed activations), 3 timeout (60 min), 4 other'
    } until ($reasons.ContainsKey($choice))
    do {
        $questions = Read-Host 'How often did you answer "Decide yourself."? (number)'
    } until ($questions -match '^\d+$')
    $extra = Read-Host 'Notes (optional; no system names, user names or tokens)'

    $rows = @(Read-Runs)
    $rows = Set-RunRow $rows $RunId @{ end_time = $end; end_reason = $reasons[$choice]; questions_answered = $questions }
    if ($extra) { Add-Note $rows $RunId $extra }
    Write-Runs $rows
    Write-Host "runs.csv: $RunId ended $end, $($reasons[$choice])."
} finally {
    if ($null -eq $previousConfigDir) {
        Remove-Item Env:\CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
    } else {
        $env:CLAUDE_CONFIG_DIR = $previousConfigDir
    }
}
