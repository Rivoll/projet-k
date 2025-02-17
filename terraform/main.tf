provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket         = "qaazuo-tf-state-bucket"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-lock"  # Optional: for state locking
    encrypt        = true              # Encrypt the state file
  }
}



# Data Source: Default VPC
data "aws_vpc" "default" {
  default = true
}

# Data Source: Subnets in Default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


data "aws_security_group" "default" {
    filter {
    name   = "group-name"
    values = ["default"]
    }
}

/*
resource "aws_instance" "worker" {
  ami           = "ami-09be70e689bddcef5"
  instance_type = "t2.micro"  # Replace with your desired instance type


  security_groups = [aws_security_group.worker_sg.name]
}
*/

resource "aws_instance" "admin" {
  ami           = "ami-09be70e689bddcef5"
  instance_type = "t3.medium"  


  vpc_security_group_ids  = [module.security_group.security_group_id]

  key_name = "projet-k"
  iam_instance_profile = "admin-profile"
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
  tags = {
    Name = "Admin-k8s-instance"
  }
}

resource "aws_instance" "worker" {
  ami           = "ami-09be70e689bddcef5"
  instance_type = "t3.medium"  

  vpc_security_group_ids  = [module.security_group.security_group_id]

  key_name = "projet-k"
  iam_instance_profile = "admin-profile"
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
  tags = {
    Name = "worker-1"
  }
}

# Admin Node IAM Policy
resource "aws_iam_policy" "admin_node_policy" {
  name        = "AdminNodePolicy"
  description = "IAM policy for Kubernetes admin nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "*"
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Admin Node IAM Role
resource "aws_iam_role" "admin_node_role" {
  name               = "KubernetesAdminNodeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the Admin Node Policy to the Role
resource "aws_iam_role_policy_attachment" "admin_node_policy_attachment" {
  role       = aws_iam_role.admin_node_role.name
  policy_arn = aws_iam_policy.admin_node_policy.arn
}

resource "aws_iam_policy" "worker_node_policy" {
  name        = "WorkerNodePolicy"
  description = "IAM policy for Kubernetes worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "elasticloadbalancing:*",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "autoscaling:Describe*",
          "cloudwatch:*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "s3:GetObject",
          "s3:ListBucket",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


# Worker Node IAM Role
resource "aws_iam_role" "worker_node_role" {
  name               = "KubernetesWorkerNodeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the Worker Node Policy to the Role
resource "aws_iam_role_policy_attachment" "worker_node_policy_attachment" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = aws_iam_policy.worker_node_policy.arn
}

# IAM Instance Profile for k8s Workers
resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker-profile"
  role = aws_iam_role.worker_node_role.name
}

# IAM Instance Profile for k8s Workers
resource "aws_iam_instance_profile" "admin_profile" {
  name = "admin-profile"
  role = aws_iam_role.admin_node_role.name
}

# Security Group for k8s Workers

module "security_group" {
  source         = "./sg"
  sg_name        = "worker_sg"
  sg_description = "Security Group for my app"
  vpc_id         = data.aws_vpc.default.id

  ingress_rules = [
    # Allow all traffic from a specific my IP
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["91.169.209.14/32"]
    },
    
    # Allow HTTP from anywhere
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    # Allow connections from another security group (e.g., Load Balancer SG)
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    # Allow connections from another security group (e.g., Load Balancer SG)
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = ["sg-03ae0747b59944a80"]
    },

    # Allow connections from another security group (e.g., Load Balancer SG)
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = ["sg-0722a80ca9819e761"]
    }
  ]

  egress_rules = [
    # Allow all outbound traffic
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Environment = "Production"
    Owner       = "DevOps Team"
  }
}



# Launch Template for k8s Workers
resource "aws_launch_template" "worker_template" {
  name_prefix   = "worker-template"
  image_id      = "ami-09be70e689bddcef5"
  instance_type = "t3.medium"
  key_name = "projet-k"

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [module.security_group.security_group_id]
  }
}




# Auto Scaling Group for k8S Workers
/*
resource "aws_autoscaling_group" "worker_asg" {
  name                = "ASG-projet-k"
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = data.aws_subnets.default_subnets.ids

  launch_template {
    id      = aws_launch_template.worker_template.id
    version = "$Latest"
  }

  tag {
    
    key                 = "kubernetes.io/cluster/example-cluster"
    value               = "owned"
    propagate_at_launch = true
  }
}
*/








