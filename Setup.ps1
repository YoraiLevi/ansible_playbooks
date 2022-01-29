[cmdletbinding()]
param()
Import-Module $PSScriptRoot\powershell\WSL_utils.ps1 -Force
Import-Module $PSScriptRoot\powershell\SSH_utils_WINDOWS.ps1 -Force
Import-Module $PSScriptRoot\powershell\SSH_utils_WSL.ps1 -Force
Import-Module $PSScriptRoot\powershell\Ansible_utils.ps1 -Force
$ErrorActionPreference = 'Stop'
#Setup WSL
#if((isWSLInstalled)){
# if(-Not (isWSLDistroInstalled)){
#     InstallWSLDistro
# }
# Distro is installed
#}
#else{
#    throw "Install WSL"
#}

#Setup SSH on Windows
SetupAndStartSSHWindows | Out-Null #| Write-Information
$SSHKeyPathPrivateWindowsPath = CreateRegisterSSHPublickeyWindows
#Setup SSH on WSL
RegisterSSHPrivatekeyWSL $SSHKeyPathPrivateWindowsPath | Out-Null #| Write-Information
SetupSSHConnection $SSHKeyPathPrivateWindowsPath | Out-Null #| Write-Information
Write-Output $SSHKeyPathPrivateWindowsPath
#Setup Ansible on WSL
Setup-Ansible