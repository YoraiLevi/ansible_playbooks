Import-Module $PSScriptRoot\ElevateScript.ps1 -Force
function SetupAndStartSSHWindows {
    if ((Get-WindowsCapability -Online -ErrorAction Stop | ? Name -like 'OpenSSH.Server*').State -ne "Installed") {
        Write-Information "SSH is not installed, installing..."
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
        Start-Service sshd
    }
    else {
        Write-Information "SSH is installed..."
        Start-Service sshd
    }
}

function ClearSSHKeyWindows{
}
function ClearAllSSHKeysWindows{
    [CmdletBinding()]
    param()
    Throw-NotAdministrator -ErrorAction Stop
    try{
        rm $ENV:USERPROFILE/.ssh/ -Recurse
    }
    catch{}
    try{
        rm $ENV:ProgramData\ssh\administrators_authorized_keys
    }
    catch{}
}
function CreateRegisterSSHPublickeyWindows{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param([string]$name = "SSHKey")
    Throw-NotAdministrator -ErrorAction Stop
    # Setting up new keys
    [System.IO.FileInfo]$SSHKeyPathPrivate = (Join-Path $ENV:USERPROFILE -ChildPath ".ssh" | Join-Path -ChildPath "id_ed25519_$name")
    [System.IO.FileInfo]$SSHKeyPathPublic = ($SSHKeyPathPrivate.FullName + ".pub")
    try{
    $null = (mkdir $SSHKeyPathPrivate.Directory.FullName) #damn powershell is weird. https://social.technet.microsoft.com/Forums/en-US/57cb76d0-747a-4e77-b5c0-bf2218f5c4a7/very-odd-return-behavior?forum=winserverpowershell
    }catch{}
    #Set SSH key on windows
    $null = (echo yes | ssh-keygen -t ed25519 -q -C "ansible" -f $SSHKeyPathPrivate.FullName -N """")
    #encoding must be ascii and not utf
    $null = (cat $SSHKeyPathPublic.FullName | Out-File -Encoding ASCII -FilePath $ENV:ProgramData\ssh\administrators_authorized_keys)
    
    #Set Permissions correctly for authorized keys file https://superuser.com/a/1605117/1220772
    $acl = Get-Acl $ENV:ProgramData\ssh\administrators_authorized_keys
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators", "FullControl", "Allow")
    $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM", "FullControl", "Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl
    
    $null = (Restart-Service sshd)
    #Connect to SSH
    $null = (ssh localhost -i $SSHKeyPathPrivate -o StrictHostKeyChecking=no exit 0)
    return $SSHKeyPathPrivate
}
