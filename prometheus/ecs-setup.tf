///*
//
//
//### Security
//
//# ALB Security group
//# This is the group you need to edit if you want to restrict access to your application
//resource "aws_security_group" "lb" {
//  name        = "ecs-alb"
//  description = "controls access to the ALB"
//  vpc_id      = aws_vpc.main.id
//
//  ingress {
//    protocol    = "tcp"
//    from_port   = 80
//    to_port     = 80
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  egress {
//    from_port = 0
//    to_port   = 0
//    protocol  = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//# Traffic to the ECS Cluster should only come from the ALB
//resource "aws_security_group" "ecs_tasks" {
//  name        = "ecs-tasks"
//  description = "allow inbound access from the ALB only"
//  vpc_id      = aws_vpc.main.id
//
//  ingress {
//    protocol        = "tcp"
//    from_port       = "9090"
//    to_port         = "9090"
//    security_groups = [aws_security_group.lb.id]
//  }
//
//  egress {
//    protocol    = "-1"
//    from_port   = 0
//    to_port     = 0
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//### ALB
//
//resource "aws_alb" "main" {
//  name            = "prometheus"
//  subnets         = aws_subnet.public.*.id
//  security_groups = [aws_security_group.lb.id]
//}
//
//resource "aws_alb_target_group" "app" {
//  name        = "prometheus"
//  port        = 80
//  protocol    = "HTTP"
//  vpc_id      = "${aws_vpc.main.id}"
//  target_type = "ip"
//}
//
//# Redirect all traffic from the ALB to the target group
//resource "aws_alb_listener" "front_end" {
//  load_balancer_arn = aws_alb.main.id
//  port              = "80"
//  protocol          = "HTTP"
//
//  default_action {
//    target_group_arn = aws_alb_target_group.app.id
//    type             = "forward"
//  }
//}
//
//### ECS
//
//resource "aws_ecs_cluster" "main" {
//  name = "ecs-cluster"
//}
//
//variable "fargate_cpu" {
//  default = "256"
//}
//
//variable "fargate_memory" {
//  default = "512"
//}
//
//variable "app_port" {
//  default = 9090
//}
//
//resource "aws_ecs_task_definition" "app" {
//  family                   = "app"
//  network_mode             = "awsvpc"
//  requires_compatibilities = ["FARGATE"]
//  cpu                      = var.fargate_cpu
//  memory                   = var.fargate_memory
//
//  container_definitions = <<DEFINITION
//[
//  {
//    "cpu": ${var.fargate_cpu},
//    "image": "prom/prometheus",
//    "memory": ${var.fargate_memory},
//    "name": "app",
//    "networkMode": "awsvpc",
//    "portMappings": [
//      {
//        "containerPort": ${var.app_port},
//        "hostPort": ${var.app_port}
//      }
//    ]
//  }
//]
//DEFINITION
//}
//
//resource "aws_ecs_service" "main" {
//  name            = "ecs-service"
//  cluster         = aws_ecs_cluster.main.id
//  task_definition = aws_ecs_task_definition.app.arn
//  desired_count   = "1"
//  launch_type     = "FARGATE"
//
//  network_configuration {
//    security_groups = [aws_security_group.ecs_tasks.id]
//    subnets         = aws_subnet.private.*.id
//  }
//
//  load_balancer {
//    target_group_arn = aws_alb_target_group.app.id
//    container_name   = "app"
//    container_port   = var.app_port
//  }
//
//  depends_on = [
//    "aws_alb_listener.front_end",
//  ]
//}*/
