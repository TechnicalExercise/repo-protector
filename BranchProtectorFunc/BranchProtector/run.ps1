using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed the request."

$secret = [System.Environment]::GetEnvironmentVariable("ACCESS_TOKEN", [System.EnvironmentVariableTarget]::Process)

if ($TriggerMetadata) {
    # $client_payload = $TriggerMetadata | ConvertFrom-Json -Depth 5
    Write-Host "Action: $($TriggerMetadata.action)"

    if ($TriggerMetadata.action -eq "created") {
        $repo = $TriggerMetadata.repository.name
        $owner = $TriggerMetadata.repository.owner.login
        $branch = $TriggerMetadata.repository.default_branch
        $senderLogin = $TriggerMetadata.login

        Write-Host "Setting policy for $owner/$repo : $branch"

        $protectionTemplate = (Get-BranchProtection -Username $senderLogin -Token $secret -Owner $owner -Repo Template -Branch main)

        Write-Host "Branch protection template: $protectionTemplate"

    }
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
        Body       = $body
    })

    function CreateGitHubRequestHeaders([string]$username, [string]$token){
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$token)))
        $headers = @{Authorization="Basic $base64AuthInfo"}
        return $headers
    }
    
    function GetRestfulErrorResponse($exception) {
        $ret = ""
        if($exception.Exception -and $exception.Exception.Response){
            $result = $exception.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $ret = $reader.ReadToEnd()
            $reader.Close()
        }
        if($ret -eq $null -or $ret.Trim() -eq ""){
            $ret = $exception.ToString()
        }
        return $ret
    }
    
    function Get-BranchProtection {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)][String]$Username,
            [Parameter(Mandatory=$true)][String]$Token,
            [Parameter(Mandatory=$true)][String]$Owner,
            [Parameter(Mandatory=$true)][String]$Repo,
            [Parameter(Mandatory=$true)][String]$Branch
        )
    
        try {
            $headers = CreateGitHubRequestHeaders -username $Username -token $Token
            Invoke-WebRequest -Method Get `
                -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch/protection" `
                -Headers $headers
        } catch {
            $resp = (GetRestfulErrorResponse $_)
            Write-Error $resp
            throw
        }
    }