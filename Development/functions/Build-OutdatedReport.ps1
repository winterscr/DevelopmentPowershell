# Process outdated functions
function getVersionInfo([string]$version) {
    $null = $version -match "(?'major'\d+)(?:.(?'minor'\d+))?(?:.(?'rev'\d+))?(?:.(?'pre'[-a-zA-z0-9_]+))?"
  
    return $Matches
}
  
function newItem([string] $package, [string] $from, [string]$to) {
    return New-Object PSObject -Property @{Package = $package; Versions = New-Object PSObject -Property @{From = $from; To = $to } }
}
  
function addVersionItems($versions, [string]$item) {
    $null = ($item -match "\s*\*\s*(?'package'[a-zA-Z0-9_.]+) (?'from'[0-9.]+) -> (?'to'[0-9.]+)")
  
    $package = $Matches["package"]
    $from = getVersionInfo $Matches["from"]
    $to = getVersionInfo $Matches["to"]
  
    if ($from.major -ne $to.major) {
        $null = $versions.Major.Add((newItem $package $from[0] $to[0]))
    }
    elseif ($from.minor -ne $to.minor) {
        $null = $versions.Minor.Add((newItem $package $from[0] $to[0]))
    }
    elseif ($from.rev -ne $to.rev) {
        $null = $versions.Rev.Add((newItem $package $from[0] $to[0]))
    }
}
  
  
<#
.synopsis
Build-OutdatedReport takes the output from paket outdated and generates a report from it.
.parameter InFile
The input file generated as the output file from "paket outdated --log-file Outfile"
#>
function Show-OutdatedReport([string] $InFile) {
    $versions = New-Object PSObject -Property @{
        Major = [System.Collections.ArrayList]@();
        Minor = [System.Collections.ArrayList]@();
        Rev   = [System.Collections.ArrayList]@()
    }
    
    Get-Content -Path $Infile | Where-Object { $_ -match "->" } | ForEach-Object { addVersionItems $versions $_ }
  
    Write-Output "Major changes"
    Write-Output "-------------"
    $versions.Major | Sort-Object -Property Package | Get-Unique -AsString
  
    Write-Output ""
    Write-Output "Minor changes"
    Write-Output "-------------"
    $versions.Minor | Sort-Object -Property Package | Get-Unique -AsString
  
    Write-Output ""
    Write-Output "Revision changes"
    Write-Output "-------------"
    $versions.Rev | Sort-Object -Property Package | Get-Unique -AsString
}
