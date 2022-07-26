#https://stackoverflow.com/questions/70254096/system-io-fileinfo-and-relative-paths
Import-Module -DisableNameChecking $PSScriptRoot\CMD_utils.psm1

function isWSLInstalled {
    return -Not [string]::IsNullOrEmpty($(Get-WSLExe))
}
function Get-WSLExe {
    $val =  ((Get-Command wsl -All -ErrorAction Stop) | Where-Object -Property Source -Like "*.exe")
    if($val.length -ge 2){
        throw "Something is wrong: $val"
    }
    return $val.Source
}

function wsl {
    #TODO Optimize args preprocessing
    #TODO make bash multiline \ work.
    #TODO Add whatif and confirm
    #TODO continuous std out rather than at end
    $WSLExe = Get-WSLExe
    $args | %{Write-Information $_}
    $args = ($args -join ' ').split()
    $args = $args | ForEach-Object { #foreach begi
        $val = $_;
        try {
            if ([string]::IsNullOrWhiteSpace($val)) { throw 'Whitespace or null' };
            if ($val.StartsWith('/')) { throw 'Maybe WSL path, not converting' };
            if ($val.StartsWith('\')) { throw 'Bash multiline command, not converting' };
            if ($val.StartsWith('~')) { throw 'Maybe WSL path, not converting' };
            if ($val.StartsWith('$')) { throw 'Maybe bash argument, not converting' };
            $pathObject = ([System.IO.FileInfo]($val)); # Throws if path cannot ever exist on windows.
            if ([System.IO.Path]::IsPathRooted($val)) {
                #Convert root path
                $path = $pathObject.FullName;   
            }
            #elif($val.StartsWith("./") -or $val.StartsWith(".\")){ #Convert relative path
            #$path = $val
            #}
            else {
                $path = $val
                #throw "Likely a random argument"
            }
            $path = $path.replace('\', '\\').replace(' ', '\ ')
            # if ($PSVersionTable.PSVersion -ge [Version]'7.2') {
            #     #https://stackoverflow.com/a/59376457/12603110
            #     $path = (&(WSLExe) wslpath $path 2> $null); 
            # }
            # # Weirdly indents first line when stderr is redirected. weird.
            # else {
                #https://stackoverflow.com/a/60386296/12603110
                $psCommand = "$(WSLExe) wslpath $path"
                $cmdCommand = Convert-StringCMD $psCommand
                Write-Information "Executing: $cmdCommand"
                $path = $(cmd.exe /c $cmdCommand" 2>nul") #delete stderr cuz irrelevant when failure
                $path = if($path.contains(' ')){"`"$path`""}else{$path}
            # }
            if ($LASTEXITCODE -ne 0) { throw 'failed to convert path' }
            return $path
        }
        catch {
            return $val
        }
    }
    $command = $args -join ' ' | ForEach-Object { $_ -replace [char]0, '' } | ForEach-Object { $_ -replace "`r?`n", "`r`n" }
    Write-Information "Executing: wsl $command "  
    # if ($PSCmdlet.ShouldProcess("wsl $command")){
        
    if (-Not [string]::IsNullOrEmpty($command)) {
        try {
            # if ($PSVersionTable.PSVersion -ge [Version]'7.2') {
            #     #https://stackoverflow.com/a/59376457/12603110
            #     &(WSLExe) $command.Split() *>&1 |  Tee-Object -Variable output | ForEach-Object { $_ -replace [char]0, '' } |  ForEach-Object { Write-Output "$_"; }# `&`& exit 
            # }
            # else {
                #https://stackoverflow.com/a/60386296/12603110
                $psCommand = "$(WSLExe) $($command.Split())"
                $cmdCommand = Convert-StringCMD $psCommand
                cmd.exe /c $cmdCommand" 2>&1" | ForEach-Object { $_ -join ('') } | ForEach-Object { $_ -replace [char]0, '' } | ForEach-Object { $_.trimend() } | ForEach-Object { $_ -replace "`r?`n", "`r`n" }  | Tee-Object -Variable output | ForEach-Object { Write-Output "$_"; }
            # }
        }
        catch { $_ | Format-List * -Force | Out-String }
        
        # https://github.com/microsoft/WSL/issues/7865 -- truncate excess null chars
        $output = (($output -join ('' | Out-String)) | ForEach-Object { $_ -replace [char]0, '' })
        Write-Host `r -NoNewline
        [Console]::Out.Flush() 
        # https://github.com/microsoft/WSL/issues/6192 -- help returns -1 exit code
        Write-Information "Exited with code: $lastexitcode"
        if ($lastexitcode -eq 0 -or $lastexitcode -eq -1) {
        }
        else { 
            Write-Error $output
        }
    }
    else {
        Write-Information 'Starting WSL...'
        &(WSLExe)
    }
    #}
}


function isWSLDistroInstalled {
    $ErrorActionPreference = 'Stop'
    if(isWSLInstalled){
        #Distro is installed
        return (wsl cat /proc/version | Out-String) -ne (wsl --list | Out-String)
    }
    return $false
    # wsl --help == wsl --list (no wsl2?) 
    # wsl --list == wsl bashcommand (no repo)
    # #return $true #--list returns error but there is and issue with stderr
    # try {
    #     $list = -join (wsl '--list')
    # }
    # catch {
    #     return $false
    # }
    # if ($LASTEXITCODE -ne 0) {
    #     return $false
    # }
    # #    $help = wsl "--help" | Out-String
    # #    # When a distro is installed list and help have different output
    # #    return -Not ($help -eq $list) -and 
    # return $list.IndexOf($Distro, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0
    
}
# function InstallWSL {
    # Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    # choco install wsl2 -y
    # choco install wsl-ubuntu-2004 -y
# }
# function InstallWSLDistro {
    # param([string]$Distro = 'Ubuntu-20.04')
    # if (isWSLInstalled -eq $false) { return }

    #    wsl "--install"
    #    wsl "--update"
    #    wsl "--shutdown"
    #    wsl "--install -d $Distro"
# }
#https://devblogs.microsoft.com/commandline/integrate-linux-commands-into-windows-with-powershell-and-the-windows-subsystem-for-linux/
#Connect to SSH
#ssh `$win_ip4 -i ~/.ssh/$((Get-ChildItem $SSHKeyPathPrivate).name) -o StrictHostKeyChecking=no exit;
#"

#bash -c "mkdir -p ~/.ssh && cp $(ConvertPath $SSHKeyPathPrivate) `"`$_`" && chmod 600 `"`$_`"/$((Get-ChildItem $SSHKeyPathPrivate).name)"
#Connect to SSH
#bash -c "win_ip4=`$(route -n | grep -m1 '^0.0.0.0' | awk '{ print `$2; }');
#ssh `$win_ip4 -i ~/.ssh/$((Get-ChildItem $SSHKeyPathPrivate).name) -o StrictHostKeyChecking=no exit;
#"

function Get-WinIP() {
    wsl cat /etc/resolv.conf `| grep nameserver `| cut `-d `' `' `-f 2
}
function Get-WSLIP() {
    wsl hostname -I
}
function Set-DefaultWSLUser() {
}
function Create-WSLUser() {
}
# if(-Not (isWSLDistroInstalled)){throw "Couldn't import, WSL is not installed"}
