
$TEMP = $env:TEMP
$attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if ($attempts.Length) { $attempts.Length + 1 }else { if ($attempts) { 2 }else { 1 } }; #New-Item "$TEMP\BOXSTARTERATTEMPT$currentAttempt"
while ($true) {
    try {
        if ((wsl cat /proc/version | Out-String) -ne (wsl --list | Out-String)) {
            #distro installed. no need to do anything.
            Write-Host "Distro is installed..."
            break;
        }
        $attempts = Get-Item $TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if ($attempts.Length) { $attempts.Length + 1 }else { if ($attempts) { 2 }else { 1 } }; New-Item "$TEMP\BOXSTARTERATTEMPT$currentAttempt"
        if ($currentAttempt -gt 5) {
            # attempts
            Write-Host "Tried too many times... exiting..."
            # exit
        }
        if ((wsl --list | out-string) -eq (wsl --help | out-string)) {
            Write-Host "Attempting to install wsl2"
            try {
                choco install wsl2 --params "/Version:2 /Retry:true"
            }
            catch {
                # If packages fails but installs anyways a restart is required
                Invoke-Reboot
            }
        }
        elseif ((wsl cat /proc/version | Out-String) -eq (wsl --list | Out-String)) {
            # for aesthetics make sure wsl2 is registered in chocolatey
            Write-Host "Making sure chocolatey has wsl2 listed"
            choco install wsl2
            Write-Host "Attempting to install wsl-ubuntu-2004"
            wsl --update # needed to register distro
            wsl --shutdown
            choco install wsl-ubuntu-2004 --params "/InstallRoot:true"
            Write-Host "Waiting for distro to register..."
            while ((wsl cat /proc/version | Out-String) -eq (wsl --list | Out-String)) {
                Start-Sleep -s 1
            }
        }
    }
    catch {
        Write-Host $_
    }
}
# Delete Attempts after done
if (-not (Get-Command git)) {
    cinst git
}
cd $TEMP; rm "MyFuckingWikiOfEverything" -Force -Recurse -ErrorAction SilentlyContinue
try {
    git clone "https://github.com/YoraiLevi/MyFuckingWikiOfEverything.git"; cd "MyFuckingWikiOfEverything/Ansible"
    .\ExecutePlaybook.ps1 -playbookFile .\playbooks\theEVERYTHING.yml -inventoryFile .\playbooks\inventories\localWindowsWSL\ -vault_id dev@vault/uuid-client
}
catch {
    # git is not in path, restart...
    $_
    Invoke-Reboot 
}
# execute theEverything playbook


# Success
rm "$TEMP\BOXSTARTERATTEMPT*"
Write-Host "Done..."