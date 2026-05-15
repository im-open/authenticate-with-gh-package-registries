Param(
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $true)]
    [string]$runnerOs,
    [parameter(Mandatory = $false)]
    [bool]$useSecondGithubToken = $false
)

Write-Host "Adding sources to a $runnerOs machine"
$orgList = $rawOrgs.Split(',');
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
    if ($useSecondGithubToken) {
        dotnet nuget add source https://nuget.pkg.github.com/$org/index.json --name $org --username USERNAME --password %READ_PACKAGE_TOKEN_SECOND% --store-password-in-clear-text
        Write-Host "Adding $org source with the secondary GitHub token environment variable: READ_PACKAGE_TOKEN_SECOND"
    } else {
        dotnet nuget add source https://nuget.pkg.github.com/$org/index.json --name $org --username USERNAME --password %READ_PACKAGE_TOKEN% --store-password-in-clear-text
        Write-Host "Adding $org source with the default GitHub token environment variable: READ_PACKAGE_TOKEN"
    }
}