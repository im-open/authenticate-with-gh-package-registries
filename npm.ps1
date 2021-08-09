Param(
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $true)]
    [string]$runnerOs
)

Write-Host "Adding registries to a $runnerOs machine"
$orgList = $rawOrgs.Split(',');

foreach ($org in $orgList)
{
    $org = $org.Trim();
    $registry = ":registry"
    Write-Host "Adding the $org$registry registry entry..."
    npm config delete "@$org$registry" 
    npm config set "@$org$registry" https://npm.pkg.github.com
}

# This sets the _authToken for github packages to the literal value: ${READ_PACKAGE_TOKEN}
# which will allow pulling that token from an environment variable.
npm set //npm.pkg.github.com/:_authToken '${READ_PACKAGE_TOKEN}'