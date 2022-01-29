function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
function Throw-NotAdministrator{
    [CmdletBinding()]
     param()
    if((Test-Administrator) -eq $false){
        throw "Not Admin"
    }
}