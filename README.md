# Cumulus Template Deployment Project

[![CircleCI](https://circleci.com/gh/nasa/cumulus-template-deploy.svg?style=svg)](https://circleci.com/gh/nasa/cumulus-template-deploy)

Documentation for how to use the Cumulus template project can be read online:

[https://nasa.github.io/cumulus/docs/deployment/deployment-readme#prepare-daac-deployment-repository](https://nasa.github.io/cumulus/docs/deployment/deployment-readme#prepare-daac-deployment-repository)

## Managing Cumulus package dependencies

This project depends on various Cumulus NPM packages specified in [`package.json`](./package.json). These dependencies may be behind the latest released versions for Cumulus core.

To check if your dependencies are out of date, compare the versions for `@cumulus/<package-name>` packages in the local [`package.json`](./package.json) with the versions in the `package.json` files inside [the Cumulus core repository package folders](https://github.com/nasa/cumulus/tree/master/packages).

If any of your dependencies are out of date, update them:

```bash
  $ npm install @cumulus/<package-name>@^1.11.3 --save
```

**Note**: Using `^1.11.3` instead of `1.11.3` means that when you run `npm install` for this project in the future, if there are any newly released minor versions of that package (e.g. `1.11.4` or `1.12.0`), they will be installed automatically. However, if you want to stay pinned to version `1.11.3` for the future, you can install using that exact version.