# authenticate-with-gh-package-registries

This action will authenticate with both nuget and npm GitHub Packages Registries for the organizations provided. This action has been customized for `im-open's` needs, so outside users will need to override the default organizations it authenticates with.

For more information around authenticating with GitHub Packages see

- [Authenticating to GitHub Packages - nuget]
- [dotnet nuget add source]
- [Authenticating to GitHub Packages - npm]
- [npm private packages in CI/CD workflow]

## Index <!-- omit in toc -->

- [authenticate-with-gh-package-registries](#authenticate-with-gh-package-registries)
  - [nuget](#nuget)
  - [npm](#npm)
  - [PAT Requirements](#pat-requirements)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Usage Examples](#usage-examples)
  - [Contributing](#contributing)
    - [Incrementing the Version](#incrementing-the-version)
    - [Source Code Changes](#source-code-changes)
    - [Updating the README.md](#updating-the-readmemd)
    - [Tests](#tests)
  - [Code of Conduct](#code-of-conduct)
  - [License](#license)

## nuget

For nuget, this action creates package source entries in the closest `nuget.config` file for each organization provided. For each package source a corresponding credentials node is added. By default, the password in each credentials node is set to the `READ_PACKAGE_TOKEN` environment variable. If `use-second-github-token` is `true`, the action uses `READ_PACKAGE_TOKEN_SECOND` instead. After executing this action, subsequent steps will be able to pull nuget packages from each provided organization's nuget package registry.

This action modifies the closest `nuget.config`. This is what the `nuget.config` file will look like with some of the default orgs:

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

For npm, this action adds one or more scoped package registries for each organization provided and credentials for the GitHub Npm Packages Registry. After executing this action, subsequent steps will be able to install npm packages from each provided organization's npm package registry.

The action modifies the `.npmrc` file by adding an authToken for npm.pkg.github.com and adds a registry for each org provided. This is what the `.npmrc` file looks like with the default organizations:

```sh
//npm.pkg.github.com/:_authToken=${READ_PACKAGE_TOKEN}
@im-client:registry=https://npm.pkg.github.com
@im-client:_authToken=${READ_PACKAGE_TOKEN}
@im-customer-engagement:registry=https://npm.pkg.github.com
@im-customer-engagement:_authToken=${READ_PACKAGE_TOKEN}
@im-enrollment:registry=https://npm.pkg.github.com
@im-funding:registry=https://npm.pkg.github.com
@im-platform:registry=https://npm.pkg.github.com
@im-practices:registry=https://npm.pkg.github.com
@bc-swat:registry=https://npm.pkg.github.com
```

The registry entries tell npm which feed to look at for each scoped package type. The `_authToken` entries use `READ_PACKAGE_TOKEN` by default. If `use-second-github-token` is `true`, org-specific `_authToken` entries use `READ_PACKAGE_TOKEN_SECOND` instead. These environment variables are set for subsequent steps in the same job, but not for other jobs.

## PAT Requirements

The PAT needs to have the `read:packages` scope, it should be authorized for each of the organizations provided and the account the PAT belongs to must have `read` access to the repository that contains the package, otherwise attempts to install packages from that feed will fail. It's strongly recommended to use a separate PAT for installing packages that only has the `read:packages` scope.

## Inputs

| Parameter        | Is Required | Default                                                                                    | Description                                                                                                                                                                                    |
|------------------|-------------|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `read-pkg-token` | true        | N/A                                                                                        | A personal access token with the `read:packages` scope that has been authorized for use with each provided org and is from an account that has read access to the repo containing the package. |
| `orgs`           | true        | im-client,im-customer-engagement,im-enrollment,im-funding,im-platform,im-practices,bc-swat | A comma-separated list of organizations that registry entries should be added for.                                                                                                             |
| `setup-nuget`    | false       | true                                                                                       | Flag indicating whether to set each org as a nuget source or not.  Accepts: `true\|false`.                                                                                                     |
| `setup-npm`      | false       | true                                                                                       | Flag indicating whether to set each org as an  npm registry or not.  Accepts: `true\|false`.                                                                                                   |
| `use-second-github-token` | false | false                                                                                      | Use `READ_PACKAGE_TOKEN_SECOND` instead of `READ_PACKAGE_TOKEN` for package auth entries. Enable this when you need to authenticate package pulls with a token from a second GitHub account.         |
| `show-config-file-contents` | false | false                                                                                     | Flag indicating whether to output `~/.npmrc` and `~/.nuget/NuGet/NuGet.Config` contents to workflow logs for debugging. Accepts: `true\|false`.                                                  |

If you set `use-second-github-token: true`, pass the second account's PAT through `read-pkg-token` (for example, `secrets.READ_PKG_TOKEN_SECOND`).

If you set `show-config-file-contents: true`, the action prints config file contents after setup steps. Use this only for troubleshooting and avoid enabling it in normal runs.

## Outputs

No Outputs

## Usage Examples 1

```yml
name: 'Build App with GitHub Packages Dependencies'

on:
  push:

jobs:
  windows-restore-and-run:
    runs-on: windows-2019 # Works on Ubuntu-20.04 as well

    steps:
      - uses: actions/checkout@v3

      - name: Authenticate with GitHub Packages on Windows
        # You may also reference the major or major.minor version
        uses: im-open/authenticate-with-gh-package-registries@v1.2.1
        with:
          read-pkg-token: ${{ secrets.READ_PKG_TOKEN }} # Token has read:packages scope and is authorized for each of the orgs
          orgs: 'myorg2,myorg2,octocoder'

      - run: npm install # .npmrc contains contains the creds for connecting and installing npm packages from GPR
      - run: npm test

      - run: dotnet restore # nuget.config contains the creds for connecting and restoring nuget packages from GRP
```

## Usage Example with use-second-github-token input

```yml
name: 'Build App with GitHub Packages Dependencies in multiple github enterprises / github accounts'

on:
  push:

jobs:
  windows-restore-and-run:
    runs-on: windows-2019 # Works on Ubuntu-20.04 as well

    steps:
      - uses: actions/checkout@v3

      - name: Authenticate with GitHub Packages on Windows
        # You may also reference the major or major.minor version
        uses: im-open/authenticate-with-gh-package-registries@v1.2.1
        with:
          read-pkg-token: ${{ secrets.READ_PKG_TOKEN }} # Token has read:packages scope and is authorized for each of the orgs
          orgs: 'my-first-account-org'

      - name: Authenticate with GitHub Packages on Windows
        # You may also reference the major or major.minor version
        uses: im-open/authenticate-with-gh-package-registries@v1.2.1
        with:
          read-pkg-token: ${{ secrets.READ_PKG_TOKEN_SECOND }} # Token has read:packages scope and is authorized for each of the orgs
          orgs: 'my-second-account-org'
          use-second-github-token: true
          show-config-file-contents: true # to see if the file is correct.  Not needed once pipeline is working properly.  Use for troubleshooting.

      - run: npm install # .npmrc contains contains the creds for connecting and installing npm packages from GPR
      - run: npm test

      - run: dotnet restore # nuget.config contains the creds for connecting and restoring nuget packages from GRP
```

## Contributing

When creating PRs, please review the following guidelines:

- [ ] The action code does not contain sensitive information.
- [ ] At least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version] for major and minor increments.
- [ ] The README.md has been updated with the latest version of the action.  See [Updating the README.md] for details.
- [ ] Any tests in the [build-and-review-pr] workflow are passing

### Incrementing the Version

This repo uses [git-version-lite] in its workflows to examine commit messages to determine whether to perform a major, minor or patch increment on merge if [source code] changes have been made.  The following table provides the fragment that should be included in a commit message to active different increment strategies.

| Increment Type | Commit Message Fragment                     |
|----------------|---------------------------------------------|
| major          | +semver:breaking                            |
| major          | +semver:major                               |
| minor          | +semver:feature                             |
| minor          | +semver:minor                               |
| patch          | *default increment type, no comment needed* |

### Source Code Changes

The files and directories that are considered source code are listed in the `files-with-code` and `dirs-with-code` arguments in both the [build-and-review-pr] and [increment-version-on-merge] workflows.  

If a PR contains source code changes, the README.md should be updated with the latest action version.  The [build-and-review-pr] workflow will ensure these steps are performed when they are required.  The workflow will provide instructions for completing these steps if the PR Author does not initially complete them.

If a PR consists solely of non-source code changes like changes to the `README.md` or workflows under `./.github/workflows`, version updates do not need to be performed.

### Updating the README.md

If changes are made to the action's [source code], the [usage examples] section of this file should be updated with the next version of the action.  Each instance of this action should be updated.  This helps users know what the latest tag is without having to navigate to the Tags page of the repository.  See [Incrementing the Version] for details on how to determine what the next version will be or consult the first workflow run for the PR which will also calculate the next version.

### Tests

The [build-and-review-pr] workflow includes tests which are linked to a status check. That status check needs to succeed before a PR is merged to the default branch.  When a PR comes from a branch, the `GITHUB_TOKEN` has the necessary permissions required to run the tests successfully.  

When a PR comes from a fork, the tests won't have the necessary permissions to run since the `GITHUB_TOKEN` only has `read` access for all scopes. When a PR comes from a fork, the changes should be reviewed, then merged into an intermediate branch by repository owners so tests can be run against the PR changes.  Once the tests have passed, changes can be merged into the default branch.

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/main/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2023, Extend Health, LLC. Code released under the [MIT license](LICENSE).

<!-- Links -->
[Incrementing the Version]: #incrementing-the-version
[Updating the README.md]: #updating-the-readmemd
[source code]: #source-code-changes
[usage examples]: #usage-examples
[build-and-review-pr]: ./.github/workflows/build-and-review-pr.yml
[increment-version-on-merge]: ./.github/workflows/increment-version-on-merge.yml
[git-version-lite]: https://github.com/im-open/git-version-lite
[authenticating to github packages - nuget]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages
[dotnet nuget add source]: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source
[authenticating to github packages - npm]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry#authenticating-to-github-packages
[npm private packages in ci/cd workflow]: https://docs.npmjs.com/using-private-packages-in-a-ci-cd-workflow
