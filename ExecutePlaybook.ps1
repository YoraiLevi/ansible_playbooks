# $playbook = 'theEVERYTHING.yml';  [switch]$v = $false; &".\ExecutePlaybook.ps1" -playbookFile ".\playbooks\$playbook" -inventoryFile .\playbooks\inventories\localWindowsWSL\ -vault_id dev@vault/uuid-client -v:$v.IsPresent | Tee-Object -FilePath "$playbook.log"
# .\ExecutePlaybook.ps1 -playbookFile .\playbooks\theEVERYTHING.yaml -keyFilePath C:\Users\devic\.ssh\id_ed25519_SSHKey -inventoryFile .\playbooks\inventories\localWindowsWSL\
# .\ExecutePlaybook.ps1 -playbookFile '.\playbooks\theEVERYTHING.yml' -inventoryFile .\playbooks\inventories\localWindowsWSL\ -vault_id dev@vault/uuid-client
[cmdletbinding()]
param([string]$playbookFile,
    [string]$keyFilePath,
    [string]$inventoryFile,
    [switch]$v = $false,
    [string]$vault_id,

    [switch]$dontClear = $false
)
Import-Module -DisableNameChecking $PSScriptRoot\powershell\Ansible_utils.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\WSL_utils.psm1 -Force
Import-Module -DisableNameChecking $PSScriptRoot\powershell\Powershell_utils.psm1

$ErrorActionPreference = 'Stop'
# $winIP = Get-WinIP
# $address = "$ENV:USERNAME@$winIP"
if ((Is-NullOrEmpty $keyFilePath) -eq $true) {
    $keyFile = &$PSScriptRoot\Setup.ps1
}
else {
    $keyFile = $keyFilePath
}
#Setup-Ansible
Execute-Playbook -playbookFile $playbookFile -keyFile $keyFile -inventoryFile $inventoryFile -vault_id $vault_id -v:$v.IsPresent
if ((Is-NullOrEmpty $keyFilePath) -eq $true) {
    &$PSScriptRoot\Cleanup.ps1
}