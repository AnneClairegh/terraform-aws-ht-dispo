# adresse DNS (nom DNS de la BDD)
output "host" {
  value = aws_db_instance.mariadb.address
}

# nom d'utilisateur de ma BDD
output "username" {
  value = aws_db_instance.mariadb.username
}

