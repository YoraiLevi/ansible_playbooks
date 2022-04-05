# Ansible

## Setup windows with Ansible automatically

```
$playbook = 'theEVERYTHING.yml'
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/YoraiLevi/MyFuckingWikiOfEverything/master/Ansible/automatedSetup.ps1'))
```

TODOS:

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
