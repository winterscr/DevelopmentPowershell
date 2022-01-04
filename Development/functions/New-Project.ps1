function New-Project([string] $SolutionName, [string] $ProjectName, [string] $ProjectType = "console", [switch] $GitInit = $false, [switch] $GitCommit = $false)
{
    if($GitInit) {
        git init
        git branch -m main
    }

    Get-GitIgnore VisualStudio
    "* text=auto eol=crlf" > .gitattributes
    mkdir src/app
    mkdir src/env
    mkdir docs

    "# $($ProjectName) Readme" > README.md
    "# $($ProjectName) Documentation" > docs/README.md
    "# $($ProjectName) Environment Files" > src/env/README.md

    cd src/app
    dotnet new tool-manifest
    dotnet tool install paket --ignore-failed-sources
    dotnet paket init && dotnet paket install && dotnet paket restore

    dotnet new sln --name $SolutionName
    dotnet new $ProjectType --name $ProjectName
    dotnet sln add $ProjectName

    cd ../..
    git add -A

    if($GitCommit) {
        git commit -m "Initial commit"
    }
}
