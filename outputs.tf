# nom DSN public de notre ELB
output "alb_dns_name" {
  value = module.my_alb_asg.alb_dns_name
}
