Function Get-TrimmedList
{
	Param(
		[parameter(Mandatory = $false)]
		[AllowNull()]
		[string]$rawValue
	)

	if ([string]::IsNullOrWhiteSpace($rawValue))
	{
		return @()
	}

	return @($rawValue.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

Function Get-NuGetConfigPath
{
	$configPathsRaw = dotnet nuget config paths
	$configPath = $configPathsRaw |
		ForEach-Object { $_.Trim() } |
		Where-Object { $_ -match '^(?:[A-Za-z]:\\|/).+\.(?:config|Config)$' } |
		Select-Object -First 1

	if ([string]::IsNullOrWhiteSpace($configPath))
	{
		throw 'Could not find a NuGet config path from "dotnet nuget config paths" output.'
	}

	return $configPath
}

Function Save-XmlFile
{
	Param(
		[parameter(Mandatory = $true)]
		[xml]$xmlDocument,
		[parameter(Mandatory = $true)]
		[string]$path
	)

	$settings = New-Object System.Xml.XmlWriterSettings
	$settings.Indent = $true
	$settings.IndentChars = '  '
	$settings.OmitXmlDeclaration = $false

	$writer = [System.Xml.XmlWriter]::Create($path, $settings)
	try
	{
		$xmlDocument.Save($writer)
	}
	finally
	{
		$writer.Dispose()
	}
}

Function Get-PackageSourceMappingPatterns
{
	Param(
		[parameter(Mandatory = $false)]
		[AllowNull()]
		[string]$rawPatternInput
	)

	$entries = @(Get-TrimmedList -rawValue $rawPatternInput)
	$globalPatterns = @()
	$orgPatterns = @{}

	foreach ($entry in $entries)
	{
		if ($entry -match '^([^:]+):(.+)$')
		{
			$orgName = $Matches[1].Trim()
			$pattern = $Matches[2].Trim()

			if ([string]::IsNullOrWhiteSpace($orgName) -or [string]::IsNullOrWhiteSpace($pattern))
			{
				continue
			}

			if (-not $orgPatterns.ContainsKey($orgName))
			{
				$orgPatterns[$orgName] = @()
			}

			$orgPatterns[$orgName] += $pattern
		}
		else
		{
			$globalPatterns += $entry
		}
	}

	$globalPatterns = @($globalPatterns | Select-Object -Unique)
	foreach ($orgName in @($orgPatterns.Keys))
	{
		$orgPatterns[$orgName] = @($orgPatterns[$orgName] | Select-Object -Unique)
	}

	return @{
		GlobalPatterns = $globalPatterns
		OrgPatterns = $orgPatterns
	}
}

Function Add-NuGetPackageSourceMapping
{
	Param(
		[parameter(Mandatory = $true)]
		[string]$rawOrgs,
		[parameter(Mandatory = $false)]
		[AllowNull()]
		[string]$rawOrgsLegacy,
		[parameter(Mandatory = $false)]
		[AllowNull()]
		[string]$nugetPackageSourceMappingPattern = 'Mktp.*',
		[parameter(Mandatory = $false)]
		[AllowNull()]
		[string]$nugetConfigPath
	)

	$orgList = @(Get-TrimmedList -rawValue $rawOrgs)
	$orgListLegacy = @(Get-TrimmedList -rawValue $rawOrgsLegacy)
	$parsedPatterns = Get-PackageSourceMappingPatterns -rawPatternInput $nugetPackageSourceMappingPattern
	$globalPatterns = @($parsedPatterns.GlobalPatterns)
	$orgPatterns = $parsedPatterns.OrgPatterns

	if ($globalPatterns.Count -eq 0 -and $orgPatterns.Count -eq 0)
	{
		return;
	}

	if ([string]::IsNullOrWhiteSpace($nugetConfigPath))
	{
		$nugetConfigPath = Get-NuGetConfigPath
	}

	if (-not (Test-Path -Path $nugetConfigPath))
	{
		throw "NuGet config file does not exist: $nugetConfigPath"
	}

	[xml]$xmlDocument = Get-Content -Path $nugetConfigPath -Raw
	if ($null -eq $xmlDocument.configuration)
	{
		throw "The NuGet config file does not contain a <configuration> root node: $nugetConfigPath"
	}

	$configurationNode = $xmlDocument.configuration
	$existingPackageSourceMappingNode = $configurationNode.SelectSingleNode('packageSourceMapping')
	if ($null -ne $existingPackageSourceMappingNode)
	{
		[void]$configurationNode.RemoveChild($existingPackageSourceMappingNode)
	}

	$packageSourceMappingNode = $xmlDocument.CreateElement('packageSourceMapping')

	$allOrgs = @()
	$allOrgs += $orgList
	$allOrgs += $orgListLegacy
	$allOrgs += @($orgPatterns.Keys)
	$allOrgs = @($allOrgs | Select-Object -Unique)
	foreach ($org in $allOrgs)
	{
		$patternsForOrg = @()
		$patternsForOrg += $globalPatterns
		if ($orgPatterns.ContainsKey($org))
		{
			$patternsForOrg += @($orgPatterns[$org])
		}
		$patternsForOrg = @($patternsForOrg | Select-Object -Unique)

		if ($patternsForOrg.Count -eq 0)
		{
			continue
		}

		$packageSourceNode = $xmlDocument.CreateElement('packageSource')
		[void]$packageSourceNode.SetAttribute('key', $org)

		foreach ($pattern in $patternsForOrg)
		{
			$packagePatternNode = $xmlDocument.CreateElement('package')
			[void]$packagePatternNode.SetAttribute('pattern', $pattern)
			[void]$packageSourceNode.AppendChild($packagePatternNode)
		}

		[void]$packageSourceMappingNode.AppendChild($packageSourceNode)
	}

	$nugetSourceNode = $xmlDocument.CreateElement('packageSource')
	[void]$nugetSourceNode.SetAttribute('key', 'nuget.org')

	$nugetWildcardPatternNode = $xmlDocument.CreateElement('package')
	[void]$nugetWildcardPatternNode.SetAttribute('pattern', '*')
	[void]$nugetSourceNode.AppendChild($nugetWildcardPatternNode)

	[void]$packageSourceMappingNode.AppendChild($nugetSourceNode)
	[void]$configurationNode.AppendChild($packageSourceMappingNode)

	Save-XmlFile -xmlDocument $xmlDocument -path $nugetConfigPath

	Write-Host "Added packageSourceMapping to: $nugetConfigPath"
	Write-Host "Mapped org sources: $($allOrgs -join ', ')"
	Write-Host "Global mapping patterns for org sources: $($globalPatterns -join ', ')"
	Write-Host "Org specific mapping patterns: $($orgPatterns.Keys -join ', ')"
}
