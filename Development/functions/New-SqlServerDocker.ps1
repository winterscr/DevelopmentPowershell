function New-SqlServerDocker([string] $Name, [int] $Port = 1435, [switch] $CreateVolume, [parameter(Mandatory = $false)][securestring] $Password)
{
    Write-Host "Creating SQL server instance $Name"
    if (!$null)
    {
        $Password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText
    }

    if ($CreateVolume){
        docker volume create $Name > $null
    }

    $createCommand = "docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=$(ConvertFrom-SecureString $Password -AsPlainText)' -p $($Port):1433 --name $($Name) " + `
        "-h $($Name) -d -v $($Name):/var/opt/mssql mcr.microsoft.com/mssql/server:2019-latest"
    #-m 436207616
    Write-Host $createCommand

    Invoke-Expression $createCommand > $null

    Write-Host "SQL Server instance listening on port $Port"
}

function Remove-SqlServerDocker([string] $Name, [switch] $DeleteVolume)
{
    Write-Host "Stopping and removing container $Name"
    docker container stop $Name > $null && docker container rm $Name > $null
    if ($DeleteVolume)
    {
        Write-Host "Deleting volume $Name"
        docker volume rm $Name > $null
    }

    Write-Host "Done"
}