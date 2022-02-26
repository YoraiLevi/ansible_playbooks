# wsl --help == wsl --list (no wsl2?) 
# wsl --list == wsl bashcommand (no repo)
if (-Not (Get-Command wsl.exe) -or (wsl cat /proc/version | Out-String) -eq (wsl --list | Out-String)){
    $attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if($attempts.Length){$attempts.Length+1}else{if($attempts){2}else{1}};#New-Item "$env:TEMP\BOXSTARTERATTEMPT$currentAttempt"
    while($currentAttempt -lt 5){
        $attempts = Get-Item $env:TEMP\BOXSTARTERATTEMPT* -ErrorAction SilentlyContinue; $currentAttempt = if($attempts.Length){$attempts.Length+1}else{if($attempts){2}else{1}};New-Item "$env:TEMP\BOXSTARTERATTEMPT$currentAttempt"
        Write-Host "Attempting to install wsl2"
        choco install wsl2 --params "/Version:2 /Retry:true"
        # Restart?
        Write-Host "Attempting to install wsl-ubuntu-2004"
        choco install wsl-ubuntu-2004 --params "/InstallRoot:true"
    }
}
# Delete Attempts after done
# rm "$env:TEMP\BOXSTARTERATTEMPT*"
cinst git
# git clone https://github.com/YoraiLevi/MyFuckingWikiOfEverything.git
# execute theEverything playbook



Write-Host "Done..."