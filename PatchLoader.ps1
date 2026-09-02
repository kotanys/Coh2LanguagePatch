param (
    [switch]$extract=$false
)

enum _Coh2State {
    Yes
    Patched
    No
}

$PATH = "."
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

function _GetCoh2State([Parameter(Mandatory)] [string]$path) {
    return $(if (Test-Path -Path "$path\__reliccoh2.exe") { [_Coh2State]::Patched }
            elseif (Test-Path -Path "$path\reliccoh2.exe") { [_Coh2State]::Yes }
            else { [_Coh2State]::No })
}
function _CreatePatch([Parameter(Mandatory)] [string]$coh2exe,
                      [Parameter(Mandatory)] [string]$outfile) {
    Invoke-ps2exe -InputFile $PATCH.Replace("{0}", $coh2exe) -OutputFile $outfile -Verbose -NoConsole
}
function _InstallPatch {
    if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue))
    {
        Install-Module -Name ps2exe -RequiredVersion 1.0.18 -Scope CurrentUser -ErrorAction Stop
    }

    Rename-Item "$PATH\RelicCoH2.exe" -NewName "__RelicCoH2.exe"
    _CreatePatch -coh2exe "__RelicCoH2.exe" -outfile "$PATH\RelicCoH2.exe"
    Write-Output "Actual COH2 executable renamed to __RelicCoH2.exe"
}

if ($extract)
{
    Write-Output "Patch extracted to patch.ps1"
    Write-Output $PATCH | Out-File patch.ps1
    return
}

$coh2state = _GetCoh2State $PATH
if ($coh2state -eq ([_Coh2State]::No))
{
    Write-Error "No COH2 found"
    return
}
elseif ($coh2state -eq ([_Coh2State]::Patched)) 
{
    Write-Output "Deleting previous patch"
    try {
        Remove-Item -Path "$PATH\reliccoh2.exe"
        Rename-Item -Path "$PATH\__reliccoh2.exe" -NewName "RelicCoH2.exe"
    }
    catch { 
        Write-Warning "Couldn't delete patch, proceeding anyway"
    }
}

try
{
    _InstallPatch
}
catch
{
    throw
}
