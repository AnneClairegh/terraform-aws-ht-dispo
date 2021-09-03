# Création d'un groupe de sécurité autorisant uniquement
#   le trafic provenant de vos instances web sur le port 3306.
resource "aws_security_group" "mariadb-sg" {
    vpc_id      = var.vpc_id
    name        = "${var.prefix_name}database-sg"
    description = "Security group for the database"

    ingress {
        description     = "from web"
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = var.webserver_sg_id # security groupd id of the webserver
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.prefix_name}database-sg"
    }
}

# Création du db_subnet_group
# pour attacher la base de données à son subnet privé
resource "aws_db_subnet_group" "mariadb-subnet" {
    name        = "mariadb-subnet"
    description = "RDS subnet group"
    subnet_ids  = var.private_subnet_ids

    tags = {
        Name = "${var.prefix_name}mariadb-subnet"
    }
}

# Paramètres de la Base de Données (mariadb)
resource "aws_db_parameter_group" "mariadb-parameters" {
  name        = "mariadb-params"
  family      = "mariadb10.2" # Please use a Parameter Group with DBParameterGroupFamily mariadb10.2
  description = "MariaDB parameter group"

  ## Parameters example
  # parameter {
  #   name  = "max_allowed_packet"
  #   value = 16777216
  # }
}

# Création de ma base de données de type "mariadb", 
#                en utilisant le service RDS.
#                attachée à mon subnet privé et
#                attachée au groupe de sécurité créé antérieurement.
#                possède une classe de type "db.t2.micro",
#                possède 20 Go de stockage maximum
#                possède des sauvegardes automatisées activées
#                        avec une période de rétention d'un jour
#                        afin que je reste éligible à l'offre gratuite d'AWS.
#                possède l'option "Multi-AZ" activée
resource "aws_db_instance" "mariadb" {
    allocated_storage         = var.storage_gb # Required unless a snapshot_identifier or replicate_source_db is provided
    engine                    = "mariadb" # Required unless a snapshot_identifier or replicate_source_db is provided
    engine_version            = var.mariadb_version
    instance_class            = var.mariadb_instance_type
    identifier                = "mariadb" # (Optional, Forces new resource) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier. Required if restore_to_point_in_time is specified.
    name                      = var.db_name # (Optional) The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance.
    username                  = var.db_username
    password                  = var.db_password
    db_subnet_group_name      = aws_db_subnet_group.mariadb-subnet.name # If unspecified, will be created in the default VPC, or in EC2 Classic, if available.
    parameter_group_name      = aws_db_parameter_group.mariadb-parameters.name
    multi_az                  = var.is_multi_az
    vpc_security_group_ids    = [aws_security_group.mariadb-sg.id]
    storage_type              = var.storage_type
    backup_retention_period   = var.backup_retention_period # The number of days for which automated backups are retained.
    final_snapshot_identifier = "${var.prefix_name}mariadb-snapshot" # (Optional) # final snapshot when executing terraform destroy.
    max_allocated_storage     = 20

    tags = {
        Name = "${var.prefix_name}mariadb"
    }

    provisioner "local-exec" {
        when = destroy
        interpreter = ["/bin/bash","-c"]
        command = "scripts/destroy_mariadb.sh ${self.identifier}"
    }
}
 