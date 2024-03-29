#!/bin/bash

clear
#----------------------------------------------
# FUNCTIONS
#----------------------------------------------
confirm () {
message="$*"
while true; do
    read -n 1 -p "$message ? (Y/n) => " yn
    echo
    case $yn in
        [Y]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y or n.";;
    esac
done
}

#----------------------------------------------
# PARAMETRES
#----------------------------------------------
_all=$1
[ -z "${_all}" ] && echo "ERREUR : Probleme parametre ${_all}" && exit 2

_db=${_all}
_dbuser=${_all}
_dbpassword=${_all}

#----------------------------------------------
# PROGRAM
#----------------------------------------------
echo 
echo "####### DATABASE #######################"
echo
echo db=$_db
echo db_user=$_dbuser
echo db_password=$_dbpassword
echo
echo psql -U $_dbuser -d $_db -f file.sql

confirm "Run Installation"


#----------------------------
# CREATE DB + DBUSER
#----------------------------
# Create User + DB
psql -U postgres <<EOF
        CREATE USER ${_dbuser} WITH LOGIN ENCRYPTED PASSWORD '${_dbpassword}';
        CREATE DATABASE ${_db} OWNER ${_dbuser};
EOF
