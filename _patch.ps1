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
