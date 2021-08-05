# authenticate-with-gh-packages-for-nuget

This action creates package source entries in the closest nuget.config file for each organization provided.  After executing this action, subsequent steps will be able to pull nuget packages from each provided organization's GitHub Packages Registry.  

The package source entry includes package source credentials which use the GitHub personal access token provided as an argument.  The PAT needs to have the `read:packages` scope and should be authorized for each of the organizations provided, otherwise it will not be able to retrieve the packages.

This action has been customized for `im-open`'s needs, so outside users will need to override the default organizations.

For more information around authenticating with GitHub Packages see [Authenticating to GitHub Packages] and [dotnet nuget add source].

## Inputs
| Parameter      | Is Required | Default                                                                                    | Description                                                                                                                                                                            |
| -------------- | ----------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github-token` | true        | N/A                                                                                        | A personal access token with access to each of the organizations that sources will be added for.<br/>Must have `read:packages` scope and be authorized to work with the provided orgs. |
| `orgs`         | true        | im-client,im-customer-engagement,im-enrollment,im-funding,im-platform,im-practices,bc-swat | A comma-separated list of organizations that package sources should be added for.                                                                                                      |

## Outputs
No Outputs

## Example

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
        uses: im-open/authenticate-with-gh-packages-for-nuget@v1.0.0
        with:
          github-token: ${{ secrets.INSTALL_PKG_TOKEN }} # Token has read:packages scope and is authorized for each of the orgs
          orgs: 'myorg2,myorg2,octocoder'

      - run: dotnet restore
```


## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).

[Authenticating to GitHub Packages]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages
[dotnet nuget add source]: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source