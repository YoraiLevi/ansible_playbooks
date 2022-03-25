[cmdletbinding()]
param()
Import-Module -DisableNameChecking $PSScriptRoot\powershell\WSL_utils.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\SSH_utils_WINDOWS.psm1
Import-Module -DisableNameChecking $PSScriptRoot\powershell\SSH_utils_WSL.psm1
$ErrorActionPreference = "Stop"
ClearAllSSHKeysWindows | Out-Host
ClearAllSSHKeysWSL | Out-Host