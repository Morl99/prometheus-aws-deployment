resource "aws_iam_user" "prometheus" {
  name = "prometheus"
  path = "/system/"
}

resource "aws_iam_access_key" "prometheus" {
  user = aws_iam_user.prometheus.name
}

resource aws_secretsmanager_secret prometheus {
  name = "prometheus/iam"
}

resource "aws_secretsmanager_secret_version" "prometheus" {
  secret_id = aws_secretsmanager_secret.prometheus
  secret_string = jsonencode({"KEY_ID"=aws_iam_access_key.prometheus.id, "SECRET" = aws_iam_access_key.prometheus.secret})
}

resource "aws_iam_user_policy" "prometheus_describe" {
  name = "ec2_describe"
  user = aws_iam_user.prometheus.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ebs_volume" "prometheus_volume" {
  availability_zone = "eu-central-1a"
  size              = 80
}