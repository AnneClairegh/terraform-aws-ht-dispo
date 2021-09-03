#!/bin/bash
# En-tête propre d'un script Bash.

alb_arn=$1

# Désactive la protection de suppression du load balancer
aws elbv2 modify-load-balancer-attributes --load-balancer-arn $alb_arn --attributes Key=deletion_protection.enabled,Value=false 1>load_balancer_protection.txt
if [ `echo $?` -eq 0 ]
then 
  cat load_balancer_protection.txt | grep deletion_protection -A 2 -B 1
  echo "Le load balancer $alb_arn n'a plus de protection de suppression !"
  
  # Supprime le load balancer
  aws elbv2 delete-load-balancer --load-balancer-arn $alb_arn
  if [ `echo $?` -eq 0 ] 
    then echo "Le load balancer $alb_arn a été supprimé !"
  else
    echo "Erreur lors de la supression du load balancer $alb_arn !"
  fi
else
  echo "Erreur lors de la désactivation de la protection de suppression du load balancer $alb_arn !"
fi
