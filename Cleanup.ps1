[cmdletbinding()]
param()
Import-Module $PSScriptRoot\powershell\WSL_utils.ps1 -Force
Import-Module $PSScriptRoot\powershell\SSH_utils_WINDOWS.ps1 -Force
Import-Module $PSScriptRoot\powershell\SSH_utils_WSL.ps1 -Force
$ErrorActionPreference = "Stop"
ClearAllSSHKeysWindows | Out-Null
ClearAllSSHKeysWSL | Out-Null