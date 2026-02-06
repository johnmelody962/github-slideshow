<#
.SYNOPSIS
    White-label the Delinea Platform documentation for IBM.

.DESCRIPTION
    Processes .htm and .html files under C:\Flare\Platform to:
      1. Replace "Delinea Platform" with <MadCap:variable name="Platform" />
      2. Wrap "Delinea " with a DelineaOnly condition span in these product names:
         - Delinea AD Connector
         - Delinea Authenticator
         - Delinea PRA Engine
         - Delinea SCIM Connector
         - Delinea Support

    Creates a .bak backup of every modified file and writes a change log.

    NOTE: Run this script ONCE per file set. Running it again on already-
    processed files will produce incorrect results (double-wrapping, etc.).

.PARAMETER RootPath
    Root folder of the Flare project. Default: C:\Flare\Platform

.PARAMETER DryRun
    Preview changes without modifying any files.

.EXAMPLE
    .\WhiteLabel-IBM.ps1
    .\WhiteLabel-IBM.ps1 -DryRun
    .\WhiteLabel-IBM.ps1 -RootPath "D:\Projects\Flare\Platform"
#>

param(
    [string]$RootPath = "C:\Flare\Platform",
    [switch]$DryRun
)

# ── Configuration ────────────────────────────────────────────────────────────

$ExcludedFolders = @("ai-chatbot", "INSTRUCTIONS", "iris-ai")

# Product names whose "Delinea " prefix gets the DelineaOnly condition.
# Longer names are listed first so they match before shorter substrings.
$DelineaProductNames = @(
    "Delinea SCIM Connector",
    "Delinea AD Connector",
    "Delinea Authenticator",
    "Delinea PRA Engine",
    "Delinea Support"
)

$BackupSuffix   = ".bak"
$LogFile        = Join-Path $RootPath "white-label-changes.log"
$ConditionSpan  = '<span MadCap:conditions="Default.DelineaOnly">Delinea </span>'
$PlatformVar    = '<MadCap:variable name="Platform" />'

# ── Collect files ────────────────────────────────────────────────────────────

if (-not (Test-Path $RootPath)) {
    Write-Error "Root path not found: $RootPath"
    exit 1
}

$files = Get-ChildItem -Path $RootPath -Recurse -File |
    Where-Object {
        ($_.Extension -eq ".htm" -or $_.Extension -eq ".html") -and
        (-not ($ExcludedFolders | Where-Object { $file = $_; $_.FullName -match "\\$_\\" }))
    }

# Re-filter with a clearer loop to guarantee exclusion works
$filteredFiles = @()
foreach ($f in (Get-ChildItem -Path $RootPath -Recurse -File)) {
    if ($f.Extension -ne ".htm" -and $f.Extension -ne ".html") { continue }

    $skip = $false
    foreach ($excluded in $ExcludedFolders) {
        if ($f.FullName -like "*\$excluded\*") {
            $skip = $true
            break
        }
    }
    if (-not $skip) { $filteredFiles += $f }
}
$files = $filteredFiles

# ── Counters & log header ───────────────────────────────────────────────────

$totalFiles        = $files.Count
$modifiedCount     = 0
$varReplacements   = 0
$condReplacements  = 0

$log = [System.Collections.Generic.List[string]]::new()
$log.Add("White-Label IBM Documentation - Change Log")
$log.Add("Date  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$log.Add("Root  : $RootPath")
$log.Add("Mode  : $(if ($DryRun) {'DRY RUN (no files changed)'} else {'LIVE'})")
$log.Add("=" * 70)

if ($DryRun) {
    Write-Host "=== DRY RUN - no files will be modified ===" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Scanning $totalFiles file(s) (excluding: $($ExcludedFolders -join ', '))..."
Write-Host ""

# ── Process each file ───────────────────────────────────────────────────────

foreach ($file in $files) {

    # Read with encoding detection — preserve BOM if present
    $bytes   = [System.IO.File]::ReadAllBytes($file.FullName)
    $hasBom  = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $enc     = if ($hasBom) {
                   New-Object System.Text.UTF8Encoding($true)
               } else {
                   New-Object System.Text.UTF8Encoding($false)
               }
    $content         = $enc.GetString($bytes)
    $originalContent = $content
    $fileChanges     = @()

    # ── Step 1: Variable replacement ─────────────────────────────────────
    #    "Delinea Platform" → <MadCap:variable name="Platform" />

    $re1     = [regex]"Delinea Platform"
    $hits1   = $re1.Matches($content).Count
    if ($hits1 -gt 0) {
        $content = $re1.Replace($content, $PlatformVar)
        $fileChanges += "  [Variable]   'Delinea Platform' x $hits1 -> Platform variable"
        $varReplacements += $hits1
    }

    # ── Step 2: Condition tagging ────────────────────────────────────────
    #    Wrap "Delinea " in each product name with a conditioned <span>.

    foreach ($name in $DelineaProductNames) {
        $remainder = $name.Substring(8)          # text after "Delinea "
        $re2       = [regex][regex]::Escape($name)
        $hits2     = $re2.Matches($content).Count
        if ($hits2 -gt 0) {
            $replacement = $ConditionSpan + $remainder
            $content     = $re2.Replace($content, $replacement)
            $fileChanges += "  [Condition]  '$name' x $hits2 -> DelineaOnly span"
            $condReplacements += $hits2
        }
    }

    # ── Write back if changed ────────────────────────────────────────────

    if ($content -ne $originalContent) {
        $relativePath = $file.FullName.Substring($RootPath.Length)
        $modifiedCount++

        if (-not $DryRun) {
            # Backup
            $backupPath = $file.FullName + $BackupSuffix
            Copy-Item -Path $file.FullName -Destination $backupPath -Force

            # Write modified content (preserve original encoding / BOM)
            [System.IO.File]::WriteAllText($file.FullName, $content, $enc)
        }

        # Console output
        Write-Host "  $relativePath" -ForegroundColor Cyan
        foreach ($c in $fileChanges) { Write-Host $c }

        # Log
        $log.Add("")
        $log.Add("FILE: $relativePath")
        if (-not $DryRun) { $log.Add("  Backup: $($file.FullName)$BackupSuffix") }
        foreach ($c in $fileChanges) { $log.Add($c) }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

$summary = @(
    "",
    "=" * 70,
    "SUMMARY",
    "=" * 70,
    "Files scanned          : $totalFiles",
    "Files modified         : $modifiedCount",
    "Variable replacements  : $varReplacements  (Delinea Platform -> variable)",
    "Condition tags added   : $condReplacements  (Delinea <name> -> DelineaOnly span)",
    "Backups created        : $(if ($DryRun) {'0 (dry run)'} else {$modifiedCount})",
    "Log file               : $LogFile"
)

foreach ($s in $summary) { $log.Add($s) }

Write-Host ""
foreach ($s in $summary) { Write-Host $s }
Write-Host ""

if (-not $DryRun) {
    $log | Out-File -FilePath $LogFile -Encoding UTF8
    Write-Host "Change log written to: $LogFile" -ForegroundColor Green
} else {
    Write-Host "DRY RUN complete - no files were changed." -ForegroundColor Yellow
}
