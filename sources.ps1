Param(
    [parameter(Mandatory = $true)]
    [string]$token,
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $true)]
    [string]$runnerOs
)

Write-Host "Adding sources to a $runnerOs machine"
$orgList = $rawOrgs.Split(',');
$sourceRaw = dotnet nuget list source
$sources = ($sourceRaw | select-string -pattern '\d\.\s*(.*)\s\[' -AllMatches).Matches | ForEach-Object { $_.Groups[1].Value }

Write-Host "The following sources exist:"
foreach ($s in $sources)
{
    Write-Host $s
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
    
    $additonalArgs = ''
    if ($runnerOs.ToLower() -eq 'linux' )
    {
        $additonalArgs = '--store-password-in-clear-text'
    }
    Write-Host "Adding the $org source..."
    dotnet nuget add source https://nuget.pkg.github.com/$org/index.json --name $org --username USERNAME --password $token $additonalArgs
}