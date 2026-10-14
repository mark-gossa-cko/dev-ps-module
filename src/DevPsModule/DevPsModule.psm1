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

function Start-FocusSession {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 240)]
        [int] $Minutes,
        [Parameter(Mandatory = $false)]
        [String] $SlackToken = $env:SLACK_USER_TOKEN # User token (xoxp-) with the dnd:write scope
    )

    if (!$SlackToken) {
        Write-Warning "No Slack token found - set SLACK_USER_TOKEN or pass -SlackToken. Skipping Slack DND."
    } else {
        $response = Invoke-RestMethod -Method Post -Uri "https://slack.com/api/dnd.setSnooze" -Headers @{ Authorization = "Bearer $SlackToken" } -Body @{ num_minutes = $Minutes }
        if ($response.ok) {
            Write-Host "Slack DND on until $([DateTimeOffset]::FromUnixTimeSeconds($response.snooze_endtime).LocalDateTime.ToShortTimeString())"
        } else {
            Write-Warning "Failed to set Slack DND: $($response.error)"
        }
    }

    # Undocumented Clock app deep link used by the Windows focus widget. The public FocusSessionManager API is a Limited Access Feature so can't be called from a script.
    $endTime = [DateTimeOffset]::UtcNow.AddMinutes($Minutes).ToUnixTimeMilliseconds()
    Start-Process "ms-clock://createfocustimer?skipBreaks=true&isAot=true&force=true&endTime=$endTime&duration=$Minutes"
    Move-FocusTimerToLaptopScreen
}

function Move-FocusTimerToLaptopScreen {
    if (-not ('DevPsModule.FocusTimerWindow' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace DevPsModule {
    public static class FocusTimerWindow {
        [StructLayout(LayoutKind.Sequential)] struct LUID { public uint LowPart; public int HighPart; }
        [StructLayout(LayoutKind.Sequential)] struct PATH_SOURCE_INFO { public LUID adapterId; public uint id; public uint modeInfoIdx; public uint statusFlags; }
        [StructLayout(LayoutKind.Sequential)] struct PATH_TARGET_INFO { public LUID adapterId; public uint id; public uint modeInfoIdx; public uint outputTechnology; public uint rotation; public uint scaling; public uint refreshNumerator; public uint refreshDenominator; public uint scanLineOrdering; public int targetAvailable; public uint statusFlags; }
        [StructLayout(LayoutKind.Sequential)] struct PATH_INFO { public PATH_SOURCE_INFO sourceInfo; public PATH_TARGET_INFO targetInfo; public uint flags; }
        [StructLayout(LayoutKind.Explicit, Size = 64)] struct MODE_INFO {
            [FieldOffset(0)] public uint infoType;
            [FieldOffset(16)] public uint width;
            [FieldOffset(20)] public uint height;
            [FieldOffset(28)] public int x;
            [FieldOffset(32)] public int y;
        }
        [StructLayout(LayoutKind.Sequential)] struct POINT { public int x, y; }
        [StructLayout(LayoutKind.Sequential)] struct RECT { public int Left, Top, Right, Bottom; }
        [StructLayout(LayoutKind.Sequential)] struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }

        [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint flags, out uint numPaths, out uint numModes);
        [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint flags, ref uint numPaths, [Out] PATH_INFO[] paths, ref uint numModes, [Out] MODE_INFO[] modes, IntPtr topologyId);
        [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT point, uint flags);
        [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr monitor, ref MONITORINFO info);
        [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr monitor, int dpiType, out uint dpiX, out uint dpiY);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr childAfter, string className, string windowName);
        [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr hWnd, int index);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr hWnd, int attribute, out int value, int size);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
        [DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr hWnd);
        [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);

        const uint QDC_ONLY_ACTIVE_PATHS = 0x2;
        const int GWL_EXSTYLE = -20, WS_EX_TOPMOST = 0x8, DWMWA_CLOAKED = 14, MDT_EFFECTIVE_DPI = 0;
        const uint SWP_NOSIZE = 0x1, SWP_NOZORDER = 0x4, SWP_NOACTIVATE = 0x10;
        static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);

        // Built-in laptop screen, or IntPtr.Zero if it isn't active (e.g. lid closed)
        static IntPtr GetInternalMonitor() {
            uint numPaths, numModes;
            if (GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, out numPaths, out numModes) != 0) return IntPtr.Zero;
            var paths = new PATH_INFO[numPaths];
            var modes = new MODE_INFO[numModes];
            if (QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, ref numPaths, paths, ref numModes, modes, IntPtr.Zero) != 0) return IntPtr.Zero;

            for (int i = 0; i < numPaths; i++) {
                // INTERNAL, LVDS, DISPLAYPORT_EMBEDDED, UDI_EMBEDDED
                uint technology = paths[i].targetInfo.outputTechnology;
                if (technology != 0x80000000 && technology != 6 && technology != 11 && technology != 13) continue;
                var source = modes[paths[i].sourceInfo.modeInfoIdx];
                return MonitorFromPoint(new POINT { x = source.x + (int)source.width / 2, y = source.y + (int)source.height / 2 }, 0);
            }
            return IntPtr.Zero;
        }

        // The Clock app's always-on-top focus timer, or IntPtr.Zero if it isn't showing.
        // Uses FindWindowEx as the timer sits in a z-order band that EnumWindows skips.
        static IntPtr FindTimer() {
            IntPtr hWnd = IntPtr.Zero;
            while ((hWnd = FindWindowEx(IntPtr.Zero, hWnd, "ApplicationFrameWindow", "Clock")) != IntPtr.Zero) {
                int cloaked;
                DwmGetWindowAttribute(hWnd, DWMWA_CLOAKED, out cloaked, sizeof(int));
                if ((GetWindowLong(hWnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0 && IsWindowVisible(hWnd) && cloaked == 0) return hWnd;
            }
            return IntPtr.Zero;
        }

        // Waits for the focus timer to appear then moves it to the top right of the laptop screen.
        // Returns false if the timer didn't appear or couldn't be moved.
        public static bool MoveToInternalDisplay(int timeoutMs) {
            var previousContext = SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
            try {
                var monitor = GetInternalMonitor();
                var info = new MONITORINFO { cbSize = Marshal.SizeOf(typeof(MONITORINFO)) };
                if (monitor == IntPtr.Zero || !GetMonitorInfo(monitor, ref info)) return true;
                var work = info.rcWork;

                // The timer moves and resizes as it's created, so wait until it's settled
                IntPtr timer = IntPtr.Zero, previousTimer = IntPtr.Zero;
                RECT window = new RECT(), previousWindow = new RECT();
                for (int waited = 0; ; waited += 250) {
                    if (waited >= timeoutMs) return false;
                    Thread.Sleep(250);
                    timer = FindTimer();
                    if (timer == IntPtr.Zero) continue;
                    GetWindowRect(timer, out window);
                    if (timer == previousTimer && window.Equals(previousWindow)) break;
                    previousTimer = timer;
                    previousWindow = window;
                }

                if (window.Left >= work.Left && window.Top >= work.Top && window.Right <= work.Right && window.Bottom <= work.Bottom) return true;

                // The timer resizes itself for the laptop screen's scaling once it's moved, so line it up using the size it'll end up
                uint dpi, unused;
                GetDpiForMonitor(monitor, MDT_EFFECTIVE_DPI, out dpi, out unused);
                int width = (int)((window.Right - window.Left) * (double)dpi / GetDpiForWindow(timer));
                int margin = (int)(24 * dpi / 96);
                return SetWindowPos(timer, IntPtr.Zero, work.Right - width - margin, work.Top + margin, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
            } finally {
                SetThreadDpiAwarenessContext(previousContext);
            }
        }
    }
}
'@
    }

    if (-not [DevPsModule.FocusTimerWindow]::MoveToInternalDisplay(10000)) {
        Write-Warning "Couldn't move the focus timer to the laptop screen"
    }
}

Export-ModuleMember -Function New-GitCommit, cal, Find-Code, Update-Pwsh, gnb, gpu, Hide-Taskbar, Open-Repo, Close-Repo, Get-OpenRepos, gcl, Start-Music, music, Start-Claude, Start-FocusSession
Set-Alias -Name gco -Value New-GitCommit
Set-Alias -Name or -Value Open-Repo
Set-Alias -Name cr -Value Close-Repo
Set-Alias -Name gor -Value Get-OpenRepos
Set-Alias -Name music -Value Start-Music
Export-ModuleMember -Alias gco, or, cr, gor, gcl, music