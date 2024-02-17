variable "role_name" {
  description = "The name of the role"
  type        = string
  default     = "test-role"
}

resource "aws_s3_bucket" "managed_bucket" {
  bucket = "managed-tf-test-bucket"
}



module "iam_assumable_role_with_oidc" {
  source    = "./modules/"
  role_name = var.role_name
}


# Affects managed_policy_arns, hence causes issues in this setup
resource "aws_iam_policy" "attached_managed_policy_arns" {
  name        = "attached-managed-policy_arns"
  description = "Managed policy to attach to the role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "attached-managed-policy_arns"
        Action = [
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

resource "aws_iam_policy_attachment" "attached_managed_policy_arns" {
  name       = "attached-managed-policy-arn"
  roles      = [module.iam_assumable_role_with_oidc.iam_role_name]
  policy_arn = aws_iam_policy.attached_managed_policy_arns.arn
}
