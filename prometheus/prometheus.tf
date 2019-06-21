provider "aws" {
  region                  = "eu-central-1"
  shared_credentials_file = "C:/Users/test/.aws/credentials"
  profile                 = "default"
}

resource "aws_iam_user" "prometheus" {
  name = "prometheus"
  path = "/system/"
}

resource "aws_iam_access_key" "prometheus" {
  user = "${aws_iam_user.prometheus.name}"
}

resource "aws_iam_user_policy" "prometheus_describe" {
  name = "ec2_describe"
  user = "${aws_iam_user.prometheus.name}"

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