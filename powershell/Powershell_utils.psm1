function Normalize-Path{
param([string]$path)
if($path.StartsWith("~")){
    r = [regex]"~\\|~/"
    $path = $r.Replace($path,$env:USERPROFILE,1)
}
if($false -eq [System.IO.Path]::IsPathRooted($path)){
    $path = "$PWD/$path"
}
return [IO.Path]::GetFullPath($path)
}
function Validate-IPv4{
param([string]$ip)
# https://stackoverflow.com/a/36760050/12603110
$r = [regex]"^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$"
return $r.IsMatch($ip)
}
function Is-NullOrEmpty{
param([string]$str)
    return [string]::IsNullOrEmpty($str)
}