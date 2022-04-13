
<#
.Synopsis
Remove-BuildFiles removes all obj and bin folders except under node_modules from the current path.
#>
function Remove-BuildFiles()
{
  Get-ChildItem -Directory -Recurse obj, bin | Where-Object { $_.FullName -notmatch "\\node_modules\\" } | Remove-Item -Recurse -Force
}
  
<#
  .synopsis
  Get-GitIgnore downloads .gitignore files from GitHub.
  .parameter Name
  The name of the .gitignore file to download.
  .parameter ListAvilable
  List the available .gitignore files
  .parameter RefreshCache
  Refresh the list of a available .gitignore files in the cache
  .description
  Downloads a .gitignore file from https://github.com/github/gitignore and places it in the
  current working folder.
  .example
  Get-GitIgnore -Name VisualStudio
#>
function Get-GitIgnore
{
  [CmdletBinding()]
  param(
    [string] $Name,
    [switch] $ListAvailable,
    [switch] $RefreshCache
  )
  process
  {
    if ($ListAvailable)
    {
      $cacheFile = Join-Path $env:TEMP "gitignore_cache.json"

      if (-not $RefreshCache `
          -and (Test-Path $cacheFile) `
          -and ([DateTime]::UtcNow - (Get-ItemProperty $cacheFile LastWriteTimeUtc).LastWriteTimeUtc).TotalDays -lt 1)
      {
        Write-Debug "Loading options from cache"
        $files = Get-Content $cacheFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
      }

      if (-not $files)
      {
        Write-Debug "Loading options from github"
        Invoke-Expression "git ls-remote https://github.com/github/gitignore master" | ForEach-Object { $_ -match "(?'hash'[a-f0-9]+)\s+refs\/heads\/master" } | Out-Null
        $files = Invoke-RestMethod "https://api.github.com/repos/github/gitignore/git/trees/$($Matches["hash"])"
        $files | ConvertTo-Json | Set-Content $cacheFile -Force
      }

      if ($files)
      {
        return $files.tree |
          Where-Object { $_.path -match "\w+\.gitignore" } |
          Select-Object @{N = "Language"; E = { $_.path.substring(0, $_.path.length - ".gitignore".length) } } |
          Select-Object -ExpandProperty Language
      }
    }
    else
    {
      $client = New-Object System.Net.WebClient
      $path = Resolve-Path .
      $path = Join-Path $path ".gitignore"
      $client.DownloadFile("https://raw.githubusercontent.com/github/gitignore/master/$($Name).gitignore", $path)
    }
  }
}

# Register the autocompleter for the name parameter on the Get-GitIgnore cmdlet
Register-ArgumentCompleter -CommandName Get-GitIgnore -ParameterName Name -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
  Get-GitIgnore -ListAvailable | Where-Object { $_ -like "*$($wordToComplete)*" }
}

<#
  .synopsis
  Starts an instance of Portainer in Docker.
  .description
  Starts Portainer (https://www.portainer.io/). This assumes that Portainer is installed and configured.
  #>
function Start-Portainer()
{
  Invoke-Expression "docker run -d -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer"
}
  
<#
  .synopsis
  Remove-StaleBranches removes local branches that are no longer tracking an upstream remote.
  .parameter Force
  Forces removal of the branches without prompting.
  #>
function Remove-StaleBranches([switch]$Force)
{
  $branches = Invoke-Expression "git branch -vv" | Select-String "^\s*(?'branch'[-a-zA-Z\/_0-9]+).*(?=: gone]).*$" -AllMatches `
  | ForEach-Object { $_.Matches[0].Groups["branch"].value }
  
  if (-not $Force -and $branches.count -gt 0)
  {
    Write-Host "Deleting the following branches" -ForegroundColor Yellow
    foreach ($branch in $branches)
    {
      Write-Host $branch
    }
  
    $prompt = Read-Host -Prompt "Delete (y/n)?"
  }
  
  if ($Force -or $prompt -eq "y")
  {
    foreach ($branch in $branches)
    {
      Invoke-Expression "git branch -D $($branch)"
    } 
  }
}

<#
.SYNOPSIS
  Sets the title of the current console window / tab.
.EXAMPLE
  PS C:\> Set-Title test
  Will set the title of the current window or tab to "test".
.INPUTS
  (optional) Title - The title to set. This will default to the current folder path if omitted.
#>
function Set-Title(
  [Parameter(Mandatory = $false)] $Title = $null)
{
  if (!$Title)
  {
    $Title = (Get-Location).path
  }

  $host.UI.rawUI.WindowTitle = $Title
}

<#
.SYNOPSIS
  Copies the current working folder to the clipboard.
#>
function Copy-CurrentPath()
{
  Get-Location | Set-Clipboard
}


<#
.SYNOPSIS
  Edit the hosts file.
#>
function Edit-Hosts()
{
  start-process notepad -verb runas -Args C:\windows\system32\drivers\etc\hosts
}

<#
.SYNOPSIS
  Installs the Azure CLI tools or upgrades them using the MSI installer.
#>
function Install-AzureCli()
{
  Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
  Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
  Remove-Item .\AzureCLI.msi
}

<#
.SYNOPSIS
  Opens the first solution file found in the src/app folder.
#>
function Open-Solution()
{
  Get-ChildItem src/app/*.sln | Select-Object -First 1 | Invoke-Expression
}