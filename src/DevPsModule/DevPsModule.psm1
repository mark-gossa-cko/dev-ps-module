function gco {
    param($Message)
    git add .
    git commit -m $Message
    git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)
}

function CodeArtifactLogin {
    $domain="checkout.okta.com"
    $okta_app="0oar3nsvk7VtIvsL3357"
    $aws_okta_app="0oa423kknpZCS07GJ357"
    $role_name="cko_issuing_engineer"
    $account_id="791259062566"
    okta-aws-cli --org-domain $domain --oidc-client-id $okta_app --aws-acct-fed-app-id $aws_okta_app -b -z -r arn:aws:iam::$($account_id):role/$role_name -i arn:aws:iam::$($account_id):saml-provider/okta
    
    Dotnet restore
}

function Find-Code {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String] $Text,
        [Parameter(Mandatory = $false)]
        [String] $Repository = "",
        [Parameter(Mandatory = $false)]
        [String] $Organization = "cko-issuing"
    )

    $limit = 30
    $languages = @("c#", "typescript", "java")
    $results = @()

    $searchRepository = ""
    if (!$Repository -eq ""){
        $searchRepository = "$Organization/$Repository"
    }

    foreach ($language in $languages){
        $newResults = gh search code $Text --repo $searchRepository --language $language --owner $Organization --json path --json repository --json textMatches --json url --limit $limit | ConvertFrom-Json
        if ($newResults.Count -eq $limit) {Write-Warning "$limit item limit reached - refine search"}
        $results += $newResults
    }

    $results = $results | Where-Object {$_.path -notmatch "test"}

    Write-Output $results | Select-Object @{N="repository";E={$_.repository.namewithowner}}, path, @{N="code";E={$_.textMatches.fragment}}, url | Sort-Object repository
}

Export-ModuleMember -Function gco, CodeArtifactLogin, Find-Code