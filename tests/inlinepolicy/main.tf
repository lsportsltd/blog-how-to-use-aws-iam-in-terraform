# Results in an endless loop due managing "inline_policy"
# In two places - "iam_role" and "aws_iam_role_policy"

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "test_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    sid = data.aws_caller_identity.current.account_id
  }
}

resource "aws_iam_role" "test_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.test_policy.json
  inline_policy {
    name = "test-inline-policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "s3:*",
          Effect   = "Allow",
          Resource = "*",
        },
      ],
    })

  }
}

resource "aws_iam_policy" "attached_policy" {
  name        = "test-attached-policy"
  description = "A test policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:Get*",
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy" "test_attachment" {
  name   = "test-attachment-inline-policy"
  role   = aws_iam_role.test_role.name
  policy = aws_iam_policy.attached_policy.policy
}
