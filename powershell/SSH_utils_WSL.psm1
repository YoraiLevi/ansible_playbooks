Import-Module $PSScriptRoot\WSL_utils.psm1
function SetupAndStartSSHWSL{
    param([string]$Distro = "Ubuntu-20.04")
}
function ClearSSHKeyWSL{
    param([string]$Distro = "Ubuntu-20.04")
}
function ClearAllSSHKeysWSL{
    param([string]$Distro = "Ubuntu-20.04")
    try{
    (wsl rm -r ~/.ssh) | Out-Host 
    }
    catch{}
}
function RegisterSSHPrivatekeyWSL {
  param([System.IO.FileInfo]$SSHKeyPathPrivate = (Join-Path $ENV:HOMEPATH .ssh | Join-Path -ChildPath id_ed25519_SSHKey))
  $PrivateKeyPath = "~/.ssh/$($SSHKeyPathPrivate.Name)"
  (wsl mkdir `-p ~/.ssh `&`& cd ~/.ssh `&`& cp $SSHKeyPathPrivate.FullName ~/.ssh `&`& chmod 600 $PrivateKeyPath) | Out-Host 
}
function SetupSSHConnection{
   param([System.IO.FileInfo]$SSHKeyPathPrivate = (Join-Path $ENV:HOMEPATH .ssh | Join-Path -ChildPath id_ed25519_SSHKey))
   $PrivateKeyPath = "~/.ssh/$($SSHKeyPathPrivate.Name)"
   $winIP = Get-WinIP
   $address = "$ENV:USERNAME@$winIP"
   $command = "ssh $address -i $PrivateKeyPath -o StrictHostKeyChecking=no exit 0"
   wsl $command | Out-Host
}