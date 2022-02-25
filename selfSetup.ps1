#Make sure wsl is installed.
if (-Not (Get-Command wsl.exe)) {
Write-Information "WSL is not installed, installing with boxstarters."
$cred = Get-Credential -Message "admin rights are required to install with chocolatey"
$boxstarterPackage = "https://raw.githubusercontent.com/YoraiLevi/MyFuckingWikiOfEverything/master/Ansible/SetupWSL.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1')); Get-Boxstarter -Force
Install-BoxstarterPackage -PackageName $boxstarterPackage -Credential $cred
}