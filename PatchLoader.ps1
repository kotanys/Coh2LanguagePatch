# FILE MUST BE ENCODED IN WINDOWS-1251 FOR RUSSIAN LANGUAGE OUTPUT
enum _Coh2State {
    Yes
    Patched
    No
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

    $tempps1 = "$env:TEMP\sgvqw0rwev_coh2patch.ps1"

    "`$COH2PATH = `"$coh2exe`"" > $tempps1
    "`$langs = Get-WinUserLanguageList" >> $tempps1
    "if (`$langs[0].LanguageTag -eq `"en-US`")" >> $tempps1
    "{" >> $tempps1
    "    [System.Diagnostics.Process]::Start(`$COH2PATH) | Out-Null" >> $tempps1
    "    return" >> $tempps1
    "}" >> $tempps1
    "`$langs.Reverse()" >> $tempps1
    "Set-WinUserLanguageList -LanguageList `$langs -Force | Out-Null" >> $tempps1
    "try" >> $tempps1
    "{" >> $tempps1
    "    [System.Diagnostics.Process]::Start(`$COH2PATH) | Out-Null" >> $tempps1
    "    Write-Output `"Waiting 20 seconds`"" >> $tempps1
    "    Start-Sleep -Seconds 20" >> $tempps1
    "}" >> $tempps1
    "finally" >> $tempps1
    "{" >> $tempps1
    "    `$langs.Reverse()" >> $tempps1
    "    Set-WinUserLanguageList -LanguageList `$langs -Force | Out-Null" >> $tempps1
    "}" >> $tempps1

    Invoke-ps2exe -inputFile $tempps1 -outputFile $outfile -Verbose
}

$PATH = "."
$iscoh2patchresult = _GetCoh2State $PATH
if ($iscoh2patchresult -eq ([_Coh2State]::No))
{
    Write-Error "Нет коха!"
    return
}
elseif ($iscoh2patchresult -eq ([_Coh2State]::Patched)) {
    Write-Output "Удаляю прошлый патч"
    try {
        Remove-Item -Path "$PATH\reliccoh2.exe"
        Rename-Item -Path "$PATH\__reliccoh2.exe" -NewName "RelicCoH2.exe"
    }
    catch {
        Write-Error "Не вышло :("
        throw
        return
    }
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
    Write-Output "Готово. Оригинальный кох переименован в __RelicCoH2.exe. Для удаления патча достаточно удалить RelicCoH2.exe и переименовать __RelicCoH2.exe в RelicCoH2.exe"
}
catch
{
    Write-Error "Ошибка!!"
    throw
    return
}