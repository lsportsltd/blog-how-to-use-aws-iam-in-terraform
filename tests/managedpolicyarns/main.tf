# Results in an endless loop due managing "managed_policy_arns"
# In two places - "iam_role" and "iam_role_policy_attachment"

data "aws_iam_policy_document" "test_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.test_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}


resource "aws_iam_policy" "attached_policy" {
  name        = "test-attached-policy"
  description = "A test policy"
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

resource "aws_iam_role_policy_attachment" "test_attachment" {
  role       = aws_iam_role.test_role.name
  policy_arn = aws_iam_policy.attached_policy.arn
}

resource "aws_iam_policy_attachment" "test_attachment" {
  name       = "test-attachment"
  roles      = [aws_iam_role.test_role.name]
  policy_arn = aws_iam_policy.attached_policy.arn
}
