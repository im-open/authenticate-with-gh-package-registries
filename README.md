# authenticate-with-gh-package-registries

This action will authenticate with both nuget and npm GitHub Packages Registries for the organizations provided. This action has been customized for `im-open's` needs, so outside users will need to override the default organizations it authenticates with.

For more information around authenticating with GitHub Packages see 
- [Authenticating to GitHub Packages - nuget] 
- [dotnet nuget add source]
- [Authenticating to GitHub Packages - npm] 
- [npm private packages in CI/CD workflow]
  

## Index

- [nuget](#nuget)
- [npm](#npm)
- [PAT Requirements](#pat-requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Usage Example](#usage-example)
- [Contributing](#contributing)
  - [Incrementing the Version](#incrementing-the-version)
- [Code of Conduct](#code-of-conduct)
- [License](#license)

## nuget
For nuget, this action creates package source entries in the closest `nuget.config` file for each organization provided.  For each package source a corresponding credentials node is added.  The password in each credentials node is set to the `READ_PACKAGE_TOKEN` environment variable.  After executing this action, subsequent steps will be able to pull nuget packages from each provided organization's nuget package registry.  

This action modifies the closest `nuget.config`.  This is what the `nuget.config` file will look like with some of the default orgs:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="im-client" value="https://nuget.pkg.github.com/im-client/index.json" />
    <add key="im-customer-engagement" value="https://nuget.pkg.github.com/im-customer-engagement/index.json" />
    <add key="im-enrollment" value="https://nuget.pkg.github.com/im-enrollment/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <im-client>
      <add key="Username" value="USERNAME" />
      <add key="ClearTextPassword" value="%READ_PACKAGE_TOKEN%" />
    </im-client>
    <im-customer-engagement>
      <add key="Username" value="USERNAME" />
      <add key="ClearTextPassword" value="%READ_PACKAGE_TOKEN%" />
    </im-customer-engagement>
    <im-enrollment>
      <add key="Username" value="USERNAME" />
      <add key="ClearTextPassword" value="%READ_PACKAGE_TOKEN%" />
    </im-enrollment>
  </packageSourceCredentials>
</configuration>
```

## npm
For npm, this action adds one or more scoped package registries for each organization provided and credentials for the GitHub Npm Packages Registry.  After executing this action, subsequent steps will be able to install npm packages from each provided organization's npm package registry.

The action modifies the `.npmrc` file by adding an authToken for npm.pkg.github.com and adds a registry for each org provided.  This is what the `.npmrc` file looks like with the default organizations:
```sh
@im-client:registry=https://npm.pkg.github.com
@im-customer-engagement:registry=https://npm.pkg.github.com
@im-enrollment:registry=https://npm.pkg.github.com
@im-funding:registry=https://npm.pkg.github.com
@im-platform:registry=https://npm.pkg.github.com
@im-practices:registry=https://npm.pkg.github.com
@bc-swat:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${READ_PACKAGE_TOKEN}
```
The registry entries tell npm which feed to look at for each scoped package type.  The last line with the  `_authToken` uses the `READ_PACKAGE_TOKEN` environment variable which has been populated with the supplied PAT.  This environment variable will be set for all subsequent steps in the job, but it will not be set for other jobs.

## PAT Requirements
The PAT needs to have the `read:packages` scope, it should be authorized for each of the organizations provided and the account the PAT belongs to must have `read` access to the repository that contains the package, otherwise attempts to install packages from that feed will fail.  It's strongly recommended to use a separate PAT for installing packages that only has the `read:packages` scope.

## Inputs
| Parameter        | Is Required | Default                                                                                    | Description                                                                                                                                                                                    |
| ---------------- | ----------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `read-pkg-token` | true        | N/A                                                                                        | A personal access token with the `read:packages` scope that has been authorized for use with each provided org and is from an account that has read access to the repo containing the package. |
| `orgs`           | true        | im-client,im-customer-engagement,im-enrollment,im-funding,im-platform,im-practices,bc-swat | A comma-separated list of organizations that registry entries should be added for.                                                                                                             |  |

## Outputs
No Outputs

## Usage Example

```yml
name: 'Build App with GitHub Packages Dependencies'

on:
  push:
    
jobs:
  windows-restore-and-run:
    runs-on: windows-2019 # Works on Ubuntu-20.04 as well
    
    steps:
      - uses: actions/checkout@v2

      - name: Authenticate with GitHub Packages on Windows
        uses: im-open/authenticate-with-gh-package-registries@v1.0.5
        with:
          read-pkg-token: ${{ secrets.READ_PKG_TOKEN }} # Token has read:packages scope and is authorized for each of the orgs
          orgs: 'myorg2,myorg2,octocoder'

      - run: npm install  # .npmrc contains contains the creds for connecting and installing npm packages from GPR
      - run: npm test

      - run: dotnet restore # nuget.config contains the creds for connecting and restoring nuget packages from GRP
```


## Contributing

When creating new PRs please ensure:
1. For major or minor changes, at least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version](#incrementing-the-version).
2. The `README.md` example has been updated with the new version.  See [Incrementing the Version](#incrementing-the-version).
3. The action code does not contain sensitive information.

### Incrementing the Version

This action uses [git-version-lite] to examine commit messages to determine whether to perform a major, minor or patch increment on merge.  The following table provides the fragment that should be included in a commit message to active different increment strategies.
| Increment Type | Commit Message Fragment                     |
| -------------- | ------------------------------------------- |
| major          | +semver:breaking                            |
| major          | +semver:major                               |
| minor          | +semver:feature                             |
| minor          | +semver:minor                               |
| patch          | *default increment type, no comment needed* |

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).

[git-version-lite]: https://github.com/im-open/git-version-lite
[Authenticating to GitHub Packages - nuget]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages
[dotnet nuget add source]: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source
[Authenticating to GitHub Packages - npm]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry#authenticating-to-github-packages
[npm private packages in ci/cd workflow]: https://docs.npmjs.com/using-private-packages-in-a-ci-cd-workflow
