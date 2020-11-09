provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

resource "aws_ecs_cluster" "scim-bridge" {
  name = "scim-bridge"
}

resource "aws_ecs_task_definition" "scim-bridge" {
  family                   = "scim-bridge"
  container_definitions    =  file("task-definitions/scim.json")
  #volume {
  #  name      = "data"
  #  host_path = "/data"
  #}
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole-scim-bridge.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole-scim-bridge" {
  name               = "ecsTaskExecutionRole-scim-bridge"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy-scim-bridge" {
  role       = aws_iam_role.ecsTaskExecutionRole-scim-bridge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "scim_bridge_service" {
  name            = "scim_bridge_service"
  cluster         = aws_ecs_cluster.scim-bridge.id
  task_definition = aws_ecs_task_definition.scim-bridge.arn
  launch_type     = "FARGATE"
  desired_count   = 1 

  /**load_balancer {
    target_group_arn = aws_lb_target_group.target_group_http.arn 
    container_name   = aws_ecs_task_definition.scim-bridge.family
    container_port   = 8080 # Specifying the container port
  }*/

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_https.arn
    container_name   = aws_ecs_task_definition.scim-bridge.family
    container_port   = 8443 # Specifying the container port
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = [aws_security_group.service_security_group.id] # Setting the security group
  }
}

resource "aws_alb" "scim-bridge-alb" {
  name               = "scim-bridge-alb" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id,
    aws_default_subnet.default_subnet_c.id
  ]
  # Referencing the security group
  security_groups = [aws_security_group.scim-bridge-sg.id]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "scim-bridge-sg" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  ingress {
    from_port   = 443 # Allowing traffic in from port 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.scim-bridge-sg.id]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "target_group_http" {
  name        = "target-group-http"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_alb.scim-bridge-alb.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_http.arn # Referencing our target group
  }
}

resource "aws_lb_target_group" "target_group_https" {
  name        = "target-group-https"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.scim-bridge-alb.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:729119775555:certificate/7b939514-6eee-496f-97dd-b30a63331db7"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_https.arn # Referencing our target group
  }
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-1c"
}