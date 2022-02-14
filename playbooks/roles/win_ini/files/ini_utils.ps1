function Out-IniFile($InputObject, $FilePath) {
    $outFile = New-Item -ItemType file -Path $Filepath -Force
    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq “Hashtable”)) {
            #No Sections
            Add-Content -Path $outFile -Value “$i=$($InputObject[$i])”
        }
        else {
            #Sections
            Add-Content -Path $outFile -Value “[$i]”
            Foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                if ($j -match “^Comment[\d]+”) {
                    Add-Content -Path $outFile -Value “$($InputObject[$i][$j])”
                }
                else {
                    Add-Content -Path $outFile -Value “$j=$($InputObject[$i][$j])”
                }

            }
            Add-Content -Path $outFile -Value “”
        }
    }
}

function Get-IniContent ($filePath) {
    $ini = @{}
    switch -regex -file $FilePath {
        “^\[(.+)\]” {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” {
            # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        }
        “(.+?)\s*=(.*)” {
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
    $ini = $ini | Join-HashTableTree $hashtable
    Out-IniFile $ini $filePath
}