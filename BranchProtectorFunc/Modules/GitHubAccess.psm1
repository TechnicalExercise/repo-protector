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