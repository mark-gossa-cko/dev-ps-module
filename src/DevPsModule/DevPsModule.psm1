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
        [Parameter(Mandatory = $true)]
        [String] $Path
    )
    $domain="checkout.okta.com"
    $okta_app="0oar3nsvk7VtIvsL3357"
    $aws_okta_app="0oa423kknpZCS07GJ357"
    $role_name="cko_issuing_engineer"
    $account_id="791259062566"
    okta-aws-cli --org-domain $domain --oidc-client-id $okta_app --aws-acct-fed-app-id $aws_okta_app -b -z -r arn:aws:iam::$($account_id):role/$role_name -i arn:aws:iam::$($account_id):saml-provider/okta -s 43200
    
    Dotnet restore $Path
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

Export-ModuleMember -Function New-GitCommit, cal, Find-Code, Update-Pwsh, gnb, gpu, Hide-Taskbar, Open-Repo, Close-Repo, Get-OpenRepos
Set-Alias -Name gco -Value New-GitCommit
Set-Alias -Name or -Value Open-Repo
Set-Alias -Name cr -Value Close-Repo
Set-Alias -Name gor -Value Get-OpenRepos
Export-ModuleMember -Alias gco, or, cr, gor