Import-Module $PSScriptRoot\WSL_utils.ps1
Import-Module $PSScriptRoot\Powershell_utils.ps1 -Force
function Setup-Ansible {
    wsl '--user root apt update && apt install ansible python3-pip -y'
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
        [switch]$v = $false
    )
    $playbookFile = Normalize-Path $playbookFile
    $keyFile = Normalize-Path $keyFile
    $inventoryFile = Normalize-Path $inventoryFile
   
    ExecutePlaybookLocalWindows -playbookFile $playbookFile  -keyFile $keyFile -inventoryFile $inventoryFile -v:$v.IsPresent
}
#https://www.google.com/search?q=check+if+ip+is+localhost&oq=check+if+ip+is+localnhost&aqs=edge.1.69i57j0i22i30l4.4351j0j1&sourceid=chrome&ie=UTF-8
# function ExecutePlaybookLocalWindows {
#     param([System.IO.FileInfo]$playbookFile,
#         #[ValidatePattern('"')] "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$"
#         [string]$address,
#         [System.IO.FileInfo]$keyFile,
#         [System.IO.FileInfo]$inventoryFile,
#         [string]$extra_vars,
#         [switch]$v
          
#     )
#     if ((Is-NullOrEmpty $inventoryFile) -eq $false){
#         $i = "-i"
#         Write-Host "YAY"
#     }
#     else{
#         Write-Host "NEY"
#     }
#     if ($v.IsPresent -eq $true) {
#         $vvv = '-vvv'
#     }
#     $playbookPath = $playbookFile.FullName
#     $keyFileName = $keyFile.BaseName
#     $command =
#     @"
# ansible-playbook $vvv $i $inventoryFile $playbookPath --extra-vars 'winlocal_ssh_private_key_file=~/.ssh/$keyFileName $extra_vars';
# "@
#     wsl $command
# }

#dynamic inventory
#ansible-playbook -i inventories/localWindowsWSL /mnt/c/Users/devic/Documents/Sources/etc/Ansible/playbooks/ping.yml --extra-vars 'ansible_ssh_private_key_file=/home/user/.ssh/id_ed25519_SSHKey'
# --ssh-common-args='-o StrictHostKeyChecking=no'
#ansible-playbook -i playbooks/inventories/localWindowsWSL/ /mnt/c/Users/devic/Documents/Sources/etc/Ansible/playbooks/ping.yml --extra-vars 'ansible_ssh_private_key_file=/home/user/.ssh/id_ed25519_SSHKey' --ssh-common-args='-o StrictHostKeyChecking=no'
#bash -c "ansible-playbook ping.yml -i inventories/personal --extra-vars 'ansible_ssh_private_key_file=~/.ssh/$((Get-ChildItem $SSHKeyPathPrivate).name)'"






function ExecutePlaybookLocalWindows {
    param([Parameter(Mandatory=$true)][System.IO.FileInfo]$playbookFile,
        #[ValidatePattern('"')] "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$"
        [System.IO.FileInfo]$keyFile,
        [System.IO.FileInfo]$inventoryFile,
        [string]$extra_vars,
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
    if ($v.IsPresent -eq $true) {
        $vvv = '-vvvvv'
    }
    $command =
    @"
ansible-playbook $vvv $i $inventoryFile $playbookPath $extra_vars;
"@
    wsl $command
}
