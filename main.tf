resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_144: LOW severity
  #checkov:skip=CKV_AWS_145: LOW severity
  bucket        = var.name
  force_destroy = var.force_destroy
  tags          = var.tags
  lifecycle {
    ignore_changes = [
      server_side_encryption_configuration,
      tags["business_unit"],
      tags["product"],
      tags["env"],
      tags_all
    ]
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  #checkov:skip=CKV_AWS_54: Allow public bucket
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.public_access_block.block_public_acls
  block_public_policy     = var.public_access_block.block_public_policy
  ignore_public_acls      = var.public_access_block.ignore_public_acls
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      kms_master_key_id = var.server_side_encryption.kms_master_key_id
      sse_algorithm     = var.server_side_encryption.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  #checkov:skip=CKV_AWS_70: Broken
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(var.bucket_policy_statements, [{
      Principal = "*"
      Effect    = "Deny"
      Action    = ["s3:*"]
      Resource  = ["arn:aws:s3:::${aws_s3_bucket.this.bucket}", "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }])
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_rules == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      expiration {
        days = rule.value.expiration_days
      }
    }
  }
}

resource "aws_s3_bucket_inventory" "this" {
  count                    = var.inventory == null ? 0 : 1
  bucket                   = aws_s3_bucket.this.id
  name                     = aws_s3_bucket.this.bucket
  enabled                  = var.inventory.enabled
  included_object_versions = var.inventory.included_object_versions

  schedule {
    frequency = var.inventory.schedule_frequency
  }

  destination {

    bucket {
      format     = var.inventory.bucket_format
      bucket_arn = var.inventory.bucket_arn
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  count         = var.logging == null ? 0 : 1
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging.target_bucket
  target_prefix = coalesce(var.logging.target_prefix, var.name)
}

locals {
  policy_statement = [
    {
      effect    = "Allow"
      actions   = ["s3:ListAllMyBuckets"]
      resources = ["arn:aws:s3:::*"]
    },
    { effect    = "Allow"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads", "s3:ListBucketVersions"]
      resources = [aws_s3_bucket.this.arn]
    },
    { effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
      resources = ["${aws_s3_bucket.this.arn}/*"]
    }
  ]
}

module "policy" {
  #checkov:skip=CKV_TF_1: Private module
  source    = "app.terraform.io/ptonini-org/iam-policy/aws"
  version   = "~> 1.0.0"
  count     = var.create_policy ? 1 : 0
  name      = coalesce(var.policy_name, "${var.name}-bucket")
  statement = local.policy_statement
}