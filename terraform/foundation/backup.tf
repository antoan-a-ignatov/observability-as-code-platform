locals {
  backup_target_tags = {
    Backup = "daily"
  }
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "dlm_assume_role" {
  statement {
    sid     = "AllowDLMAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "oacp-dlm"
  description        = "Role for Data Lifecycle Manager to snapshot the CI data volume"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume_role.json
}

data "aws_iam_policy_document" "dlm" {
  # Describe actions do not support resource-level permissions.
  statement {
    sid = "DescribeResources"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "SnapshotCIDataVolume"
    actions   = ["ec2:CreateSnapshot"]
    resources = [aws_ebs_volume.ci_data.arn]
  }

  statement {
    sid = "CreateAndTagSnapshots"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:${data.aws_region.current.region}::snapshot/*"]
  }

  statement {
    sid       = "DeleteBackupSnapshots"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["arn:aws:ec2:${data.aws_region.current.region}::snapshot/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Backup"
      values   = ["daily"]
    }
  }
}

resource "aws_iam_role_policy" "dlm" {
  name   = "oacp-dlm-snapshots"
  role   = aws_iam_role.dlm.id
  policy = data.aws_iam_policy_document.dlm.json
}

resource "aws_dlm_lifecycle_policy" "ci_data" {
  description        = "Daily snapshots of the CI data volume"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    target_tags    = local.backup_target_tags

    schedule {
      name      = "Daily, keep 7"
      copy_tags = true

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 7
      }
    }
  }

  tags = {
    Name = "oacp-ci-data-daily"
  }
}
