# le nom DNS de mon ELB,
# afin de pouvoir tester son bon fonctionnement directement depuis mon navigateur
output "alb_dns_name" {
  value = aws_lb.my-alb.dns_name
}

# l'id du groupe de sécurité de nos instances web
# afin de le rajouter en tant que cible dans la règle ingress du groupe de sécurité de notre base de données
output "webserver_sg_id" {
  value = [aws_security_group.asg-instances-sg.id]
}

# le nom de mon ASG 
# qui sera utilisé plus tard dans nos alarmes CloudWatch
output "asg_name" {
  value = aws_autoscaling_group.my_autoscaling.name
}

