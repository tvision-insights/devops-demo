provider "aws" {
  version = "~> 1.0"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
  allowed_account_ids = ["${var.aws_account_id}"]
}
