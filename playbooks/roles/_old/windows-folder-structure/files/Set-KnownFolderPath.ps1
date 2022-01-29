param($KnownFolder,$Target)
Import-Module $PSScriptRoot/KnownFolderPath.ps1 -Force
$Target=(resolve-path $Target).path.TrimEnd('\') 
$Path=""
if((Get-KnownFolderPath $KnownFolder ([ref]$Path)) -eq 0){
    if((join-path (resolve-path $Path).path '') -eq (join-path (resolve-path $Target).path '')){
        #are path and target already equal?
        throw "Already at destination, nothing done."
    }
    attrib +r $Target
    Copy-Item (join-path $Path desktop.ini) $Target;
    if((Set-KnownFolderPath $KnownFolder $Target) -eq 0){
        $code = Get-KnownFolderPath $KnownFolder ([ref]$Path)
        if((join-path (resolve-path $Path).path '') -eq (join-path (resolve-path $Target).path '')){
            exit 0
        }
        else{
            throw "Paths mismatch:
            "+(join-path (resolve-path $Path).path '')+"
            "+(join-path (resolve-path $Target).path '')
        }
    }
    else{
        Set-KnownFolderPath $KnownFolder $Path
        throw "Failed to change directory"
    }

}
