#!/bin/bash
# En-tête propre d'un script Bash.

bucket=$1

# Vide le bucket s3 et liste les objets supprimés dans un fichier
aws s3 rm s3://$bucket/ --recursive 1>deleted_s3_objects.txt
if [ `echo $?` -eq 0 ] && [ -s deleted_s3_objects.txt ]
then cat deleted_s3_objects.txt
     echo "Les objets du bucket $bucket ont été supprimés !"
else
  aws s3 ls s3://$bucket/ 1>listed_s3_objects.txt
  if [ `echo $?` -eq 0 ] && [ -s listed_s3_objects.txt ]
  then echo "Erreur sur la supression, les objects du s3 n'ont pas été supprimés !"
  fi
fi

# Supprime le bucket s3
aws s3 rm s3://$bucket/
if [ `echo $?` -eq 0 ]
then echo "Le bucket s3 $bucket a été supprimé !"
else echo "Erreur dans la supression du bucket s3 $bucket !"
fi
