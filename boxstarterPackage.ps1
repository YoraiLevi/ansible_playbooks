$attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = ($attempts.Length)?$attempts.Length+1:($attempts)?2:1
if (-Not (Get-Command wsl.exe) -and (wsl cat /proc/version | Out-String) -eq (wsl --help | Out-String)){
    while($currentAttempt -le 5){
        Write-Host "Attempting to install wsl2"
        choco install wsl2 --params "/Version:2 /Retry:true"
        # Restart?
        Write-Host "Attempting to install wsl-ubuntu-2004"
        choco install wsl-ubuntu-2004 --params "/InstallRoot:true"
        New-Item "$env:TEMP\BOXSTARTERATTEMPT$currentAttempt"
    }
}
# Delete Attempts after done
# rm "$env:TEMP\BOXSTARTERATTEMPT*"
cinst git
# git clone https://github.com/YoraiLevi/MyFuckingWikiOfEverything.git
# execute theEverything playbook



Write-Host "Done..."