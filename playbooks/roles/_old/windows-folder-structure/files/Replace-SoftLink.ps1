param([Parameter(Mandatory = $true)]$Target, [Parameter(Mandatory = $true)]$Path, [System.Boolean]$Move)
#make sure target exists
Get-Item $Target -Force -ErrorAction stop *> $null
$item = Get-Item $Path -Force
if ($null -eq $item) {
    #Path doesn't exist, just create symlink
    New-Item -Type SymbolicLink -Target $Target -Path $Path 
    echo "Changed: Created Symbolic Link successfully"
    exit 0
}
else {
    #Path exists
    $item_target = ($item | Where-Object { $_.Attributes -match "ReparsePoint" } | select target).target
    #Is symlink
    if ((-not [string]::IsNullOrWhiteSpace($item_target))) {
        if ((join-path (resolve-path $item_target).path '') -eq (join-path (resolve-path $Target).path '')) {
            # check if symlink target is pointhing to target. if yes OK
            echo "Ok: nothing changed"
            exit 0
        }
        else {
            $item.delete()
            New-Item -Type SymbolicLink -Target $Target -Path $Path 
            echo "Changed: Created Symbolic Link successfully"
            exit 0
        }
    }
    else {
        #Is not symlink
        Rename-Item -Path $Path -NewName ($item.Name + ".old" + "_" + $(get-date -f MM-dd-yyyy_HH_mm_ss))
        New-Item -Type SymbolicLink -Target $Target -Path $Path
        if ($Move) {
            echo "moving files"
        }
        echo "Changed: Created Symbolic Link successfully"
        exit 0
    }
}
