
$attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if ($attempts.Length) { $attempts.Length + 1 }else { if ($attempts) { 2 }else { 1 } }; #New-Item "$env:TEMP\BOXSTARTERATTEMPT$currentAttempt"
while (($currentAttempt -lt 5) -and (-Not (Get-Command wsl.exe) -or (wsl cat /proc/version | Out-String) -eq (wsl --list | Out-String))) {
    $attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if ($attempts.Length) { $attempts.Length + 1 }else { if ($attempts) { 2 }else { 1 } }; New-Item "$env:TEMP\BOXSTARTERATTEMPT$currentAttempt"
    Write-Host "Attempting to install wsl2"
    choco install wsl2 --params "/Version:2 /Retry:true"
    # Restart?
    Write-Host "Attempting to install wsl-ubuntu-2004"
    choco install wsl-ubuntu-2004 --params "/InstallRoot:true"
}
# Delete Attempts after done
cinst git
cd $env:TEMP; rm "MyFuckingWikiOfEverything" -Force -Recurse -ErrorAction SilentlyContinue
try {
    git clone "https://github.com/YoraiLevi/MyFuckingWikiOfEverything.git"; cd "MyFuckingWikiOfEverything/Ansible"
    .\ExecutePlaybook.ps1 -playbookFile .\playbooks\theEVERYTHING.yml -inventoryFile .\playbooks\inventories\localWindowsWSL\
}
catch{
    # If git is not in path, restart...
    Invoke-Reboot 
}
# execute theEverything playbook


# Success
rm "$env:TEMP\BOXSTARTERATTEMPT*"
Write-Host "Done..."