param (
    [switch]$extract=$false
)

enum _Coh2State {
    Yes
    Patched
    No
}

$PATCH = @'
    $COH2PATH = "{0}"
    $langs = Get-WinUserLanguageList
    if ($langs[0].LanguageTag -eq "en-US")
    {
        [System.Diagnostics.Process]::Start($COH2PATH) | Out-Null
        return
    }
    $langs.Reverse()
    Set-WinUserLanguageList -LanguageList $langs -Force 3> $null
    try
    {
        [System.Diagnostics.Process]::Start($COH2PATH) | Out-Null
        Start-Sleep -Seconds 20
    }
    finally
    {
        $langs.Reverse()
        Set-WinUserLanguageList -LanguageList $langs -Force 3> $null
    }
'@

function _GetCoh2State {
    return $(if (Test-Path -Path "__reliccoh2.exe") { [_Coh2State]::Patched }
            elseif (Test-Path -Path "reliccoh2.exe") { [_Coh2State]::Yes }
            else { [_Coh2State]::No })
}
function _TestCoh2State() {
    $coh2state = _GetCoh2State
    if ($coh2state -eq ([_Coh2State]::No))
    {
        Write-Error "No COH2 found"
        throw
    }
    elseif ($coh2state -eq ([_Coh2State]::Patched)) 
    {
        Write-Output "Deleting previous patch"
        try {
            Remove-Item -Path "reliccoh2.exe"
            Rename-Item -Path "__reliccoh2.exe" -NewName "RelicCoH2.exe"
        }
        catch { 
            Write-Warning "Couldn't delete patch, proceeding anyway"
        }
    }
}
function _InstallPatch {
    try { Get-Command Invoke-PS2EXE | Out-Null }
    catch
    {
        Install-Module -Name ps2exe -RequiredVersion 1.0.18 -Scope CurrentUser -ErrorAction Stop
    }

    Rename-Item "RelicCoH2.exe" -NewName "__RelicCoH2.exe"
    Invoke-ps2exe -InputFile "patch.ps1" -OutputFile "RelicCoH2.exe" -Verbose -NoConsole
    Write-Output "Actual COH2 executable renamed to __RelicCoH2.exe"
}


try
{
    $contents = $(if ($extract) { $PATCH } else { $PATCH.Replace("{0}", "__RelicCoH2.exe") })
    Write-Output $contents | Out-File patch.ps1
    if (-not $extract) {
        _TestCoh2State
        _InstallPatch
    }
}
catch
{
    throw
}
