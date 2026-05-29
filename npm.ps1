Param(
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $false)]
    [string]$rawOrgsLegacy,
    [parameter(Mandatory = $true)]
    [string]$runnerOs
)

Write-Host "Adding registries to a $runnerOs machine"
$orgList = $rawOrgs.Split(',');
$orgListLegacy = $rawOrgsLegacy.Split(',');

foreach ($org in $orgList)
{
    $org = $org.Trim();
    if ([string]::IsNullOrWhiteSpace($org)) { continue }
    $registry = ":registry"
    $authToken = ":_authToken"
    Write-Host "Adding the $org$registry registry entry..."
    npm config delete "@$org$registry" 
    npm config set "@$org$registry" https://npm.pkg.github.com
    Write-Host "Adding the $org$authToken auth token entry..."
    npm config delete "@$org$authToken"
    npm config set "@$org$authToken" '${READ_PACKAGE_TOKEN}'
}

foreach ($org in $orgListLegacy)
{
    $org = $org.Trim();
    if ([string]::IsNullOrWhiteSpace($org)) { continue }
    $registry = ":registry"
    $authToken = ":_authToken"
    Write-Host "Adding the $org$registry registry entry..."
    npm config delete "@$org$registry" 
    npm config set "@$org$registry" https://npm.pkg.github.com
    Write-Host "Adding the $org$authToken auth token entry..."
    npm config delete "@$org$authToken"
    npm config set "@$org$authToken" '${READ_PACKAGE_TOKEN_LEGACY}'
}

# This sets the _authToken for github packages to the literal value: ${READ_PACKAGE_TOKEN}
# which will allow pulling that token from an environment variable.
npm set //npm.pkg.github.com/:_authToken '${READ_PACKAGE_TOKEN}'

