# Ansible

## Setup windows with Ansible automatically

```
$playbook = 'theEVERYTHING.yml'; $code = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/YoraiLevi/ansible_playbooks/master/automatedSetup.ps1'); Invoke-Command  $([Scriptblock]::Create(($code) -join "`r`n")) -ArgumentList $playbook
```

```
$playbook = 'ping.yml'; $code = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/YoraiLevi/ansible_playbooks/master/automatedSetup.ps1'); Invoke-Command  $([Scriptblock]::Create(($code) -join "`r`n")) -ArgumentList $playbook
```

TODOS:
* pin to quick access https://stackoverflow.com/questions/30051634/is-it-possible-programmatically-add-folders-to-the-windows-10-quick-access-panel
* include_vars that allows "patching"/overwriting existing keys, recusive patching
* inheritable include_vars - "works kinda" - write action that includes vars and merges
* easily remove "omitted" keys from dict
* read any file format (utf16 issue) - _needle function
* find files module - _needle function
* create modules intead of roles for windows
* auto scan for custom facts module. linux + windows with no error
* win_reg_file cannot process hex: type correctly (binary) aka no capslock .reg
* Issue with installing python (when not installed) via choco
* download_file needs the directory to be already made
* Task scheduler task in background https://superuser.com/a/1332982/1220772
* Install Interception Driver on laptop (for ahk) https://github.com/evilC/AutoHotInterception#setup
* set login keyboard <https://social.technet.microsoft.com/Forums/windows/en-US/6a21b20a-4d04-460a-b672-968de78c6646/command-line-tools-to-completely-change-regioninput-language-for-default-user-and-welcome-screen?forum=winservergen>
* an alternative to settings the "known folders" is via registries: https://www.ubackup.com/articles/cant-move-the-folder-because-there-is-a-folder-onedrive.html#:~:text=Why%20Can't%20Move%20Documents,t%20return%20to%20normal%20values.
