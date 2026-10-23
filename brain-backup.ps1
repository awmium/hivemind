# Syncs every ~/.claude/projects/*/memory/ into the Brain and keeps its history.
# Runs from the SessionEnd hook in ~/.claude/settings.json.
#   projects\  true mirror of each project's auto-memory: current truth only
#   archive\   append-only history, never pruned: every note the mirror drops or overwrites, and every
#              deleted or changed note in the hand-written folders (global\, ...), saved as
#              "<note> (deleted|replaced YYYY-MM-DD).md" and logged in archive\archive-log.txt
#   .state\    last-seen copy of the hand-written folders, used only to detect their changes
# Nothing is deleted or overwritten until its previous version is safely in archive\.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

# --- configure ---------------------------------------------------------------
param(
    [string]$BrainRoot    = 'C:\CHANGE-ME\Brain',   # your Brain folder (ideally inside OneDrive)
    [string]$ProjectsRoot = (Join-Path $env:USERPROFILE '.claude\projects')
)

$ErrorActionPreference = 'SilentlyContinue'

# Optional: readable mirror folder names. Key = the raw folder name under
# ~\.claude\projects\ (the sanitized project path); value = the name you want.
# Unknown projects fall back to their raw name.
$friendlyNames = @{
    # 'd--Repos-My-Client-Project' = 'my-client-project'
}
# ------------------------------------------------------------------------------

$mirrorRoot  = Join-Path $BrainRoot 'projects'
$archiveRoot = Join-Path $BrainRoot 'archive'
$stateRoot   = Join-Path $BrainRoot '.state'
$logFile     = Join-Path $archiveRoot 'archive-log.txt'
$today       = Get-Date -Format 'yyyy-MM-dd'
$script:archived = 0

function Save-ToArchive([string]$file, [string]$rel, [string]$archiveDir, [string]$verb) {
    try {
        $dir = [IO.Path]::Combine($archiveDir, [IO.Path]::GetDirectoryName($rel))
        New-Item -ItemType Directory -Force -Path $dir -ErrorAction Stop | Out-Null
        $stem   = [IO.Path]::GetFileNameWithoutExtension($rel)
        $ext    = [IO.Path]::GetExtension($rel)
        $target = Join-Path $dir "$stem ($verb $today)$ext"
        $n = 2
        while (Test-Path -LiteralPath $target) { $target = Join-Path $dir "$stem ($verb $today #$n)$ext"; $n++ }
        Copy-Item -LiteralPath $file -Destination $target -ErrorAction Stop
        Add-Content -LiteralPath $logFile -Value "$today  $verb  $($target.Substring($archiveRoot.Length + 1))"
        $script:archived++
        return $true
    } catch { return $false }
}

# Archives every file in $old that is missing from $new or differs from it ($new = '' archives all).
# MEMORY.md rewrites are skipped: it is an index that changes with every new memory.
function Save-Changes([string]$new, [string]$old, [string]$archiveDir) {
    if (-not (Test-Path -LiteralPath $old)) { return $true }
    $ok   = $true
    $base = (Get-Item -LiteralPath $old).FullName.TrimEnd('\')
    foreach ($f in Get-ChildItem -LiteralPath $base -File -Recurse -Force) {
        $rel = $f.FullName.Substring($base.Length + 1)
        $cur = if ($new) { [IO.Path]::Combine($new, $rel) } else { '' }
        if (-not $cur -or -not (Test-Path -LiteralPath $cur)) {
            if (-not (Save-ToArchive $f.FullName $rel $archiveDir 'deleted')) { $ok = $false }
        } elseif ($f.Name -ne 'MEMORY.md') {
            $a = (Get-FileHash -LiteralPath $f.FullName).Hash
            $b = (Get-FileHash -LiteralPath $cur).Hash
            if ($a -and $b -and $a -ne $b) {
                if (-not (Save-ToArchive $f.FullName $rel $archiveDir 'replaced')) { $ok = $false }
            }
        }
    }
    return $ok
}

# 1. Mirror each project's memory, archiving what the mirror is about to drop or overwrite
$synced = @()
foreach ($proj in Get-ChildItem -LiteralPath $ProjectsRoot -Directory) {
    if ($proj.Name -match '-worktrees-') { continue }
    $mem = Join-Path $proj.FullName 'memory'
    if (-not (Test-Path -LiteralPath $mem)) { continue }
    if (-not (Get-ChildItem -LiteralPath $mem -File -Recurse | Select-Object -First 1)) { continue }

    $key  = $proj.Name
    $name = $friendlyNames[$key]
    if (-not $name) {
        $match = $friendlyNames.Keys | Where-Object { $_ -ieq $key } | Select-Object -First 1
        $name = if ($match) { $friendlyNames[$match] } else { $key }
    }

    $dest = Join-Path $mirrorRoot $name
    if (Save-Changes $mem $dest (Join-Path $archiveRoot "projects\$name")) {
        robocopy $mem $dest /MIR /R:1 /W:1 /NP /NJH /NJS | Out-Null
    }
    $synced += $name
}

# 2. Mirrors whose project is gone or has no memories left: archive, then remove.
#    Skipped when nothing synced, so an unreadable projects root never empties the mirror.
if ($synced.Count -gt 0) {
    foreach ($dir in Get-ChildItem -LiteralPath $mirrorRoot -Directory) {
        if ($synced -contains $dir.Name) { continue }
        if (Save-Changes '' $dir.FullName (Join-Path $archiveRoot "projects\$($dir.Name)")) {
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force
        }
    }
}

# 3. Hand-written folders (global/, awmium/, ...): archive what changed since the last run
$skip    = @('projects', 'archive')
$curated = @(Get-ChildItem -LiteralPath $BrainRoot -Directory | Where-Object { $_.Name -notlike '.*' -and $skip -notcontains $_.Name } | ForEach-Object Name)
$seen    = @(Get-ChildItem -LiteralPath $stateRoot -Directory -Force | ForEach-Object Name)
foreach ($name in @($curated + $seen | Sort-Object -Unique)) {
    $live = $curated -contains $name
    $src  = if ($live) { Join-Path $BrainRoot $name } else { '' }
    $snap = Join-Path $stateRoot $name
    if (Save-Changes $src $snap (Join-Path $archiveRoot $name)) {
        if ($live) { robocopy $src $snap /MIR /R:1 /W:1 /NP /NJH /NJS | Out-Null }
        else { Remove-Item -LiteralPath $snap -Recurse -Force }
    }
}

$stamp = Join-Path $BrainRoot 'last-backup.txt'
"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  synced: $($synced -join ', ')  archived: $script:archived" | Set-Content $stamp
exit 0
