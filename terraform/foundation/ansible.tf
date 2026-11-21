# Transfer bucket for Ansible's Session Manager connection. Files are removed after each run; the lifecycle rule clears leftovers.
resource "aws_s3_bucket" "ansible" {
  bucket        = "observability-as-code-platform-ansible-anto"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible" {
  bucket = aws_s3_bucket.ansible.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ansible" {
  bucket = aws_s3_bucket.ansible.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "ansible" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.ansible.arn,
      "${aws_s3_bucket.ansible.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "ansible" {
  bucket = aws_s3_bucket.ansible.id
  policy = data.aws_iam_policy_document.ansible.json

  depends_on = [aws_s3_bucket_public_access_block.ansible]
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible" {
  bucket = aws_s3_bucket.ansible.id

  rule {
    id     = "expire-transfer-files"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
