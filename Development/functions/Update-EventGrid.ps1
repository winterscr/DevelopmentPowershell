# Private functions for Update-EventGrid
function getEndpointAndUpdate([string] $sourceResourceId, [string] $tunnelName, [string] $subscriptionName, [string] $pathAndQuery) {
  # Query NGROK for endpoints
  $tunnel = getNgrokTunnel $tunnelName
  $endpointUri = "$($tunnel.public_url)/$($pathAndQuery)"
  updateEventGridEndpoint $sourceResourceId $subscriptionName $endpointUri
    
  Write-Host -ForegroundColor Green "Successfully updated '$($subscriptionName)' endpoint"
}
  
function updateEventGridEndpoint([string]$sourceResourceId, [string]$subscriptionName, [string]$endpointUri) {
  $cmd = "az eventgrid event-subscription show --source-resource-id $($sourceResourceId) --name $($subscriptionName)"
  $currentSub = Invoke-Expression $cmd -ErrorAction SilentlyContinue | ConvertFrom-Json
  
  Write-Verbose "Currently $($subscriptionName) is $($currentSub.destination.endpointBaseUrl), changing to $($endpointUri)"
  
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to query event grid for the subscription '$($subscriptionName)'"
  }
  
  $cmd = "az eventgrid event-subscription update --source-resource-id $($sourceResourceId) --name $($subscriptionName) --endpoint $($endpointUri)"
  $null = Invoke-Expression $cmd -ErrorAction SilentlyContinue
  
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to update event grid with the subscription for '$($subscriptionName)'"
  }
}
  
function getNgrokTunnel([string] $tunnelName) {
  $ngrokUri = "http://localhost:$($ngrokPort)/api/tunnels/$($tunnelName)"
  
  try {
    $result = Invoke-RestMethod $ngrokUri -ErrorAction SilentlyContinue
  }
  catch {
    throw "Unable to connect to NGROK tunnel '$($ngrokUri)', please ensure it is running"
  }
  
  return $result
}
  
<#
.synopsis
Updates event grid with new endpoint from ngrok.
.parameter Subscription
The ID of the subscription.
.parameter ResourceGroup
The resource group containing the event grid.
.parameter Namespace
The namespace of the event grid.
.parameter Secret
The secret for the callback URL.
.parameter NgrokPort
The port to connect to the local ngrok instance on.

Optional: Defaults to 4040.
#>
function Update-EventGrid(
  [parameter(Mandatory = $true)][string] $Subscription,
  [parameter(Mandatory = $true)][string] $ResourceGroup,
  [parameter(Mandatory = $true)][string] $Namespace,
  [parameter(Mandatory = $true)][string] $Secret,
  [int]$NgrokPort = 4040) {
  try {
    $sourceResourceId = "/subscriptions/$($subscription)/resourceGroups/$($resourceGroup)/providers/Microsoft.EventGrid/topics/$($Namespace)"
  
    getEndpointAndUpdate $sourceResourceId "orchestrator" "orchestrator" "api/event?secret=$($secret)"
    getEndpointAndUpdate $sourceResourceId "outgoing" "outgoing" "notifications?secret=$($secret)"
  
    exit 0
  }
  catch [string] {
    Write-Error -Message $_
    exit 1
  }
}
  