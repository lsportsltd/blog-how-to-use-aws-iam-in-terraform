
variable "env" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}


variable "managed_policy_arns" {
  description = "A list of the ARNs of the managed policies to attach to the role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

data "aws_caller_identity" "current" {}

locals {
  dev_account     = "862877837751"
  qa_account      = "262094742590"
  prod_account    = "242710284192"
  tooling_account = "239071824248"
  role_name       = "k8s-${var.env}-${var.region}-this-role"

  custom_policy_document_statements = [
    {
      "Action" : [
        "kafka-cluster:connect",
        "kafka-cluster:DescribeCluster",
        "kafka-cluster:DescribeClusterDynamicConfiguration",
      ],
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/*"
      ]
    },
    {
      "Action" : [
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:DescribeTopicDynamicConfiguration",
        "kafka-cluster:ReadData"
      ],
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:topic/*"
      ]
    },
    {
      "Action" : [
        "kafka-cluster:DescribeGroup"
      ],
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:group/*"
      ]
    },
    {
      "Action" : [
        "kafka-cluster:DescribeTransactionalId"
      ],
      "Effect" : "Allow",
      "Resource" : [
        "arn:aws:kafka:${var.region}:${data.aws_caller_identity.current.account_id}:transactional-id/*"
      ]
    }
  ]

}

data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "custom_policy" {
  count = length(try(local.custom_policy_document_statements, [])) > 0 ? 1 : 0
  name  = "${local.role_name}-policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = try(local.custom_policy_document_statements, [])
  })
}



# Create role with managed policies and assume policy
resource "aws_iam_role" "this" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  managed_policy_arns = compact(
    flatten(
      [
        var.managed_policy_arns,
        try(aws_iam_policy.custom_policy[0].arn, [])
      ]
    )
  )
}
