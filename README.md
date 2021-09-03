# Construire avec Terraform une infrastructure AWS hautement disponible

## Description

This module builds a highly available AWS infrastructure from Terraform for a php web application communicating with a database.

![infrastructure schema](./imgs/infrastructure-schema.jpg)

## Modules

| name                    |  usage |
|-------------------------|--------|
| `vpc`                   | Creates VPC  with two public subnets for the ELB and two private subnets for the EC2 instances and the RDS service on different AZs| 
| `alb_asg`               | Creates an Auto Scaling group with ELB of type "application" |
| `cloudwatch_cpu_alarms` | Creates a cloudwatch alarms depending on the CPU usage and triggering ASG operations |    
| `s3`                    | Creates an S3 bucket on which the sources of the application will be put |
| `ec2_role_allow_s3`     | Creates an instance profile using an iam role authorizing access to S3 from the EC2 instances |
| `rds`                   | Creates a mariadb relational database used for the EC2 web instances | 

## How it works 

To use this project, first indicate the root password of the database, for example in a file called `terraform.tfvars` (this file name is automatically considered by Terraform during the execution of your configuration). Example :

```tfvars
db_password = "your-password"
```

Second, create your ssh key pair in the `keys` folder. Use the `ssh-keygen` command as follows :

```shell
ssh-keygen -t rsa

Generating public/private rsa key pair.
Enter file in which to save the key (/home/hatim/.ssh/id_rsa): ./keys/terraform
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
```

Then add the path of your public key in the root module in the `path_to_public_key` parameter of the `my_alb_asg module`. For example :

```hcl
module "my_alb_asg" {
    ...
    ...
    path_to_public_key   = "./keys/terraform.pub"
    ...
    ...
}
```

You can then launch your configuration with the following command

```shell
terraform init && terraform apply
```

Result :

```
...
...

Outputs:

alb_dns_name = [DNS OF YOUR ELB] 
```

Finally open your browser and test your application from the dns name of your ELB :

![affiche l'ip de la machine dans le navigateur web](./imgs/Résultats-01_affiche-nom-machine-dans-navigateur-web-10.0.3.167.png)

![affiche l'ip de la machine dans le navigateur web](./imgs/Résultats-01_affiche-nom-machine-dans-navigateur-web-10.0.4.122.png)

Then write a subject on your web application, to verify that data base works :

![récupère le poste titre de test sur la machine de la zone A](./imgs/Résultats-03_récupère-poste-titre-de-test-sur-machine-10.0.2.167.png)

![récupère le poste titre de test sur la machine de la zone B](./imgs/Résultats-04_récupère-poste-titre-de-test-sur-machine-10.0.4.122.png)