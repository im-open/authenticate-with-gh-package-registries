Param(
    [parameter(Mandatory = $true)]
    [string]$rawOrgs,
    [parameter(Mandatory = $true)]
    [string]$runnerOs,
    [parameter(Mandatory = $false)]
    [bool]$useSecondGithubToken = $false
)

Write-Host "Adding registries to a $runnerOs machine"

# This sets the _authToken for github packages to a literal env var reference,
# so npm resolves it at runtime from the current job environment.
if ($useSecondGithubToken) {
    Write-Host "Skipping setting the global _authToken since we're using the secondary GitHub token environment variable: READ_PACKAGE_TOKEN_SECOND"
} else {
    npm set //npm.pkg.github.com/:_authToken '${READ_PACKAGE_TOKEN}'
    write-Host "Setting the default global _authToken to reference the READ_PACKAGE_TOKEN environment variable"
}

$orgList = $rawOrgs.Split(',');
$npmUserConfigPath = npm config get userconfig

foreach ($org in $orgList)
{
    $org = $org.Trim();
    $registry = ":registry"
    Write-Host "Adding the $org$registry registry entry..."
    if(!$useSecondGithubToken) {
        npm config delete "@$org$registry" 
    }else{
        Write-Host "Skipping deletion of @$org$registry since we're using the secondary GitHub token environment variable: READ_PACKAGE_TOKEN_SECOND and we want to preserve any existing registry entry that references that variable"
    }
    
    npm config set "@$org$registry" https://npm.pkg.github.com

    Write-Host "Adding the $org:_authToken entry..."
    
    (Get-Content $npmUserConfigPath) | Where-Object { $_ -notmatch "@$($org):_authToken" } | Set-Content $npmUserConfigPath
    if ($useSecondGithubToken) {
        Add-Content -Path $npmUserConfigPath -Value "@$($org):_authToken=`${READ_PACKAGE_TOKEN_SECOND}"
        Write-Host "Adding org specific _authToken entry for $org that references the READ_PACKAGE_TOKEN_SECOND environment variable"
    } else {
        Add-Content -Path $npmUserConfigPath -Value "@$($org):_authToken=`${READ_PACKAGE_TOKEN}"
        Write-Host "Adding org specific _authToken entry for $org that references the READ_PACKAGE_TOKEN environment variable"
    }
}

Write-Host "Ensuring that the global _authToken is present at the top of the file."
$globalConfigLine = "//npm.pkg.github.com/:_authToken='`${READ_PACKAGE_TOKEN}'"
if ($useSecondGithubToken) {
    $globalConfigLineExists = Select-String -Path $npmUserConfigPath -Pattern $globalConfigLine
    if($globalConfigLineExists) {
        Write-Host "The global _authToken entry referencing the default GitHub token environment variable already exists in the npmrc file."
    } else {
        $originalContent = Get-Content $npmUserConfigPath
        Write-Host "The global _authToken entry referencing the secondary GitHub token environment variable does not exist in the npmrc file. Adding it now."
        Set-Content -Path $npmUserConfigPath -Value $globalConfigLine
        $originalContent | Add-Content -Path $npmUserConfigPath
    }
} else {
    Write-Host "Skipping check for global _authToken."
}