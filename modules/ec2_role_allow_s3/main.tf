# Création d'un rôle, attaché aux services EC2
# avec une policy, qui autorise un accès complet aux services S3
resource "aws_iam_role" "s3-mybucket-role" {
    name = "${var.prefix_name}s3-bucket-role"
# Cette stratégie de confiance permet au service Amazon EC2 d'assumer le rôle.
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

    tags = {
        Name = "${var.prefix_name}s3-bucket-role"
    }
}

# Cette stratégie définit un accès complet aux services S3
resource "aws_iam_role_policy" "s3-mybucket-role-policy" {
    name        = "${var.prefix_name}s3-bucket-${var.bucket_name}-role-policy"
    role        = aws_iam_role.s3-mybucket-role.id
    # description = "whole access to s3 service"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
              "arn:aws:s3:::${var.bucket_name}",
              "arn:aws:s3:::${var.bucket_name}/*"
            ]
        }
    ]
}
EOF
}

# Création d'un profil d'instance
# pour transmettre les informations (liées au rôle créé précédemment), 
# à vos instances EC2, lorsque celles-ci démarrent
resource "aws_iam_instance_profile" "s3-mybucket-role-instanceprofile" {
    name = "${var.prefix_name}-s3-${var.bucket_name}-role-instanceprofile"
    role = aws_iam_role.s3-mybucket-role.name # Optional) Name of the role to add to the profile.

    tags = {
        Name = "${var.prefix_name}-ec2-inst-profile"
    }
}
