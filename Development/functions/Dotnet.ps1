function Edit-UserSecrets(
    [Parameter(Mandatory = $false)][string]$Path,
    [Parameter(Mandatory = $false)][string]$Id) {
    

    if (-not $id) {
        if ($path) {
            $csproj = $path
        }
        else {
            $csproj = Get-Location
        }

        $csproj = (Get-ChildItem -Path $csproj -Filter *.csproj | Select-Object -First 1).FullName

        $project = [xml](Get-Content $csproj)

        $id = $project.SelectSingleNode("//PropertyGroup/UserSecretsId")."#text"
    }

    $secrets = "$($env:APPDATA)/Microsoft/UserSecrets/$($id)/secrets.json"

    if(-not (Test-Path -LiteralPath $secrets)){
        throw "User secrets for $($Id) does not exist"
    }

    Invoke-Item -LiteralPath $secrets | Out-Null
}
