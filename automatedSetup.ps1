$prevPWD = $PWD
$TEMP = $env:TEMP
function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
function Throw-NotAdministrator {
    if ((Test-Administrator) -eq $false) {
        throw "Not Admin"
    }
}
$ErrorActionPreference = 'stop'
Throw-NotAdministrator
$scriptPath = $MyInvocation.MyCommand.Path

# Initialized windows
if ( (-not ((wsl --list | out-string) -eq (wsl --help | out-string))) -and #wsl2 installed
(-not ((wsl cat /proc/version | Out-String) -eq (wsl --list | Out-String)))) {
    #distro installed 
    $taskName = "automatedSetup"
    try {
        if (-not $scriptPath) {
            cd $TEMP; rm "MyFuckingWikiOfEverything" -Force -Recurse -ErrorAction SilentlyContinue
            git clone "https://github.com/YoraiLevi/MyFuckingWikiOfEverything.git"; cd "MyFuckingWikiOfEverything/Ansible"
            $scriptPath = Join-Path $PWD -ChildPath "automatedSetup.ps1"
        }
        $command = "`$playbook=$playbook;&$scriptPath"
        # Schedule task if needed
        $playbook = if($playbook){$playbook}else{'theEVERYTHING.yml'}
        if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
            $trigger = New-ScheduledTaskTrigger -AtLogon
            $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -Command $command"
            Register-ScheduledTask -Trigger $trigger -Action $action -TaskName $taskName -RunLevel Highest
        }
        
        $ansibleDir = (get-item $scriptPath).Directory
        cd $ansibleDir
        &".\ExecutePlaybook.ps1" -playbookFile ".\playbooks\$playbook" -inventoryFile .\playbooks\inventories\localWindowsWSL\ -vault_id dev@vault/uuid-client | Tee-Object -FilePath "$playbook.log"
        #clear scheduled task
    }
    finally {
        cd $prevPWD
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Pause
        exit $lastexitcode
    }
}
    
# Initialize Windows
Write-Information "WSL is not installed, installing with boxstarters."
$cred = Get-Credential -Message "admin rights are required to install with chocolatey" -UserName $env:USERNAME
$boxstarterPackage = "https://raw.githubusercontent.com/YoraiLevi/MyFuckingWikiOfEverything/master/Ansible/boxstarterPackage.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1')); Get-Boxstarter -Force
Install-BoxstarterPackage -PackageName $boxstarterPackage -Credential $cred