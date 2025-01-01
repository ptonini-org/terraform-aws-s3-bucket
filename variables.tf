variable "name" {}

variable "force_destroy" {
  default  = false
  nullable = false
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "object_ownership" {
  default  = "BucketOwnerEnforced"
  nullable = false
}

variable "acl" {
  default  = "private"
  nullable = false
}

variable "versioning" {
  default  = "Enabled"
  nullable = false
}

variable "create_policy" {
  default  = false
  nullable = false
}

variable "policy_name" {
  default = null
}

variable "bucket_policy_statements" {
  default  = []
  nullable = false
}

variable "server_side_encryption" {
  type = object({
    kms_master_key_id = optional(string)
    sse_algorithm     = optional(string, "aws:kms")
  })
  default  = {}
  nullable = false
}

variable "inventory" {
  type = object({
    enabled                  = optional(bool, true)
    included_object_versions = optional(string, "All")
    schedule_frequency       = optional(string, "Weekly")
    bucket_arn               = string
    bucket_format            = optional(string, "ORC")
  })
  default = null
}

variable "public_access_block" {
  type = object({
    restrict_public_buckets = optional(bool, true)
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, false)
    ignore_public_acls      = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "lifecycle_rules" {
  type = map(object({
    id              = string
    status          = string
    expiration_days = number
  }))
  default = null
}

variable "logging" {
  type = object({
    target_bucket = string
    target_prefix = optional(string)
  })
  default = null
}

