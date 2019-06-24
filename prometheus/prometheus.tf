resource "aws_iam_user" "prometheus" {
  name = "prometheus"
  path = "/system/"

}

resource "aws_iam_access_key" "prometheus" {
  user = aws_iam_user.prometheus.name
}

resource aws_secretsmanager_secret prometheus-key-id {
  name = "prometheus/iam/key-id"
}

resource "aws_secretsmanager_secret_version" "prometheus-key-id" {
  secret_id     = aws_secretsmanager_secret.prometheus-key-id.id
  secret_string = aws_iam_access_key.prometheus.id
}

resource aws_secretsmanager_secret prometheus-secret {
  name = "prometheus/iam/secret"
}

resource "aws_secretsmanager_secret_version" "prometheus-secret" {
  secret_id     = aws_secretsmanager_secret.prometheus-secret.id
  secret_string = aws_iam_access_key.prometheus.secret
}
data "aws_kms_key" "secretsmanager" {
  key_id = "alias/aws/secretsmanager"
}

resource "aws_iam_role" "prometheus_secrets" {
  name = "prometheus_secrets"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prometheus_secrets" {
  policy_arn = aws_iam_policy.ecs-prometheus-secret.arn
  role       = aws_iam_role.prometheus_secrets.name
}

resource "aws_iam_policy" "ecs-prometheus-secret" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.prometheus-key-id.arn}",
        "${aws_secretsmanager_secret.prometheus-secret.arn}",
        "${data.aws_kms_key.secretsmanager.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
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

// TODO this should be mounted to the Docker container to have persistent data
resource "aws_ebs_volume" "prometheus_volume" {
  availability_zone = "eu-central-1a"
  size              = 80
}

variable "fargate_cpu" {
  default = "256"
}

variable "fargate_memory" {
  default = "512"
}

variable "app_port" {
  default = 9090
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.prometheus_secrets.arn
  container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "morl99/prometheus-ec2",
    "memory": ${var.fargate_memory},
    "name": "prometheus-ec2",
    "networkMode": "awsvpc",
    "user" : "nobody",
    "secrets": [
      {
          "name": "KEY_ID",
          "valueFrom": "${aws_secretsmanager_secret.prometheus-key-id.arn}"
      },
      {
          "name": "SECRET",
          "valueFrom": "${aws_secretsmanager_secret.prometheus-secret.arn}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
DEFINITION
}

resource "aws_security_group" "prometheus_ingress" {
  name        = "ecs-prometheus-ingress"
  description = "controls access to the prometheus web endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "main" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = "1"
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.prometheus_ingress.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }
}