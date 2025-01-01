output "this" {
  value = aws_s3_bucket.this
}

output "policy_statement" {
  value = local.policy_statement
}

output "policy_arn" {
  value = try(module.policy[0].this["arn"], null)
}