#!/bin/bash
# En-tête propre d'un script Bash.

db_identifier=$1

# Arrêt de la BDD
aws rds stop-db-instance --db-instance-identifier $db_identifier 1>DBInstanceStatus_stoped.txt
if [ `echo $?` -eq 0 ] && [ -s DBInstanceStatus_stoped.txt ]
then
  cat DBInstanceStatus_stoped.txt | grep DBInstanceStatus -B 1
  echo "La BDD $db_identifier été arrêtée !"

  # Supprime la BDD en évitant le final snapshot 
  aws rds delete-db-instance --skip-final-snapshot --db-instance-identifier $db_identifier 1>DBInstanceStatus_deleted.txt
  if [ `echo $?` -eq 0 ] && [ -s DBInstanceStatus_stoped.txt ]
  then
    cat DBInstanceStatus_deleted.txt | grep DBInstanceStatus -B 1
    echo "La BDD $db_identifier a été supprimée !"
  else 
    echo "Erreur lors de la suppression de la BDD $db_identifier !"
  fi
else
  echo "Erreur lors de l'arrêt de la BDD $db_identifier !"
fi
