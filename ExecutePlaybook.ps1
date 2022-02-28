# .\ExecutePlaybook.ps1 -playbookFile .\playbooks\theEVERYTHING.yaml -keyFilePath C:\Users\devic\.ssh\id_ed25519_SSHKey -inventoryFile .\playbooks\inventories\localWindowsWSL\
[cmdletbinding()]
param([string]$playbookFile,
    [string]$keyFilePath,
    [string]$inventoryFile,
    [switch]$v = $false
)
Import-Module $PSScriptRoot\powershell\Ansible_utils.ps1 -Force
Import-Module $PSScriptRoot\powershell\WSL_utils.ps1 -Force

$ErrorActionPreference = 'Stop'
# $winIP = Get-WinIP
# $address = "$ENV:USERNAME@$winIP"
if ((Is-NullOrEmpty $keyFilePath) -eq $true) {
    $keyFile = .\Setup.ps1
}
else {
    $keyFile = $keyFilePath
}
#Setup-Ansible
Execute-Playbook -playbookFile $playbookFile -keyFile $keyFile -inventoryFile $inventoryFile -v:$v.IsPresent
.\Cleanup.ps1