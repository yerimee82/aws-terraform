# 프로바이더 지정
provider "aws" {
  region = "ap-northeast-2"
}

# 사용자 생성
resource "aws_iam_user" "tftest" {
  name = "terraformtest"
  path = "/system/"

  # 태그 설정 가능
#   tags = {
#     tag-key = "testValue"
#   }
}

# 그룹 생성 및 연결 
resource "aws_iam_group" "terraformtest" {
  name = "terraformtest"
  path = "/system/"
}

/* 그룹에 사용자 추가하기 - aws_iam_group_membership 
* 특정 그룹에 여러 사용자를 한 번에 추가함
* 그룹 중심으로 멤버십 정의 
*/

resource "aws_iam_group_membership" "team" {
  name = "tf_test-membership"

  users = [
    aws_iam_user.tftest.name
  ]

  group = aws_iam_group.terraformtest.name
}


/* 사용자를 여러 그룹에 추가하기 - aws_iam_user_group_membership
* 특정 사용자가 여러 그룹에 속하게 되는 경우 사용
* 사용자 중심으로 그룹 멤버십 정의
*/

// 기존 그룹에 추가 
data "aws_iam_group" "existing_developers" {
  group_name = "developers"
}

resource "aws_iam_user_group_membership" "name" {
  user = aws_iam_user.tftest.name
  groups = [ data.aws_iam_group.existing_developers.group_name ]
}

# 정책 추가하기 
# jsonencode 활용하기 : https://developer.hashicorp.com/terraform/language/functions/jsonencode

resource "aws_iam_policy" "tftest_policy" {
  name = "tftest_policy"
  path = "/system/"
  description = "terraform policy test"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListAllMyBuckets"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
          ]
        Resource = "arn:aws:s3:::julook-lambda-edge-image-resize/*"
      }
    ]
  })
}

# 정책과 그룹 연결 
resource "aws_iam_group_policy_attachment" "test-attach" {
  group = aws_iam_group.terraformtest.name
  policy_arn = aws_iam_policy.tftest_policy.arn
}