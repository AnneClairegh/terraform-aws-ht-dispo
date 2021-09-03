provider "aws" {
    region = var.region
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
}

module "my_vpc" {
    source               = "./modules/vpc"
    vpc_cidr             = "10.0.0.0/16"
    public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
    azs                  = ["us-east-2a", "us-east-2b"]
    prefix_name          = var.prefix_name
}

module "my_s3" {
    source              = "./modules/s3"
    bucket_name         = "stockage-des-sources-ec2"
    path_folder_content = "./src/"

}

module "my_ec2_role" {
    source = "./modules/ec2_role_allow_s3"
    prefix_name = var.prefix_name
    bucket_name = var.bucket_name
}

module "my_alb_asg" {
    source             = "./modules/alb_asg"
    prefix_name        = var.prefix_name
    vpc_id             = module.my_vpc.vpc_id
    public_subnet_ids  = [module.my_vpc.public_subnet_ids]
    private_subnet_ids = [module.my_vpc.private_subnet_ids]
    webserver_port     = 80
    webserver_protocol = "HTTP"
    instance_type      = "t2.micro"
    role_profile_name  = module.my_ec2_role.profil
    min_instance       = 2
    desired_instance   = 2
    max_instance       = 3
    path_to_public_key = "./keys/terraform.pub"
    # path_to_public_key = "/home/ac/Bureau/tp9_terraform-aws-ht-dispo/keys/terraform.pub"
    ami                = data.aws_ami.ubuntu-ami.id
    
# Ce user_data contiendra :
# Mise à jour de la liste des packages de notre distribution.
# Installation du service web apache, l'interpréteur php avec la bibliothèque mysql et la cli d'AWS.
# Activation permanente du service apache via la commande  systemctl .
# Suppression de la page web d'accueil par défaut  index.html . 
# Téléchargement de nos sources depuis notre bucket S3. 
# Création de l'architecture de la table de notre base de données mariadb. 
# Configuration de la partie base de données de notre application web depuis la commande sed.
    user_data = <<-EOF
      #!/bin/bash
      sudo apt-get update -y
      sudo apt-get install -y apache2 awscli mysql-client php php-mysql
      sudo systemctl enable apache2
      sudo systemctl start apache2
      sudo rm -f /var/www/html/index.html
      sudo aws s3 sync  s3://${var.bucket_name}/ /var/www/html/
      mysql -h ${module.my_rds.host} -u ${module.my_rds.username} -p${var.db_password} < /var/www/html/articles.sql
      sudo sed -i 's/##DB_HOST##/${module.my_rds.host}/' /var/www/html/db-config.php
      sudo sed -i 's/##DB_USER##/${module.my_rds.username}/' /var/www/html/db-config.php
      sudo sed -i 's/##DB_PASSWORD##/${var.db_password}/' /var/www/html/db-config.php
      EOF
}

module "my_rds" {
    source                   =  "./modules/rds"
    prefix_name              = var.prefix_name
    vpc_id                   = module.my_vpc.vpc_id
    private_subnet_ids       = module.my_vpc.private_subnet_ids
    webserver_sg_id          = module.my_alb_asg.webserver_sg_id
    storage_gb               = 5
    mariadb_version          = "10.2.11"
    mariadb_instance_type    = "db.t2.micro"
    db_name                  = "mariadb_AC"
    db_username              = "root"
    db_password              = var.db_password
    is_multi_az              = true
    storage_type             = "gp2"
    backup_retention_period  = 1
}

module "my_cloudwatch" {
    source                = "./modules/cloudwatch_cpu_alarms"
    prefix_name           = var.prefix_name
    max_cpu_percent_alarm = 80
    min_cpu_percent_alarm = 5
    asg_name              = module.my_alb_asg.asg_name
}
