Import-Module -DisableNameChecking $PSScriptRoot\WSL_utils.psm1
Import-Module -DisableNameChecking $PSScriptRoot\Powershell_utils.psm1
function Setup-Ansible {
    wsl '--user root apt update && apt install ansible python3-pip ohai -y' #setup module can use ohai.
    wsl 'ansible-galaxy collection install ansible.windows'
    wsl 'ansible-galaxy collection install community.windows'
    wsl 'ansible-galaxy collection install chocolatey.chocolatey'
    # wsl 'pip install "pywinrm>=0.3.0"'
}


function Execute-Playbook {
    param([string]$playbookFile,
        #[ValidatePattern('"')]
        [string]$keyFile,
        [string]$inventoryFile,
        [string]$vault_id,
        [switch]$v = $false
    )
    $playbookFile = Normalize-Path $playbookFile
    $keyFile = Normalize-Path $keyFile
    $inventoryFile = Normalize-Path $inventoryFile
   
    ExecutePlaybookLocalWindows -playbookFile $playbookFile -keyFile $keyFile -vault_id $vault_id -inventoryFile $inventoryFile -v:$v.IsPresent
}

function ExecutePlaybookLocalWindows {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$playbookFile,
        #[ValidatePattern('"')] "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$"
        [System.IO.FileInfo]$keyFile,
        [System.IO.FileInfo]$inventoryFile,
        [string]$extra_vars,
        [string]$vault_id,
        [switch]$v
          
    )
    $playbookPath = $playbookFile.FullName
    if ((Is-NullOrEmpty $keyFile) -eq $false){
        $keyFileName = $keyFile.BaseName
        $extra_vars = "winlocal_ssh_private_key_file=~/.ssh/$keyFileName $extra_vars"
    }
    if ((Is-NullOrEmpty $extra_vars) -eq $false){
        $extra_vars =   "--extra-vars '$extra_vars'"
    }
    if ((Is-NullOrEmpty $inventoryFile) -eq $false){
        $i = "-i"
    }
    if ((Is-NullOrEmpty $vault_id) -eq $false){
        $vault_id = "--vault-id '$vault_id'"
    }
    if ($v.IsPresent -eq $true) {
        $vvv = '-vvvvv'
    }
    $command =
    @"
ansible-playbook $vvv $i $inventoryFile $playbookPath $vault_id $extra_vars;
"@
    wsl $command
}
