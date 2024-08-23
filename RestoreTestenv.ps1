Remove-Item -Path "testenv" -Force -Recurse
New-Item -Path "." -Name "testenv" -ItemType Directory
Out-File -FilePath ".\testenv\RelicCoH2.exe"