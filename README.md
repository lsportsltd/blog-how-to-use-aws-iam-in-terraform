# how-to-use-aws-iam-in-terraform

![blog-how-to-use-aws-iam-in-terraform-banner](https://github.com/lsportsltd/blog-how-to-use-aws-iam-in-terraform/assets/154052290/dd47932c-e149-4eee-bb99-b322cfa4c36c)

This blog post is a step-by-step guide on how to use AWS IAM in Terraform. After experiencing much pain and frustration, I finally figured out how to use AWS IAM in Terraform. This blog post will save you some time and frustration.
The magical thing about this blog post is that you can do every step in this blog post locally on your machine without even owning an AWS account. This is because we will use the [Localstack](https://www.localstack.cloud/) tool to simulate AWS locally on your machine.

## Requirements

To follow this blog post, you need to have the following tools installed on your machine:

- [Python 3.6 or later](https://www.python.org/downloads/)
- [Docker](https://docs.docker.com/engine/install/) - For running Localstack
- [Localstack](https://docs.localstack.cloud/getting-started/installation/) and development tools for interacting with Localstack
  ```bash
  python -m pip install terraform-local awscli-local localstack
  ```

## Setup

To get started, complete the following steps; this is a one-time setup:

```bash
git clone https://github.com/lsportsltd/blog-how-to-use-aws-iam-in-terraform.git
cd blog-how-to-use-aws-iam-in-terraform
```

## Getting Started

> **IMPORTANT**: From now on, the working directory should be the `blog-how-to-use-aws-iam-in-terraform` directory.

1. Start Localstack - This will start a new Docker container, serving all AWS APIs locally on your machine on localhost:4566

   ```bash
   localstack start
   ```

1. **Create a new terminal**
1. Change to an example directory - For example [examples/1-managed-arns-changes](./examples/1-managed-arns-changes)

   ```bash
   cd examples/1-managed-arns-changes
   ```

1. **IMPORTANT**: We'll be using `tflocal`, instead of `terraform`, communicating with Localstack.
1. Initialize Terraform - This will download the required providers and modules.
   ```bash
   tflocal init
   ```
1. Plan the changes - This will show you what Terraform will do when you apply the changes.
   ```bash
   tflocal plan -out plan.out
   ```
1. Apply the changes - This will apply the changes to the Localstack container.
   ```bash
   tflocal apply plan.out
   ```
1. Verify the changes - This will show the current state after changes
   ```bash
   tflocal show
   ```
1. Plan and Apply the changes to check for weird behaviors
   ```bash
   tflocal plan -out plan.out && tflocal apply plan.out
   ```

That was it! You can now test all the examples in the [examples](./examples/) directory. Each example is a separate Terraform configuration demonstrating a different aspect of using AWS IAM in Terraform.

Before you move on to the following example, make sure to destroy the resources created by the current example:

```bash
tflocal destroy -auto-approve
```

## 1 - Managed ARNs Changes

This example demonstrates the issue when setting the attribute `managed_policy_arns` in the `aws_iam_role`, and then creating a `aws_iam_role_policy_attachment`. This is a known conflict and it is also mentioned in the docs:

> If you use this resource's managed_policy_arns argument or inline_policy configuration blocks, this resource will take over exclusive management of the role's respective policy types (e.g., both policy types if both arguments are used). These arguments are incompatible with other ways of managing a role's policies, such as [aws_iam_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment), [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment), and [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy). If you attempt to manage a role's policies by multiple means, you will get resource cycling and/or errors. [Source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

After planning and applying this plan, you'll experience a never-ending loop of changes, each time you plan and apply. The root cause of the loop is due `aws_iam_role_policy_attachment`, which attempts to change the existing attribute `managed_policy_arns`.

Here's the output of the plan, for each "plan and apply", the result, sadly, will be the same:

```ruby
  # aws_iam_role.test_role will be updated in-place
  ~ resource "aws_iam_role" "test_role" {
        id                    = "test_role"
      ~ managed_policy_arns   = [
          - "arn:aws:iam::000000000000:policy/attached-policy",
            # (1 unchanged element hidden)
        ]
        name                  = "test_role"
        tags                  = {}
        # (8 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

This is expected, and it is mentioned in the [docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role#managed_policy_arns).

## 2 - EKS IRSA Module


The solution is rather simple, if all **resources** were managed in the same repository, one can adjust the resources and remove the `aws_iam_role_policy_attachment` resource, and instead use the `inline_policy` attribute in the `aws_iam_role` resource.

In reality, many Terraform modules will create and manage IAM Roles and Policies for you, and you might not have control over the resources. The solution is to pick the right policy attachment type and make sure that it doesn't conflict with existing policies.


| Resource Name                                                                                                                            | Affected attribute in the `aws_iam_role` |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| [aws_iam_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment)           | managed_policy_arns                      |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | managed_policy_arns                      |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                       | inline_policy                            |


Take a real-life example, assuming we use the Terraform module [terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-assumable-role-with-oidc) to create an [IAM Role for AWS Service Account (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).


See [examples/2-eks-irsa-module/main.tf](./examples/2-eks-irsa-module/main.tf), where we use the module `terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc` to create an IAM Role for AWS Service Account (IRSA), and then attach an additional IAM Policy as `inline_policy`.

After running `tflocal init && tflocal plan -out plan.out && tflocal apply plan.out`, you'll see the following output:

```ruby
# module.iam_assumable_role_with_oidc.aws_iam_role.this[0]:
resource "aws_iam_role" "this" {
    # ...    
    arn                   = "arn:aws:iam::000000000000:role/role-with-oidc"
    managed_policy_arns   = [                   # <--- This is the interesting part
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    ]
    # ...
}
```

To inspect the current state, run:

```bash
tflocal show
```

Assuming I want to add a policy to the role, I've realized the `managed_policy_arns` is already occupied by the module, and I can't use `aws_iam_role_policy_attachment` or `aws_iam_policy_attachment` to attach the policy, as it will cause a conflict. So I must use `aws_iam_role_policy` to attach the policy as `inline_policy`, this will be done in the next example.

## 3 - EKS IRSA Module - Managed ARNs Changes - Solution

Finally, the solution is to use `aws_iam_role_policy` to attach the policy as `inline_policy`. This will not cause any conflicts, as the `inline_policy` attribute is not affected by the `managed_policy_arns` attribute.

```ruby
# IAM Policy that will be attached to the role with "aws_iam_role_policy" to inline_policy
resource "aws_iam_policy" "attached_policy" {
  name        = "attached-policy"
  description = "A policy that will be attached to the role with aws_iam_role_policy to inline_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.managed_bucket.arn,
          "${aws_s3_bucket.managed_bucket.arn}/*",
        ]
      },
    ]
  })
}


# Affects inline_policy, hence doesn't cause an issue this setup
resource "aws_iam_role_policy" "attached_policy" {
  name   = "attached_policy"
  role   = module.iam_assumable_role_with_oidc.iam_role_name
  policy = aws_iam_policy.attached_policy.policy
}
```

This example results in the following output:

```ruby
No changes. Your infrastructure matches the configuration.
```

The module [iam-assumable-role-with-oidc](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-assumable-role-with-oidc) is not the perfect example, as it uses `managed_policy_arns` and `inline_policy` properly in `aws_iam_role`, and by properly, I mean not setting them at all, allowing `aws_iam_role_policy_attachment` and `aws_iam_role_policyto` be used safely, see check how [iam-assuamble-role-with-oidc](https://github.com/terraform-aws-modules/terraform-aws-iam/blob/v5.34.0/modules/iam-assumable-role-with-oidc/main.tf#L87-L102) defines an aws_iam_role.

As you already know, each module that creates an `aws_iam_role` should be inspected thoroughly. If the module is configured with no `inline_policy` and `managed_policy_arns`, it is safe to use the IAM Policy attachment without fearing conflict.


## Conclusion

In many cases, it's possible to pass variables to a module and let the module create the IAM Role and Policy for you. However, in some cases, you may need to attach additional policies to the role from somewhere else in the infrastructure, from another stack or state, and you may not have control over the module. In such cases, you must know how to attach policies to the role and ensure that you don't cause conflicts.

Ideally, all IAM Policies and Roles should be managed in the same state, and the "perfect solution" resides in [examples/4-perfect](/examples/4-perfect), where all resources are managed in the same state. But this is far from reality, and that can only be done **at your codebase level**; you'll always need to handle outputs from other stacks and attach policies to roles from different stacks.
