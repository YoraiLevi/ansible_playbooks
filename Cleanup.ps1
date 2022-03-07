[cmdletbinding()]
param()
Import-Module $PSScriptRoot\powershell\WSL_utils.psm1
Import-Module $PSScriptRoot\powershell\SSH_utils_WINDOWS.psm1
Import-Module $PSScriptRoot\powershell\SSH_utils_WSL.psm1
$ErrorActionPreference = "Stop"
ClearAllSSHKeysWindows | Out-Host
ClearAllSSHKeysWSL | Out-Host