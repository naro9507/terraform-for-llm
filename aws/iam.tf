resource "aws_iam_user" "terraform_runner_user" {
  name = "terraform-admin-user"
  tags = {
    Environment = "Development"
    Project     = "TerraformManagement"
  }
}

resource "aws_iam_access_key" "terraform_user_key" {
  user = aws_iam_user.terraform_runner_user.name
}

resource "aws_iam_user_policy_attachment" "terraform_admin_access" {
  user       = aws_iam_user.terraform_runner_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "bedrock_dev_user" {
  name = "bedrock-access-dev-user"
  tags = {
    Purpose   = "Use Local Development Tool"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "bedrock_invoke_policy" {
  name        = "bedrock-invoke-model-policy"
  description = "Policy to allow invoking Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "bedrock_invoke_attachment" {
  user       = aws_iam_user.bedrock_dev_user.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}

# 4. IAMアクセスキーの作成 (プログラムからのアクセス用)
resource "aws_iam_access_key" "bedrock_dev_user_key" {
  user = aws_iam_user.bedrock_dev_user.name
}

# 出力: アクセスキーIDとシークレットアクセスキー
# !!! 注意: これらの情報は非常に機密性が高いため、安全に管理してください !!!
# バージョン管理システムに直接コミットしたり、公開したりしないでください。
output "terraform_access_key_id" {
  description = "The access key ID for Terraform IAM user."
  value       = aws_iam_access_key.terraform_user_key.id
  sensitive   = true
}

output "terraform_secret_access_key" {
  description = "The secret access key for Terraform IAM user."
  value       = aws_iam_access_key.terraform_user_key.secret
  sensitive   = true
}

output "bedrock_access_key_id" {
  description = "The access key ID for the Bedrock IAM user."
  value       = aws_iam_access_key.bedrock_dev_user_key.id
  sensitive   = true
}

output "bedrock_secret_access_key" {
  description = "The secret access key for the Bedrock IAM user."
  value       = aws_iam_access_key.bedrock_dev_user_key.secret
  sensitive   = true
}
