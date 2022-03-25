Import-Module -DisableNameChecking $PSScriptRoot\ElevateScript.psm1
function SetupAndStartSSHWindows {
    $ErrorActionPreference = 'Stop'
    try {
        if ((Get-Service sshd).Status -notlike "Running") {
            Write-Information "SSH is installed... starting.."
            Start-Service sshd
        }

    }
    catch {
        if ((Get-WindowsCapability -Online -ErrorAction Stop | ? Name -like 'OpenSSH.Server*').State -ne "Installed") {
            Write-Information "SSH is not installed, installing..."
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
            # New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
            Start-Service sshd
        }
    }
}

function ClearSSHKeyWindows {
}
function ClearAllSSHKeysWindows {
    [CmdletBinding()]
    param()
    Throw-NotAdministrator -ErrorAction Stop
    try {
        rm $ENV:USERPROFILE/.ssh/ -Recurse
    }
    catch {}
    try {
        rm $(Get-AuthorizedKeysFilePath)
    }
    catch {}
}
function Get-AuthorizedKeysFilePath {
    # TODO: Get the actual settings from the file.
    #AuthorizedKeysFile      .ssh/authorized_keys

    # Match Group administrators
    #   AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
    if ((cat $env:ProgramData\ssh\sshd_config) | Where-Object { $_ -like "*# AuthorizedKeysFile*" }) { 
        #special admin location is commented out, using regular user location
        return "$ENV:USERPROFILE\.ssh\authorized_keys"
    }
    else {
        return "$ENV:ProgramData\ssh\administrators_authorized_keys"
    }
}
function CreateRegisterSSHPublickeyWindows {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param([string]$name = "SSHKey")
    Throw-NotAdministrator -ErrorAction Stop
    # Setting up new keys
    [System.IO.FileInfo]$SSHKeyPathPrivate = (Join-Path $ENV:USERPROFILE -ChildPath ".ssh" | Join-Path -ChildPath "id_ed25519_$name")
    [System.IO.FileInfo]$SSHKeyPathPublic = ($SSHKeyPathPrivate.FullName + ".pub")
    # TODO: There's an issue here with keysetup when installing on new pc's, the return value of this function is of the directory? and not of the key created. key is ok.
    try {
        mkdir $SSHKeyPathPrivate.Directory.FullName | Write-Host #damn powershell is weird. https://social.technet.microsoft.com/Forums/en-US/57cb76d0-747a-4e77-b5c0-bf2218f5c4a7/very-odd-return-behavior?forum=winserverpowershell
    }
    catch {}
    #Set SSH key on windows
    echo yes | ssh-keygen -t ed25519 -q -C "ansible" -f $SSHKeyPathPrivate.FullName -N """" | Out-Host 
    #encoding must be ascii and not utf
    cat $SSHKeyPathPublic.FullName | Out-File -Encoding ASCII -FilePath $(Get-AuthorizedKeysFilePath) | Out-Host 
    
    #Set Permissions correctly for authorized keys file https://superuser.com/a/1605117/1220772
    try{
        $acl = Get-Acl $ENV:ProgramData\ssh\administrators_authorized_keys
        $acl.SetAccessRuleProtection($true, $false)
        $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators", "FullControl", "Allow")
        $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM", "FullControl", "Allow")
        $acl.SetAccessRule($administratorsRule)
        $acl.SetAccessRule($systemRule)
        $acl | Set-Acl
    }
    catch{}
    
    Restart-Service sshd | Out-Host 
    #Connect to SSH
    try {
        ssh localhost -i $SSHKeyPathPrivate -o StrictHostKeyChecking=no exit 0 | Out-Host 
    }
    catch {
        echo 1
    }
    return $SSHKeyPathPrivate
}
