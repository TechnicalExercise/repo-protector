using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed the request."

$secret = [System.Environment]::GetEnvironmentVariable("ACCESS_TOKEN", [System.EnvironmentVariableTarget]::Process)

$client_payload = $TriggerMetadata | ConvertFrom-Json

if ($client_payload.action -eq "created") {
    $repo = $client_payload.repository.name
    $owner = $client_payload.repository.owner.login
    $branch = $client_payload.repository.default_branch

    Write-Host "Setting policy for $owner/$repo : $branch"
}






# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}
Write-Host $body

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})

