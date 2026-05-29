Param(
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $false)]
    [string]$rawOrgsLegacy,
    [parameter(Mandatory = $true)]
    [string]$runnerOs,
    [parameter(Mandatory = $false)]
    [string]$nugetPackageSourceMappingPattern
)

Write-Host "Adding sources to a $runnerOs machine"
$orgList = $rawOrgs.Split(',');
$orgListLegacy = $rawOrgsLegacy.Split(',');
$sourceRaw = dotnet nuget list source


$myMatches = ($sourceRaw | select-string -pattern '\d\.\s*(.*)\s\[' -AllMatches).Matches
if ($null -ne $myMatches)
{
    $sources = $myMatches | ForEach-Object { $_.Groups[1].Value }
    Write-Host "The following sources exist:"
    foreach ($s in $sources)
    {
        Write-Host $s
    }
}
else
{
    Write-Host "There does not appear to be any existing sources"
    $sources = @()
}

foreach ($org in $orgList)
{
    $org = $org.Trim();
    if ([string]::IsNullOrWhiteSpace($org)) { continue }
    Write-Host "`nChecking $org..."
    if ($sources.Contains($org)) 
    {
        Write-Host "The $org source is already present, removing..."
        dotnet nuget remove source $org
    }
    else
    {
        Write-Host "The $org source does not exist"
    }
    
    Write-Host "Adding the $org source..."
    dotnet nuget add source https://nuget.pkg.github.com/$org/index.json --name $org --username USERNAME --password %READ_PACKAGE_TOKEN% --store-password-in-clear-text
}

foreach ($org in $orgListLegacy)
{
    $org = $org.Trim();
    if ([string]::IsNullOrWhiteSpace($org)) { continue }
    Write-Host "`nChecking $org..."
    if ($sources.Contains($org)) 
    {
        Write-Host "The $org source is already present, removing..."
        dotnet nuget remove source $org
    }
    else
    {
        Write-Host "The $org source does not exist"
    }
    
    Write-Host "Adding the $org source..."
    dotnet nuget add source https://nuget.pkg.github.com/$org/index.json --name $org --username USERNAME --password %READ_PACKAGE_TOKEN_LEGACY% --store-password-in-clear-text
}

if ($null -eq $nugetPackageSourceMappingPattern)
{
    Write-Host "No nuget package source mapping pattern provided, skipping adding package source mapping"
    exit 0 # Stop the script here since we don't want to add package source mapping if no pattern is provided
}

. "$PSScriptRoot\nuget-add-package-source-mapping.ps1"

Add-NuGetPackageSourceMapping -rawOrgs $rawOrgs -rawOrgsLegacy $rawOrgsLegacy -nugetPackageSourceMappingPattern $nugetPackageSourceMappingPattern