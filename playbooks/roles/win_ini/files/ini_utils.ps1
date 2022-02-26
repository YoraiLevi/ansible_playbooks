function Out-IniFile($InputObject, $FilePath) {
    $outFile = New-Item -ItemType file -Path $Filepath -Force
    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq "Hashtable")) {
            #No Sections
            Add-Content -Path $outFile -Value "$i=$($InputObject[$i])"
        }
        else {
            #Sections
            Add-Content -Path $outFile -Value "[$i]"
            Foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                if ($j -match "^Comment[\d]+") {
                    Add-Content -Path $outFile -Value "$($InputObject[$i][$j])"
                }
                else {
                    Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])"
                }

            }
            Add-Content -Path $outFile -Value ""
        }
    }
}

function Get-IniContent ($filePath) {
    $ini = @{}
    switch -regex -file $FilePath {
        "^\[(.+)\]" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" {
            # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" {
            # Key
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}
function Join-HashTableTree {
    #https://stackoverflow.com/a/55090736/12603110
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]
        $SourceHashtable,

        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]
        $JoinedHashtable
    )

    $output = $SourceHashtable.Clone()

    foreach ($key in $JoinedHashtable.Keys) {
        $oldValue = $output[$key]
        $newValue = $JoinedHashtable[$key]

        $output[$key] =
        if ($oldValue -is [hashtable] -and $newValue -is [hashtable]) { $oldValue | Join-HashTableTree $newValue }
        elseif ($oldValue -is [array] -and $newValue -is [array]) { $oldValue + $newValue }
        else { $newValue }
    }

    $output;
}
function Merge-Ini($filePath,$hashtable) {
    $ErrorActionPreference = 'Stop'
    $ini = @{}
    try {
        $ini = Get-IniContent $filePath
    }
    catch {}
    $newini = $ini | Join-HashTableTree $hashtable
    $different = $null -ne (Compare-Hashtable $ini $newini)
    if($different){
        Out-IniFile $newini $filePath | Out-Null
    }
    return $different
}

Function Convert-ObjectToHashTable
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [pscustomobject] $Object
    )
    $HashTable = @{}
    $ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
    foreach ($Member in $ObjectMembers) 
    {
        $val = $Object.$($Member.Name)
        if($val -is [PSCustomObject]){
            $val = Convert-ObjectToHashTable $val
        }
        $HashTable.$($Member.Name) = $val
    }
    return $HashTable
}
function Compare-Hashtable {
    # https://gist.github.com/dbroeglin/c6ce3e4639979fa250cf
    <#
    .SYNOPSIS
    Compare two Hashtable and returns an array of differences.
    
    .DESCRIPTION
    The Compare-Hashtable function computes differences between two Hashtables. Results are returned as
    an array of objects with the properties: "key" (the name of the key that caused a difference), 
    "side" (one of "<=", "!=" or "=>"), "lvalue" an "rvalue" (resp. the left and right value 
    associated with the key).
    
    .PARAMETER left 
    The left hand side Hashtable to compare.
    
    .PARAMETER right 
    The right hand side Hashtable to compare.
    
    .EXAMPLE
    
    Returns a difference for ("3 <="), c (3 "!=" 4) and e ("=>" 5).
    
    Compare-Hashtable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5}
    
    .EXAMPLE 
    
    Returns a difference for a ("3 <="), c (3 "!=" 4), e ("=>" 5) and g (6 "<=").
    
    $left = @{ a = 1; b = 2; c = 3; f = $Null; g = 6 }
    $right = @{ b = 2; c = 4; e = 5; f = $Null; g = $Null }
    
    Compare-Hashtable $left $right
    
    #>	
    # [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [Hashtable]$Left,
    
            [Parameter(Mandatory = $true)]
            [Hashtable]$Right		
        )
        $ErrorActionPreference = "Stop"
        
        function New-Result($Key, $LValue, $Side, $RValue) {
            New-Object -Type PSObject -Property @{
                        key    = $Key
                        lvalue = $LValue
                        rvalue = $RValue
                        side   = $Side
                }
        }
        [Object[]]$Results = $Left.Keys | % {
            if ($Left.ContainsKey($_) -and !$Right.ContainsKey($_)) {
                New-Result $_ $Left[$_] "<=" $Null
            } else {
                $LValue, $RValue = $Left[$_], $Right[$_]
                if ($LValue -is [hashtable] -and $RValue -is [hashtable]){
                    $compared = Compare-Hashtable $LValue $RValue
                    if($null -ne $compared){
                        New-Result $_ $LValue "!={Hastable}" $RValue
                    }
                }
                elseif ($LValue -ne $RValue) {
                    New-Result $_ $LValue "!=" $RValue
                }
            }
        }
        $Results += $Right.Keys | % {
            if (!$Left.ContainsKey($_) -and $Right.ContainsKey($_)) {
                New-Result $_ $Null "=>" $Right[$_]
            } 
        }
        $Results 
    }
