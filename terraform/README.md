# Introduction

This directory contains the terraform AWS config for the BOPS application.

There are three directories in here:

- `main` contains AWS configs for the app itself
- `modules` contains shared terraform modules - used by the items in `main`
- `state_config` should generally not be changed/used. It sets up the S3 bucket
  and DynamoDB locking that we use to make sure people don't overwrite each
  other's state configs.

* `bin` contains utilities for working with the infrastructure code
* `errors` contains the configuration for the static errors bucket
* `modules` contains shared modules used by the `preview` and `production` environments
* `preview` contains the configuration for the preview environment
* `production` contains the configuration for the production environment
* `state` sets up the S3 bucket and DynamoDB table that is use for state locking

# Usage

1. Install `tfenv` (with `brew install tfenv` for example). This is a Terraform
  version manager, similar to rbenv.
2. In your shell, change into the terraform/ directory and run `tfenv install`.
  The tfenv program will then read the `.terraform-version` file and install
  the appropriate version of Terraform.
3. Change into the `main` || `preview` directory. # why? which one will be for bops?
4. Check that your `~/.aws/credentials` file has a `bops-staging` profile with
  the correct values.
5. Run `terraform init` to download required libraries and state.
6. Run `terraform plan`. If you've made no changes to the files, this
  should return no changes.
7. Make your terraform changes and run `terraform plan` as required.
8. Commit your changes and make a pull request.
9. Once reviewed, merge the changes to master and run `terraform apply`.
