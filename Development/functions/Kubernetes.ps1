<#
.SYNOPSIS
    Start minikube and configure the current shell to minikube docker.
.NOTES
    This will not start minikube if it is already running but
    will just configure the current shell.
#>
function Use-MiniKube()
{
    minikube status

    if ($LASTEXITCODE -ne 0)
    {
        minikube start
    }

    if ($LASTEXITCODE -ne 0)
    {
        throw "Unable to start minikube"
    }

    Write-Host -ForegroundColor Green "Configuring docker environment to minikube"

    minikube docker-env --shell powershell | Invoke-Expression
}

<#
.SYNOPSIS
    Configure the current shell to use docker desktop.
#>
function Use-DockerDesktop()
{
    Write-Host -ForegroundColor Green "Configuring docker environment to docker desktop"

    Remove-Item env:DOCKER_*
}
