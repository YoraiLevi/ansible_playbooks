[cmdletbinding()]
param()
Import-Module -DisableNameChecking $PSScriptRoot\powershell\WSL_utils.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\SSH_utils_WINDOWS.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\SSH_utils_WSL.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\Ansible_utils.psm1
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
SetupAndStartSSHWindows | Out-Host #| Write-Information
$SSHKeyPathPrivateWindowsPath = CreateRegisterSSHPublickeyWindows
#Setup SSH on WSL
RegisterSSHPrivatekeyWSL $SSHKeyPathPrivateWindowsPath | Out-Host #| Write-Information
SetupSSHConnection $SSHKeyPathPrivateWindowsPath | Out-Host #| Write-Information
Write-Host $SSHKeyPathPrivateWindowsPath
Write-Output $SSHKeyPathPrivateWindowsPath
#Setup Ansible on WSL
Setup-Ansible | Out-Host