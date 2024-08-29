enum _Coh2State {
    Yes
    Patched
    No
}

$PATCHURL = "https://raw.githubusercontent.com/kotanys/Coh2LanguagePatch/main/_patch.ps1"
$PATH = "."

function _DownloadPatch([string]$coh2exe) {
    try 
    {
        $responce = Invoke-WebRequest -Uri $PATCHURL -Headers @{"Cache-Control"="no-cache"}
    }
    catch [System.InvalidOperationException]
    {
        Write-Error "Unable to download $PATCHURL"
        return $null
    }
    catch
    {
        Write-Error "Unknown error downloading"
        return $null
    }
    if ($responce.StatusCode -ne 200)
    {
        Write-Error "Unable to download"
        return $null
    }
    return $responce.Content.Replace("{0}", $coh2exe)
}
function _GetCoh2State([Parameter(Mandatory)] [string]$path) {
    return $(if (Test-Path -Path "$path\__reliccoh2.exe") { [_Coh2State]::Patched }
            elseif (Test-Path -Path "$path\reliccoh2.exe") { [_Coh2State]::Yes }
            else { [_Coh2State]::No })
}
function _CreatePatch([Parameter(Mandatory)] [string]$coh2exe,
                      [Parameter(Mandatory)] [string]$outfile) {

    if (Test-Path -Path "$PATH\_patch.ps1")
    {
        Write-Output "Using local _patch.ps1"
        $ps1 = "$PATH\_patch.ps1"
    }
    else
    {
        Write-Output "Downloading from $PATCHURL"
        $patch = _DownloadPatch -url $PATCHURL -coh2exe $coh2exe
        if ($null -eq $patch)
        {
            throw
        }
        $ps1 = "$env:TEMP\sgvqw0rwev_coh2patch.ps1"
        $patch | Out-File $ps1
        Write-Output "Downloaded to $ps1"
    }
    Invoke-ps2exe -inputFile $ps1 -outputFile $outfile -Verbose -noConsole
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
    catch { }
}

try {
    Invoke-PS2EXE | Out-Null
}
catch {
    Install-Module -Name ps2exe -Scope CurrentUser
}

try
{
    Rename-Item "$PATH\RelicCoH2.exe" -NewName "__RelicCoH2.exe"
    _CreatePatch -coh2exe "__RelicCoH2.exe" -outfile "$PATH\RelicCoH2.exe"
    Write-Output "Actual COH2 executable renamed to __RelicCoH2.exe"
}
catch
{
    throw
    return
}
