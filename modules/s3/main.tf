# Création d'un bucket S3
# avec un ACL prêt à l'emploi de type "private"
resource "aws_s3_bucket" "s3_sources" {
    bucket = var.bucket_name
    acl    = "private"

    provisioner "local-exec" {
        when = destroy
        interpreter = ["/bin/bash","-c"]
        command = "scripts/destroy_s3.sh ${self.bucket}"
    }

    tags = {
        Name = var.bucket_name
    }
}

# Dépose automatique des sources de l'application web 
# dans le bucket s3 créé
resource "null_resource" "add_src_to_s3" {
    triggers = {
        build_number = timestamp() # run it all times
        # build_number = "${timestamp()}" # run it all times
    }
    
    provisioner "local-exec" {
        command = "aws s3 sync ${var.path_folder_content} s3://${var.bucket_name}/"
    }
    depends_on = [aws_s3_bucket.s3_sources]
}
# vide le bucket s3, quand il doit être détruit 
# provisioner "local-exec" {
#     when = destroy
#     command = "aws s3 rm s3://${self.bucket} --recursive/"
# }

# Création d'un hôte bastion (une instance EC2 sur un de nos subnets publiques)
# "ImageLocation": "099720109477/ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200408"
# "ami-08c757228751c5335" # The ImageId of eu-west-3 region Paris.
# "ami-0eb89db7593b5d434" # The ImageId of eu-west-2 region London.
# resource "aws_instance" "bastion-ubuntu" {
#     ami = "ami-08c757228751c5335" # The ImageId of eu-west-3 region Paris.
#     instance_type = "t2.micro"
#     vpc_security_group_ids = aws_security_group.inst_elb_sg.id
#     subnet_id = "var.private_subnet_ids" # (Optional) VPC Subnet ID to launch in.
#     tags = {
#         Name = "${var.prefix_name}-bastion-ubuntu"
#     }
# }
# Vous pouvez aussi utiliser les VPCs EndPoints pour se connecter à votre service S3,
# qui uitilse AWS Glue

