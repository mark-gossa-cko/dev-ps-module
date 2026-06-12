function New-GitCommit {
    param($Message)
    git add .
    git commit -m $Message
    git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)
}

function gpu {
    git checkout main
    git pull
}

function gnb {
    param($Name)
    gpu
    git checkout -b $Name
}

function cal {
    param(
        [Parameter(Mandatory = $false)]
        [String] $Path
    )
    $domain="checkout.okta.com"
    $okta_app="0oar3nsvk7VtIvsL3357"
    $aws_okta_app="0oa423kknpZCS07GJ357"
    $role_name="cko_prism_engineer"
    $cko_mgmt_account="791259062566" # Must be the account ID of the role you want to assume and this must match the account ID in the provider ARN
    
    if (!$Path) {
        $Path = Get-Location
    }
        
    okta-aws-cli --org-domain $domain --oidc-client-id $okta_app --aws-acct-fed-app-id $aws_okta_app -b -z -r arn:aws:iam::$($cko_mgmt_account):role/$role_name -i arn:aws:iam::$($cko_mgmt_account):saml-provider/okta -s 43200
    aws codeartifact login --tool dotnet --repository cko-packages --domain cko-packages --domain-owner 791259062566 --region eu-west-1 --no-verify-ssl
    Dotnet restore $Path
}

function gcl {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepositoryUrl
    )

    # Extract folder name from repository URL
    $repoName = ($RepositoryUrl -split "/" | Select-Object -Last 1) -replace ".git$",""

    git clone $RepositoryUrl

    Set-Location $repoName

    cal

    Invoke-item *.sln
}

function Find-Code {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String] $Text,
        [Parameter(Mandatory = $false)]
        [String] $Repository = "",
        [Parameter(Mandatory = $false)]
        [String] $Organization = "cko-issuing",
        [Parameter(Mandatory = $false)]
        [String[]] $Languages = @("c#", "typescript", "java", "hcl")
    )

    $limit = 30
    $results = @()

    $searchRepository = ""
    if (!$Repository -eq ""){
        $searchRepository = "$Organization/$Repository"
    }

    foreach ($language in $Languages){
        $newResults = gh search code $Text --repo $searchRepository --language $language --owner $Organization --json path --json repository --json textMatches --json url --limit $limit | ConvertFrom-Json
        if ($newResults.Count -eq $limit) {Write-Warning "$limit item limit reached - refine search"}
        $results += $newResults
    }

    $results = $results | Where-Object {$_.path -notmatch "test"}

    Write-Output $results | Select-Object @{N="repository";E={$_.repository.namewithowner}}, path, @{N="code";E={$_.textMatches.fragment}}, url | Sort-Object repository
}

function Update-Pwsh {
    winget install --id Microsoft.Powershell --source winget
}

function Hide-Taskbar {
    $p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    $v=(Get-ItemProperty -Path $p).Settings
    $v[8]=123
    Set-ItemProperty -Path $p -Name Settings -Value $v
    Stop-Process -f -ProcessName explorer
}

function Open-Repo {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Path
    )
    
    $leaf = Split-Path -Leaf $Path
    $userProfile = $env:USERPROFILE
    $modulePath = Join-Path -Path $userProfile -ChildPath ".devPsModule"
    if (-not (Test-Path $modulePath)) {
        New-Item -Path $modulePath -ItemType Directory | Out-Null
    }
    $pidInfoPath = Join-Path -Path $modulePath -ChildPath "$leaf.json"
    
    $cursorPID = (Start-Process -FilePath "cursor" -ArgumentList $Path -PassThru).Id
    $slnPIDs = @()
    foreach ($slnFile in (Get-ChildItem -Path $Path -Filter "*.sln" -Recurse)) {
        $slnPIDs += (Start-Process -FilePath $slnFile.FullName -PassThru).Id
    }
    
    $pidInfo = @{
        CursorPID = $cursorPID
        SlnPIDs = $slnPIDs
    }
    
    $pidInfo | ConvertTo-Json | Out-File -FilePath $pidInfoPath
    
    # cal $Path
}

function Close-Repo {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Path
    )
    
    $userProfile = $env:USERPROFILE
    $modulePath = Join-Path -Path $userProfile -ChildPath ".devPsModule"
    $pidInfoPath = Join-Path -Path $modulePath -ChildPath "$Path.json"
    
    if (Test-Path $pidInfoPath) {
        $pidInfo = Get-Content -Path $pidInfoPath | ConvertFrom-Json
        if ($pidInfo.CursorPID) {
            Stop-Process -Id $pidInfo.CursorPID -Force -ErrorAction SilentlyContinue
        }
        if ($pidInfo.SlnPIDs) {
            foreach ($pid in $pidInfo.SlnPIDs) {
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-Warning "No process information found for $Path."
    }
}

function Get-OpenRepos {
    $userProfile = $env:USERPROFILE
    $modulePath = Join-Path -Path $userProfile -ChildPath ".devPsModule"
    if (Test-Path $modulePath) {
        Get-ChildItem -Path $modulePath -Filter "*.json" | ForEach-Object { $_.BaseName }
    } else {
        Write-Warning "No .devPsModule folder found."
    }
}

function Start-Music {
    Start-Process -FilePath "chrome" -ArgumentList "--incognito", "https://music.youtube.com"
    Start-Process -FilePath "ms-actioncenter:controlcenter/bluetooth"
}

function Start-Claude {
    # $credentialsPath = "C:\Users\MarkGossa\.aws\credentials"
    # if (-not (Test-Path $credentialsPath) -or (Get-Item $credentialsPath).LastWriteTime -lt (Get-Date).AddHours(-1)) {
    #     okta-aws-cli --org-domain "checkout.okta.com" --oidc-client-id "0oar3nsvk7VtIvsL3357" --aws-acct-fed-app-id 0oaricq7oliS1Yb8G357 -bz --aws-session-duration 43200 --all-profiles
    # }

    # $env:AWS_PROFILE = "playground14-OktaIDP-cko_playground_engineer"
    # $env:CLAUDE_CODE_USE_BEDROCK = "1"
    # $env:AWS_REGION = "eu-west-1"
    $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
    C:\Users\MarkGossa\.local\bin\claude.exe
}

Export-ModuleMember -Function New-GitCommit, cal, Find-Code, Update-Pwsh, gnb, gpu, Hide-Taskbar, Open-Repo, Close-Repo, Get-OpenRepos, gcl, Start-Music, music, Start-Claude
Set-Alias -Name gco -Value New-GitCommit
Set-Alias -Name or -Value Open-Repo
Set-Alias -Name cr -Value Close-Repo
Set-Alias -Name gor -Value Get-OpenRepos
Set-Alias -Name music -Value Start-Music
Export-ModuleMember -Alias gco, or, cr, gor, gcl, music