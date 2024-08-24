# FILE MUST BE ENCODED IN WINDOWS-1251 FOR RUSSIAN LANGUAGE OUTPUT
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
        Write-Error "Не вышло получить файл."
        return $null
    }
    catch
    {
        Write-Error "Неожиданная ошибка скачивания."
        return $null
    }
    if ($responce.StatusCode -ne 200)
    {
        Write-Error "Не вышло получить файл."
        return $null
    }
    return $responce.Content.Replace("{0}", $coh2exe)
}
function _GetCoh2State([Parameter(Mandatory)] [string]$path) {
    $found = $false
    $files = Get-ChildItem -File -Path $path
    foreach ($file in $files) {
        if ($file.Name.ToLower().Equals("__reliccoh2.exe"))
        {
            return [_Coh2State]::Patched
        }
        if ($file.Name.ToLower().Equals("reliccoh2.exe"))
        {
            $found = $true
        }
    }
    return $(if ($found) { [_Coh2State]::Yes } else { [_Coh2State]::No })
}
function _CreatePatch([Parameter(Mandatory)] [string]$coh2exe,
                      [Parameter(Mandatory)] [string]$outfile) {

    if (Test-Path -Path "$PATH\_patch.ps1")
    {
        Write-Output "Найден патч в текущей папке."
        $ps1 = "$PATH\_patch.ps1"
    }
    else
    {
        Write-Output "Скачиваю патч с $PATCHURL"
        $patch = _DownloadPatch -url $PATCHURL -coh2exe $coh2exe
        if ($null -ne $patch)
        {
            throw
        }
        $ps1 = ".\sgvqw0rwev_coh2patch.ps1"
        $patch | Out-File $ps1
        Write-Output "Патч (.ps1) сохранён в $ps1"
    }
    Invoke-ps2exe -inputFile $ps1 -outputFile $outfile -Verbose
}

$coh2state = _GetCoh2State $PATH
if ($coh2state -eq ([_Coh2State]::No))
{
    Write-Error "Нет коха!"
    return
}
elseif ($coh2state -eq ([_Coh2State]::Patched)) {
    Write-Output "Удаляю прошлый патч"
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
    Write-Output "Патч установлен. Оригинальный exe коха переименован в __RelicCoH2.exe"
}
catch
{
    Write-Error "Ошибка!!"
    throw
    return
}