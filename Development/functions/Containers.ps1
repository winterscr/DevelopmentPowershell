function New-SqlServerContainer([string] $Name, [int] $Port = 1435, [switch] $CreateVolume, [parameter(Mandatory = $false)][securestring] $Password) {
    Write-Host "Creating SQL server instance $Name"
    if (!$null) {
        $Password = ConvertTo-SecureString 'Pa$$w0rd' -AsPlainText
    }

    if ($CreateVolume) {
        docker volume create $Name > $null
    }

    $createCommand = "docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=$(ConvertFrom-SecureString $Password -AsPlainText)' -p $($Port):1433 --name $($Name) " + `
        "-h $($Name) -d -v $($Name):/var/opt/mssql mcr.microsoft.com/mssql/server:2019-latest"
    #-m 436207616
    Write-Host $createCommand

    Invoke-Expression $createCommand > $null

    Write-Host "SQL Server instance listening on port $Port"
}

function Remove-SqlServerContainer([string] $Name, [switch] $DeleteVolume) {
    Write-Host "Stopping and removing container $Name"
    docker container stop $Name > $null && docker container rm $Name > $null
    if ($DeleteVolume) {
        Write-Host "Deleting volume $Name"
        docker volume rm $Name > $null
    }

    Write-Host "Done"
}

function New-AzuriteContainer([string][parameter(Mandatory = $false)] $Volume, [switch] $CreateVolume, [string][parameter(Mandatory = $false)] $ContainerName) {
    if (!$Volume) {
        $volumePath = "C:\docker_volumes\azurite"
    }

    runContainer `
        -ImageName "mcr.microsoft.com/azure-storage/azurite" `
        -DockerOptions "-p 10000:10000 -p 10001:10001 -p 10002:10002 -d" `
        -Volume $volumePath `
        -DataPath "/data" `
        -CreateVolume $CreateVolume `
        -ContainerName $ContainerName
}

function New-MongoContainer([string][parameter(Mandatory = $false)] $Volume, [switch] $CreateVolume, [string][parameter(Mandatory = $false)] $ContainerName) {
    if (!$Volume) {
        $volumePath = "C:\docker_volumes\mongodb"
    }

    runContainer `
        -ImageName "mongo:latest" `
        -DockerOptions "-p 27017:27017 -d" `
        -Volume $volumePath `
        -DataPath "/data/db" `
        -CreateVolume $CreateVolume `
        -ContainerName $ContainerName
}

function runContainer(
    $ImageName,
    $DockerOptions,
    $Volume,
    $DataPath,
    $CreateVolume,
    $ContainerName) {

    if (!(Test-Path $Volume)) {
        if ($CreateVolume) {
            Write-Host -ForegroundColor Green "Volume folder not found, creating '$($Volume)'"
            New-Item -Path $Volume -ItemType Directory > $null
        }
        else {
            Write-Error "Volume folder not found and CreateVolume was not specified"
            return
        }
    }

    $dockerCommand = "docker run $($DockerOptions) -v $($Volume):$($DataPath)"

    if ($ContainerName) {
        $dockerCommand += " --name $($ContainerName)"
    }

    $dockerCommand += " $($ImageName)"

    Invoke-Expression $dockerCommand
}