variable "ci_ami_id" {
  description = "Ubuntu 24.04 AMI for the CI machine, looked up from Canonical's SSM parameter. Updated by hand in a PR."
  type        = string
  default     = "ami-084df9e6ad4622caf"

  validation {
    condition     = can(regex("^ami-[0-9a-f]{17}$", var.ci_ami_id))
    error_message = "ci_ami_id must be an AMI ID such as ami-0123456789abcdef0."
  }
}
