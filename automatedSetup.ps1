# .\Ansible\automatedSetup.ps1 'ping.yml' 1 2 'b'
# Invoke-Command  $([Scriptblock]::Create((cat .\Ansible\automatedSetup.ps1) -join "`r`n")) -ArgumentList 'ping.yml','DEV'
param($playbook = 'theEVERYTHING.yml', $branch = 'master', [switch]$v = $false)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
function Autologon {
    param([string]$BackupFile)
    Throw-NotAdministrator
    $cred = Get-Credential -Message "Autologin:" -UserName $env:USERNAME
    Set-SecureAutoLogon -Username $cred.UserName -Password $cred.Password -BackupFile $BackupFile
}
function Set-SecureAutoLogon {
    <#
        .SYNOPSIS
        Enables auto logon using the specified username and password.
        
        .PARAMETER  Username
        The username of the user to automatically logon as.
        
        .PARAMETER  Password
        The password for the user to automatically logon as.
        
        .PARAMETER  Domain
            The domain of the user to automatically logon as.
            
            .PARAMETER  AutoLogonCount
            The number of logons that auto logon will be enabled.
            
            .PARAMETER  RemoveLegalPrompt
            Removes the system banner to ensure intervention-less logon.
            
            .PARAMETER  BackupFile
            If specified the existing settings such as the system banner text will be backed up to the specified file.
            
            .EXAMPLE
            PS C:\> Set-SecureAutoLogon `
            -Username $env:USERNAME `
            -Password (Read-Host -AsSecureString) `
            -AutoLogonCount 2 `
                    -RemoveLegalPrompt `
                    -BackupFile "C:\WinlogonBackup.xml"
                    
                    .INPUTS
            None.
            
            .OUTPUTS
            None.
            
            .NOTES
            Revision History:
            2011-04-19 : Andy Arismendi - Created.
                2011-09-29 : Andy Arismendi - Changed to use LSA secrets to store password securely.
                
                .LINK
                https://support.microsoft.com/kb/324737
                
                .LINK
                https://msdn.microsoft.com/en-us/library/aa378750
                
                #>
    # https://github.com/chocolatey/boxstarter/blob/9b8034c19eff2a97ac3d51ea76915542b36ee775/Boxstarter.Bootstrapper/Set-SecureAutoLogon.ps1
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]
        $Username,
        
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [System.Security.SecureString]
        $Password,
        
        [string]
        $Domain,
        
        [Int]
        $AutoLogonCount,
        
        [switch]
        $RemoveLegalPrompt,
        
        [string]
        $BackupFile
    )
        
    begin {
        [string] $WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
        [string] $WinlogonBannerPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            
        [string] $Enable = 1
        [string] $Disable = 0
            
        #region C# Code to P-invoke LSA LsaStorePrivateData function.
        Add-Type @"
            using System;
            using System.Collections.Generic;
            using System.Text;
            using System.Runtime.InteropServices;
            
            namespace ComputerSystem
            {
                public class LSAutil
                {
                    [StructLayout(LayoutKind.Sequential)]
                    private struct LSA_UNICODE_STRING
                    {
                        public UInt16 Length;
                        public UInt16 MaximumLength;
                        public IntPtr Buffer;
                    }
                    
                    [StructLayout(LayoutKind.Sequential)]
                    private struct LSA_OBJECT_ATTRIBUTES
                    {
                        public int Length;
                        public IntPtr RootDirectory;
                        public LSA_UNICODE_STRING ObjectName;
                        public uint Attributes;
                        public IntPtr SecurityDescriptor;
                        public IntPtr SecurityQualityOfService;
                    }
                    
                    private enum LSA_AccessPolicy : long
                    {
                        POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
                        POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
                        POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
                        POLICY_TRUST_ADMIN = 0x00000008L,
                        POLICY_CREATE_ACCOUNT = 0x00000010L,
                        POLICY_CREATE_SECRET = 0x00000020L,
                        POLICY_CREATE_PRIVILEGE = 0x00000040L,
                        POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
                        POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
                        POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
                        POLICY_SERVER_ADMIN = 0x00000400L,
                        POLICY_LOOKUP_NAMES = 0x00000800L,
                        POLICY_NOTIFICATION = 0x00001000L
                    }
                    
                    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                    private static extern uint LsaRetrievePrivateData(
                                IntPtr PolicyHandle,
                                ref LSA_UNICODE_STRING KeyName,
                                out IntPtr PrivateData
                    );
                    
                    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                    private static extern uint LsaStorePrivateData(
                        IntPtr policyHandle,
                        ref LSA_UNICODE_STRING KeyName,
                        ref LSA_UNICODE_STRING PrivateData
                        );
                        
                        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                        private static extern uint LsaOpenPolicy(
                            ref LSA_UNICODE_STRING SystemName,
                            ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
                            uint DesiredAccess,
                            out IntPtr PolicyHandle
                            );
                            
                            [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                            private static extern uint LsaNtStatusToWinError(
                                uint status
                                );
                                
                                [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                                private static extern uint LsaClose(
                                    IntPtr policyHandle
                                    );
    
                                    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
                                    private static extern uint LsaFreeMemory(
                                        IntPtr buffer
                    );
    
                    private LSA_OBJECT_ATTRIBUTES objectAttributes;
                    private LSA_UNICODE_STRING localsystem;
                    private LSA_UNICODE_STRING secretName;
                    
                    public LSAutil(string key)
                    {
                        if (key.Length == 0)
                        {
                            throw new Exception("Key length zero");
                        }
                        
                        objectAttributes = new LSA_OBJECT_ATTRIBUTES();
                        objectAttributes.Length = 0;
                        objectAttributes.RootDirectory = IntPtr.Zero;
                        objectAttributes.Attributes = 0;
                        objectAttributes.SecurityDescriptor = IntPtr.Zero;
                        objectAttributes.SecurityQualityOfService = IntPtr.Zero;
                        
                        localsystem = new LSA_UNICODE_STRING();
                        localsystem.Buffer = IntPtr.Zero;
                        localsystem.Length = 0;
                        localsystem.MaximumLength = 0;
                        
                        secretName = new LSA_UNICODE_STRING();
                        secretName.Buffer = Marshal.StringToHGlobalUni(key);
                        secretName.Length = (UInt16)(key.Length * UnicodeEncoding.CharSize);
                        secretName.MaximumLength = (UInt16)((key.Length + 1) * UnicodeEncoding.CharSize);
                    }
                    
                    private IntPtr GetLsaPolicy(LSA_AccessPolicy access)
                    {
                        IntPtr LsaPolicyHandle;
    
                        uint ntsResult = LsaOpenPolicy(ref this.localsystem, ref this.objectAttributes, (uint)access, out LsaPolicyHandle);
    
                        uint winErrorCode = LsaNtStatusToWinError(ntsResult);
                        if (winErrorCode != 0)
                        {
                            throw new Exception("LsaOpenPolicy failed: " + winErrorCode);
                        }
                        
                        return LsaPolicyHandle;
                    }
    
                    private static void ReleaseLsaPolicy(IntPtr LsaPolicyHandle)
                    {
                        uint ntsResult = LsaClose(LsaPolicyHandle);
                        uint winErrorCode = LsaNtStatusToWinError(ntsResult);
                        if (winErrorCode != 0)
                        {
                            throw new Exception("LsaClose failed: " + winErrorCode);
                        }
                    }
                    
                    public void SetSecret(string value)
                    {
                        LSA_UNICODE_STRING lusSecretData = new LSA_UNICODE_STRING();
    
                        if (value.Length > 0)
                        {
                            //Create data and key
                            lusSecretData.Buffer = Marshal.StringToHGlobalUni(value);
                            lusSecretData.Length = (UInt16)(value.Length * UnicodeEncoding.CharSize);
                            lusSecretData.MaximumLength = (UInt16)((value.Length + 1) * UnicodeEncoding.CharSize);
                        }
                        else
                        {
                            //Delete data and key
                            lusSecretData.Buffer = IntPtr.Zero;
                            lusSecretData.Length = 0;
                            lusSecretData.MaximumLength = 0;
                        }
                        
                        IntPtr LsaPolicyHandle = GetLsaPolicy(LSA_AccessPolicy.POLICY_CREATE_SECRET);
                        uint result = LsaStorePrivateData(LsaPolicyHandle, ref secretName, ref lusSecretData);
                        ReleaseLsaPolicy(LsaPolicyHandle);
                        
                        uint winErrorCode = LsaNtStatusToWinError(result);
                        if (winErrorCode != 0)
                        {
                            throw new Exception("StorePrivateData failed: " + winErrorCode);
                        }
                    }
                }
            }
"@
        #endregion
    }
    
    process {
        
        try {
            $ErrorActionPreference = "Stop"
    
            $decryptedPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            )
                
            if ($BackupFile) {
                # Initialize the hash table with a string comparer to allow case sensitive keys.
                # This allows differentiation between the winlogon and system policy logon banner strings.
                $OrigionalSettings = New-Object System.Collections.Hashtable ([system.stringcomparer]::CurrentCulture)
                    
                $OrigionalSettings.AutoAdminLogon = (Get-ItemProperty $WinlogonPath ).AutoAdminLogon
                $OrigionalSettings.ForceAutoLogon = (Get-ItemProperty $WinlogonPath).ForceAutoLogon
                $OrigionalSettings.DefaultUserName = (Get-ItemProperty $WinlogonPath).DefaultUserName
                $OrigionalSettings.DefaultDomainName = (Get-ItemProperty $WinlogonPath).DefaultDomainName
                if ((Get-ItemProperty $WinlogonPath).DefaultPassword) {
                    $OrigionalSettings.DefaultPassword = (Get-ItemProperty $WinlogonPath).DefaultPassword
                    Remove-ItemProperty -Path $WinlogonPath -Name DefaultPassword -Force
                }
                $OrigionalSettings.AutoLogonCount = (Get-ItemProperty $WinlogonPath).AutoLogonCount
                
                # The winlogon logon banner settings.
                $OrigionalSettings.LegalNoticeCaption = (Get-ItemProperty $WinlogonPath).LegalNoticeCaption
                $OrigionalSettings.LegalNoticeText = (Get-ItemProperty $WinlogonPath).LegalNoticeText
                
                # The system policy logon banner settings.
                $OrigionalSettings.legalnoticecaption = (Get-ItemProperty $WinlogonBannerPolicyPath).legalnoticecaption
                $OrigionalSettings.legalnoticetext = (Get-ItemProperty $WinlogonBannerPolicyPath).legalnoticetext
                
                $OrigionalSettings | Export-Clixml -Depth 10 -Path $BackupFile
            }
            
            # Store the password securely.
            $lsaUtil = New-Object ComputerSystem.LSAutil -ArgumentList "DefaultPassword"
            $lsaUtil.SetSecret($decryptedPass)
            
            # Store the autologon registry settings.
            Set-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon -Value $Enable -Force
    
            Set-ItemProperty -Path $WinlogonPath -Name DefaultUserName -Value $Username -Force
            Set-ItemProperty -Path $WinlogonPath -Name DefaultDomainName -Value $Domain -Force
            
            if ($AutoLogonCount) {
                Set-ItemProperty -Path $WinlogonPath -Name AutoLogonCount -Value $AutoLogonCount -Force
            }
            else {
                try { Remove-ItemProperty -Path $WinlogonPath -Name AutoLogonCount -ErrorAction stop } catch { $global:error.RemoveAt(0) }
            }
            
            if ($RemoveLegalPrompt) {
                Set-ItemProperty -Path $WinlogonPath -Name LegalNoticeCaption -Value $null -Force
                Set-ItemProperty -Path $WinlogonPath -Name LegalNoticeText -Value $null -Force
                
                Set-ItemProperty -Path $WinlogonBannerPolicyPath -Name legalnoticecaption -Value $null -Force
                Set-ItemProperty -Path $WinlogonBannerPolicyPath -Name legalnoticetext -Value $null -Force
            }
        }
        catch {
            throw 'Failed to set auto logon. The error was: "{0}".' -f $_
        }
    
    }
}
function Remove-SecureAutoLogon {
    # https://github.com/chocolatey/boxstarter/blob/9b8034c19eff2a97ac3d51ea76915542b36ee775/Boxstarter.Bootstrapper/Cleanup-Boxstarter.ps1
    Param(
        [string] $BackupFile
    )
    Write-Host "Cleaning up autologon registry keys" -Verbose
    $winLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    if ($BackupFile -and (Test-Path $BackupFile -ErrorAction SilentlyContinue)) {
        $winlogonProps = Import-CLIXML -Path $BackupFile
    }
    @("DefaultUserName", "DefaultDomainName", "DefaultPassword", "AutoAdminLogon") | % {
        if (!$winlogonProps -or !$winlogonProps.ContainsKey($_)) {
            Remove-ItemProperty -Path $winLogonKey -Name $_ -ErrorAction SilentlyContinue
        }
        else {
            Set-ItemProperty -Path $winLogonKey -Name $_ -Value $winlogonProps[$_]
        }
    }
}
function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
function Throw-NotAdministrator {
    if ((Test-Administrator) -eq $false) {
        throw "Not Admin"
    }
}
function Restart-Computer {  
    Microsoft.PowerShell.Management\Restart-Computer -Force
    exit
}
function Install-Chocolatey {
    if (-not (Test-Path $Profile)) {
        New-Item $PROFILE -ErrorAction SilentlyContinue -Force
    }
    if (-not $env:ChocolateyInstall -or -not (Test-Path "$env:ChocolateyInstall\bin\choco.exe")) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Restart-Computer
    }
}
function Installed-WSL2 {
    return (wsl --list | out-string) -ne (wsl --help | out-string)
}
function Installed-Distro {
    return (wsl cat /proc/version | Out-String) -ne (wsl --list | Out-String)  
}
function choco() { $ErrorActionPreference = "Stop"; choco.exe $args '-y'; if ($lastexitcode -ne 0) { throw } }
$taskName = "automatedSetup"
$localdir = $(Join-Path $env:ProgramData $taskName)
Start-Transcript -IncludeInvocationHeader -Append -OutputDirectory $localdir

Throw-NotAdministrator
$scriptPath = $MyInvocation.MyCommand.Path
$TEMP = Join-Path $env:TEMP $(New-Guid) | % { mkdir $_ } #$env:TEMP
$autoLoginBackupFilePath = $(Join-Path $localdir 'backup.autologon')
$repoUrl = "https://github.com/YoraiLevi/ansible_playbooks/archive/refs/heads/$branch.zip"

$winLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$winLogon = (Get-ItemProperty -Path $winLogonKey -ErrorAction SilentlyContinue)
if ($winLogon.AutoAdminLogon -ne 1 -or $winLogon.DefaultUserName -ne $env:USERNAME) {
    Autologon -BackupFile $autoLoginBackupFilePath
}
# runs from internet
if (-not $scriptPath) {
    $archivePath = (Join-Path $TEMP "$branch.zip")
    $extractPath = $(Join-Path $TEMP "$branch")
    Invoke-WebRequest $repoUrl -OutFile $archivePath
    Expand-Archive -Path $archivePath $extractPath -Force #Overwrites
    # $files = Expand-Archive -Path $archivePath $TEMP -Force -PassThru #Overwrites
    $files = Get-ChildItem -Recurse -Path $extractPath -Filter "$taskName.ps1"
    $scriptPath = $files | Where-Object { $_.Name -eq "$taskName.ps1" } | select -First 1 | select -ExpandProperty FullName
}

$executionPolicyCommand = "Set-ExecutionPolicy Bypass -Scope Process -Force"
$commandArguments = ($args + ($PSBoundParameters.GetEnumerator() | foreach { "-{0} {1}" -f $_.Key, $_.Value })) -join ' '
$command = "$executionPolicyCommand; &`"$scriptPath`" $commandArguments"
# Schedule task if needed
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew -Priority 0
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -Command `"$command`""
    Register-ScheduledTask -Trigger $trigger -Action $action -TaskName $taskName -RunLevel Highest -Settings $settings
}
try {
    Install-Chocolatey
    while ($true) {
        try {
            if (Installed-Distro) {
                #distro installed. no need to do anything.
                Write-Host "Distro is installed..."
                break;
            }
            if (-not (Installed-WSL2)) {
                Write-Host "Attempting to install wsl2"
                choco install wsl2 --params "/Version:2 /Retry:true"
            }
            elseif (-not (Installed-Distro)) {
                # for aesthetics make sure wsl2 is registered in chocolatey
                Write-Host "Making sure chocolatey has wsl2 listed"
                choco install wsl2 --params "/Version:2 /Retry:true"
                Write-Host "Attempting to install wsl-ubuntu-2004"
                wsl --update # needed to register distro
                wsl --shutdown
                try {
                    choco install wsl-ubuntu-2004 --params "/InstallRoot:true"
                }
                catch {
                    Write-Output $_
                }
                Write-Host "Waiting for distro to register..."
                while (-not (Installed-Distro)) {
                    Start-Sleep -s 1
                }
                wsl --update
                wsl --shutdown
            }
        }
        catch {
            Write-Host "caught error, lastexitcode: $LASTEXITCODE"; Write-Host $_;
            # https://docs.chocolatey.org/en-us/configuration#exit-codes
            if ($LASTEXITCODE -eq 350 -or $LASTEXITCODE -eq 3010 -or $LASTEXITCODE -eq 1604 -or $LASTEXITCODE -eq 1603) {
                echo "Restarting..."
                Restart-Computer
                exit 0
            }
        }
    }

    # Initialized windows
    if ( Installed-WSL2 -and Installed-Distro) {
        $ansibleDir = (get-item $scriptPath).Directory
        $prevPWD = $PWD
        cd $ansibleDir;
        iex $executionPolicyCommand
        &".\ExecutePlaybook.ps1" -playbookFile ".\playbooks\$playbook" -inventoryFile .\playbooks\inventories\localWindowsWSL\ -vault_id dev@vault/uuid-client -v:$v.IsPresent | Tee-Object -FilePath "$playbook.log"
        cd $prevPWD;
        
    }
}
finally {
    Write-Output "Exiting... $lastexitcode"
    Pause
}
if (Test-Path $autoLoginBackupFilePath) {
    Remove-SecureAutoLogon -BackupFile $autoLoginBackupFilePath
    rm $autoLoginBackupFilePath -ErrorAction SilentlyContinue -Force
}
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Stop-Transcript
