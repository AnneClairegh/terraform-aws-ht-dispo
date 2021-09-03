# J'exporte mon profile d'instance
output "profil" {
    value = aws_iam_instance_profile.s3-mybucket-role-instanceprofile.name
}

# J'exporte le rôle attaché aux services EC2, 
#  avec un accès complet aux services S3
output "role" {
    value = aws_iam_role.s3-mybucket-role.name
}
