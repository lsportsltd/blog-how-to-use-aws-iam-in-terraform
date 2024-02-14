resource "aws_s3_bucket" "managed_bucket" {
  bucket = "another-tf-test-bucket"
}



module "iam_assumable_role_with_oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.34.0"

  create_role = true

  role_name = "role-with-oidc"

  tags = {
    Role = "role-with-oidc"
  }

  provider_url = "oidc.eks.eu-west-1.amazonaws.com/id/BA9E170D464AF7B92084EF72A69B9DC8"

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
  number_of_role_policy_arns = 1
}

# IAM Policy that will be attached to the role with "aws_iam_role_policy"
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
