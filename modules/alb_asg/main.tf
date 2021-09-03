# Création du Groupe de sécurité pour mon ELB 
#                     (ou plutôt pour mon ALB)
# autorisant uniquement le traffic provenant d'internet
# sur le port 80
resource "aws_security_group" "alb-sg" {
    name        = "${var.prefix_name}alb-sg"
    description = "Security group for the load balancer"
    vpc_id      = var.vpc_id # Récupérer l'id de notre VPC

    ingress {
        description  = "from Internet"
        from_port    = var.webserver_port
        to_port      = var.webserver_port
        protocol     = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.prefix_name}alb-sg"
    }
}

# Création du Groupe de sécurité pour mes instances ASG (AutoScaling Groups)
# autorisant uniquement le traffic provenant de notre ELB sur le port 80
resource "aws_security_group" "asg-instances-sg" {
    name = "${var.prefix_name}asg-webserver-sg"
    description = "Security group for ASG instances" # Allow ELB inbound traffic on port 80"
    vpc_id = var.vpc_id # Récupérer l'id de notre VPC

    ingress {
        description = "from ALB"
        from_port   = var.webserver_port
        to_port     = var.webserver_port
        protocol    = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
    }

    ingress {
        description = "for ASG webserver instances"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.prefix_name}asg-webserver-sg"
    }
}

# Public key to connect to ec2 instances
resource "aws_key_pair" "mykeypair" {
  key_name   = "${var.prefix_name}key"
  public_key = file(var.path_to_public_key)
}

# Création d'une configuration de lancement de mon ASG
# où je spécifie l'ami (image_id est requis)
# le type d'instance ("t2.micro" pour rester dans l'offre gratuite d'AWS)
# le profil d'instance, ? avec mon rôle IAM,?
# le user-data, décrit en paramètre d'entrée du module
# la paire de clés,
# le groupe de sécurité à utiliser sur les instances de mon ASG

resource "aws_launch_configuration" "my-launchconfig" {
  name_prefix          = "${var.prefix_name}launchconfig"
  image_id             = var.ami # (Required) The EC2 image ID to launch.
  instance_type        = var.instance_type
  key_name             = aws_key_pair.mykeypair.key_name # (Optional) The key name that should be used for the instance.
  security_groups      = [aws_security_group.asg-instances-sg.id]
  user_data            = var.user_data # décrit en paramètre d'entrée du module
  iam_instance_profile = var.role_profile_name # (Optional) The name attribute of the IAM instance profile to associate with launched instances.
  
  lifecycle {
    create_before_destroy = true
  }
}

# Création de mon AutoScaling Groups (ASG)
# où je spécifie la configuration de lancement créé précédemment,
# les subnets privés, surlesquels se lanceront mes instances
# mon Target Group (<target_group_arns>) et non service_linked_role_arn
# un contrôle de type "ELB" (<health_check_type>)
# le nombre désiré / minimum / maximum de mes instances
# L'option <force_delete>, qui permet de modifier
#    le comportement par défaut de destruction de Terraform
# La mettre à true forcera la suppression de mon ASG
#    sans attendre la mise en fin de toutes les instances de mon ASG

resource "aws_autoscaling_group" "my_autoscaling" {
    name                      = "${var.prefix_name}autoscaling"
    vpc_zone_identifier       = flatten([var.private_subnet_ids])
    launch_configuration      = aws_launch_configuration.my-launchconfig.name
    min_size                  = var.min_instance
    desired_capacity          = var.desired_instance
    max_size                  = var.max_instance
    health_check_grace_period = 300 
    health_check_type         = "ELB"
    target_group_arns         = [ aws_lb_target_group.my-alb-tg.arn ]
    force_delete              = true
    
    tag {
        key = "Name"
        value = "${var.prefix_name}asg"
        propagate_at_launch = true
    }
}

# Création d'un équilibreur de charge, de type "Application"
# attaché à mon subnet public et
# attaché à mon groupe de sécurité ELB
resource "aws_lb" "my-alb" {
    name               = "${var.prefix_name}tf-alb"
    internal           = false
    load_balancer_type = "application"
    subnets            = flatten([var.public_subnet_ids])
    security_groups    = [aws_security_group.alb-sg.id]

    enable_deletion_protection = true

    provisioner "local-exec" {
        when = destroy
        interpreter = ["/bin/bash","-c"]
        command = "scripts/destroy_alb.sh ${self.arn}"
    }

    # impossible de récupérer la valeur de aws_lb.my-alb.arn ou ${self.arn} dans le script

    # access_logs {
    #    bucket  = aws_s3_bucket.lb_logs.bucket # (Required) The S3 bucket name to store the logs in.
    #    prefix  = "test-lb" # (Optional) The S3 bucket prefix. Logs are stored in the root if not configured.
    #    enabled = true # (Optional) Boolean to enable / disable access_logs. Defaults to false, even when bucket is specified.
    # }

    tags = {
        Name = "${var.prefix_name}alb"
    }
}

# Création d'une Target Group sur le port 80
# afin d'aider mon ELB à 
# acheminer les requêtes http vers les instances de mon ASG
resource "aws_lb_target_group" "my-alb-tg" {
    name        = "${var.prefix_name}alb-tg"
    port        = var.webserver_port
    protocol    = var.webserver_protocol # HTTP or HTTPS, Protocol to use for routing traffic to the targets.
    vpc_id      = var.vpc_id # Récupérer l'id de notre VPC
    # target_type = instance # targets are specified by instance ID. The default is instance.

    tags = {
        Name = "${var.prefix_name}alb-tg"
    }
}

# Création d'un HTTP Listener
# attaché à mon ELB (équilibreur de charge, de type application) et
# attaché à mon Target Group
# pour déterminer comment mon ELB acheminera 
#  les demandes vers les cibles enregistrées dans mon Target Group
resource "aws_lb_listener" "alb-listener" {
    load_balancer_arn = aws_lb.my-alb.arn
    port              = var.webserver_port 
    protocol          = var.webserver_protocol
    
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.my-alb-tg.arn
    }
    
    tags = {
        Name = "${var.prefix_name}alb-listener"
    }
}
