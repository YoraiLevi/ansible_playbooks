function Get-Available {
    $template = @'
|   CURRENT    |     LTS      |  OLD STABLE  | OLD UNSTABLE |
|--------------|--------------|--------------|--------------|
|    {current*:17.3.1}    |   {lts:16.13.2}    |   0.12.18    |   0.11.16    |
|    {current*:17.3.0}    |   {lts:16.13.1}    |   0.12.17    |   0.11.15    |
'@
    $available = ((nvm list available).trim()) | ConvertFrom-String -TemplateContent $template
    return $available
}
function Get-Installed {
    $template = @'
{version*:17.3.1}
* {version*:16.14.2} (Currently using 64-bit executable)
* {version*:16.14.2} (Currently using 32-bit executable)
{version*:16.13.2}
'@
    $installed = ((nvm list).trim()) | ConvertFrom-String -TemplateContent $template
    return $installed.version
}
function Get-InstalledLTS {
    $available = Get-Available
    $installed = Get-Installed
    return ((Compare-Object $available.lts $installed -PassThru -IncludeEqual -ExcludeDifferent) | measure -Maximum).Maximum
}
function Get-InstalledLatest {
    $installed = Get-Installed
    return ($installed | measure -Maximum).Maximum
}
# function Get-InstalledLatest{
# $template = @'
# Version {version*:17.3.1} is already installed.
# Downloading node.js version {version*:16.13.2} (64-bit)...
# Extracting...
# Complete
# '@
# # (((nvm install latest).trim()) | ConvertFrom-String -TemplateContent $template).version
# return (((nvm install $version).trim()) | ConvertFrom-String -TemplateContent $template).version
# }

# function Install-NodeVersion{
#     param($version="lts")

# }
