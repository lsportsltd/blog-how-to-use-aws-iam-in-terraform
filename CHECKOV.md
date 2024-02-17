# how-to-use-aws-iam-in-terraform - checkov

Following this blog post, [How To Use AWS IAM In Terraform](https://engineering.lsports.eu/how-to-use-aws-iam-in-terraform-95be5244f562), I've decided to ease the adoption of the described practices by adding [checkov](https://www.checkov.io/) tests to the codebase.

## Requirements

- Docker
- make
- Python 3.7+

## Setup

- Install requirements
   ```bash
   make install
   ```

## Getting Started

1. Start localstack locally
   ```bash
   make localstack-start
   ```
1. **Create a new terminal window**
2. Run `tflocal` on a test - That's a full init, plan, apply cycle
   ```bash
   make tflocal-all-inlinepolicy
   ```
3. Run tests with `checkov` - Should **Pass** ✅ for the first time of creating resources
   ```bash
   make checkov-externalchecks-inlinepolicy
   ```
4. Run `tflocal` on a test again - This time, it will want to "change" but without any effect
   ```bash
   make tflocal-all-inlinepolicy 
   ```
5.  Run tests with `checkov` - Should **Fail** ❌ due to "managing value in two places."
   ```bash
   make checkov-externalchecks-inlinepolicy
   ```


The same steps can be taken for [managedpolicyarns](tests/managedpolicyarns) and [modulemanagedpolicyarns](tests/modulemanagedpolicyarns).

## Known Caveats

It would be better to cache conflicts **before applying** them to the infrastructure. Still, due to the complexity of AWS and Terraform resources and dependencies, I could only catch this conflict after the fact. Better than nothing.
