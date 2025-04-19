# https://sophiabits.com/blog/managing-your-aws-organization-in-terraform#bonus-points-configure-your-subaccount
resource "aws_iam_policy" "assume_access" {
  name   = "terraform-assume-${var.account.name}-role"
  policy = data.aws_iam_policy_document.assume_access.json
}

data "aws_iam_policy_document" "assume_access" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account.id}:role/*"]
  }
}

data "aws_iam_user" "terraform" { user_name = "Terraform" }

resource "aws_iam_policy_attachment" "assume_access" {
  name       = "terraform-assume-${var.account.name}-role-attachment"
  policy_arn = aws_iam_policy.assume_access.arn
  users      = [data.aws_iam_user.terraform.user_name]
}

provider "aws" {
  alias  = "child"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.account.id}:role/${var.account.role_name}"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  provider = aws.child
  bucket   = "${var.account.name}-terraform"
}

resource "aws_s3_bucket_acl" "terraform_state" {
  provider = aws.child
  bucket   = aws_s3_bucket.terraform_state.id
  acl      = "private"
}

# Keep old Terraform state files
resource "aws_s3_bucket_versioning" "terraform_state" {
  provider = aws.child
  bucket   = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  provider     = aws.child
  name         = "terraform-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "Terraform Lock Table"
  }
}

resource "aws_iam_user" "terraform" {
  provider = aws.child
  name     = "Terraform"
  path     = "/"
}

resource "aws_iam_user_policy_attachment" "terraform" {
  provider = aws.child
  user     = aws_iam_user.terraform.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
