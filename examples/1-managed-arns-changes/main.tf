
# file: examples/1-managed-arns-changes/main.tf


# AWS S3 Bucket - Will be used in IAM Policies
resource "aws_s3_bucket" "managed_bucket" {
  bucket = "another-tf-test-bucket"
}


# IAM Policy that will be used in "managed_policy_arns" attribute
data "aws_iam_policy_document" "managed_bucket" {
  statement {
    sid     = "S3"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.managed_bucket.arn,
      "${aws_s3_bucket.managed_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "managed_bucket" {
  name        = "managed-bucket"
  description = "A Policy that will be attached as a managed policy to a role"
  policy      = data.aws_iam_policy_document.managed_bucket.json
}


# IAM Role
resource "aws_iam_role" "test_role" {
  name                = "test_role"
  managed_policy_arns = [aws_iam_policy.managed_bucket.arn]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


# IAM Policy that will be attached to the role with "aws_iam_role_policy_attachment"
resource "aws_iam_policy" "attached_policy" {
  name        = "attached-policy"
  description = "A policy that will be attached to the role with aws_iam_role_policy_attachment"
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


# Affects "managed_policy_arns", hence causes an issue with this setup
resource "aws_iam_role_policy_attachment" "attached_policy" {
  role       = aws_iam_role.test_role.name
  policy_arn = aws_iam_policy.attached_policy.arn
}


# Same result as in "aws_iam_role_policy_attachment" resource, affects "managed_policy_arns"
# resource "aws_iam_policy_attachment" "attached_policy" {
#   name       = "attached_policy"
#   roles      = [aws_iam_role.test_role.name]
#   policy_arn = aws_iam_policy.attached_policy.arn
# }

# Affects inline_policy, hence doesn't cause an issue this setup
resource "aws_iam_role_policy" "attached_policy" {
  name   = "attached_policy"
  role   = aws_iam_role.test_role.name
  policy = aws_iam_policy.attached_policy.policy
}
