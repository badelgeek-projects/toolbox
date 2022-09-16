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
site=$1
[ -z "${site}" ] && echo "ERREUR : Probleme parametre ${site}" && exit 2

site_cfgfile="cfg-${site}"
[ ! -f "${site_cfgfile}" ] && echo "ERREUR : Probleme Fichier configuration ${site_cfgfile} inexistant" && exit 2

#----------------------------------------------
# SOURCE FICHIER CONFIGURATION
#----------------------------------------------
. ${site_cfgfile}
site_dir="${site_basedir}/${site}"
[ ! -d "${site_dir}" ] && echo "ERREUR : Probleme Repertoire ${site_dir} inexistant" && exit 2

#----------------------------------------------
# VARIABLES
#----------------------------------------------

# WP variables
wp_user=$(echo ${site} | md5sum | head -c 5)
wp_password=$(LC_CTYPE=C tr -dc A-Za-z0-9_ < /dev/urandom | head -c 12)

# DB variables
db_name="${USER}_${wp_user}"
db_user="${USER}_${wp_user}"
db_password=$(LC_CTYPE=C tr -dc A-Za-z0-9_ < /dev/urandom | head -c 12)



#----------------------------------------------
# PROGRAM
#----------------------------------------------
echo 
echo "####### WORDPRESS ######################"
echo
echo "site = $site"
echo "site_dir = $site_dir"
echo "wp_user = $wp_user"
echo "wp_password = $wp_password"
echo
echo 
echo "####### DATABASE #######################"
echo
echo db=$db_name
echo db_user=$db_user
echo db_password=$db_password
echo

confirm "Run Installation"

#----------------------------
# CHECK DB
# - DB do not exists
# - USER do not exists
#----------------------------

# Test DB
nb_db=$(uapi Mysql list_databases | grep database | grep -c "${db_name}$")
if [ ${nb_db} -ne  0 ] ; then
   echo -e "\e[1;31m DB ${db_name} existe deja ! \e[0m"
   confirm "Delete DB : ${db_name}"
   uapi Mysql delete_database name="${db_name}" > /dev/null
fi

# Test DBUSER
nb_db=$(uapi Mysql list_users | grep user | grep -c "${db_user}$")
if [ ${nb_db} -ne  0 ] ; then
   echo -e "\e[1;31m DBUSER ${db_user} existe deja ! \e[0m"
   confirm "Delete USER : ${db_name}"
   uapi Mysql delete_user name="${db_user}" > /dev/null
fi

#----------------------------
# CREATE DB + DBUSER
#----------------------------

# Create DB
step="Create DB"
echo "$step"
uapi Mysql create_database name="${db_name}" > /dev/null
[ $? -ne  0 ]  && echo -e "\e[1;31m ERREUR ${step} ! \e[0m" && exit 2

# Create DBUSER
step="Create DBUSER"
echo "$step"
uapi Mysql create_user name="${db_user}" password="${db_password}" > /dev/null
[ $? -ne  0 ]  && echo -e "\e[1;31m ERREUR ${step} ! \e[0m" && exit 2

# Set DBUSER PRIVILEGES
step="Create DBUSER: set ALLPRIVILEGES"
echo "$step"
uapi Mysql set_privileges_on_database user="${db_user}" database="${db_name}" privileges="ALL%20PRIVILEGES" > /dev/null
[ $? -ne  0 ]  && echo -e "\e[1;31m ERREUR ${step} ! \e[0m" && exit 2

#----------------------------
# WORDPRESS INSTALL
#----------------------------
cd ${site_dir}

# Test if Site exists
ls index.php > /dev/null
if [ $? -eq  0 ] ; then
   echo -e "\e[1;31m SITE ${site} existe deja ! \e[0m"
   confirm "Delete files : ${site_dir}"
   rm -r wp-*.php wp-content > /dev/null
fi

# download the WordPress core files
step="WORDPRESS : Download"
echo "$step"
wp core download
[ $? -ne  0 ]  && echo -e "\e[1;31m ERREUR ${step} ! \e[0m" && exit 2

# create the wp-config file with our standard setup
step="WORDPRESS : Create wp-config"
echo "$step"
wp config create --dbname=$db_name --dbuser=$db_user --dbpass=$db_password --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'DISALLOW_FILE_EDIT', true );
PHP

# Install WordPress
step="WORDPRESS : Install"
echo "$step"
wp core install --url="https://${site}" --title="${site_title}" --admin_user="$wp_user" --admin_password="$wp_password" --admin_email="${site_mail}"

# discourage search engines
step="WORDPRESS : No Index"
echo "$step"
wp option update blog_public 0

# show only 6 posts on an archive page
step="WORDPRESS : Set 6 posts per archive page"
echo "$step"
wp option update posts_per_page 6

# delete sample page
step="WORDPRESS : Delete Sample page"
echo "$step"
wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids)

# create homepage
step="WORDPRESS : Create Home page"
echo "$step"
wp post create --post_type=page --post_title="Page d'Accueil" --post_status=publish --post_author=$(wp user get $wp_user --field=ID)

# set homepage as front page
step="WORDPRESS : Set Home page"
echo "$step"
wp option update show_on_front 'page'

# set homepage to be the new page
wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=page-daccueil --field=ID --format=ids)

# set pretty urls
step="WORDPRESS : Permalink structure"
echo "$step"
wp rewrite structure '/%postname%' --hard
wp rewrite flush --hard

# delete akismet and hello dolly
step="WORDPRESS : Delete unecessary plugins"
echo "$step"
wp plugin delete akismet
wp plugin delete hello

# Install PLUGINS
step="WORDPRESS : Install plugins"
echo "$step"
for plugin in ${site_plugins_web}
do
   wp plugin install ${plugin}  --activate
done

# Install THEMES
step="WORDPRESS : Install theme"
echo "$step"
for theme in ${site_themes_install}
do
   wp theme install ${theme}
done
wp theme activate ${site_theme_activate}

# create a navigation bar
wp menu create "Main Navigation"

# CREATE CATEGORY 
step="WORDPRESS : Create Categories"
echo "$step"

i=0
while [ $i -lt ${#site_categories[@]} ]
do
   wp term create category "${site_categories[$i]}"
   i=$(expr $i + 1)
done

# Add Category to Main Navigation (except "Uncategorized=1")
for category_id in $(wp term list category --order="ASC" --field=ID --format=ids)
do
   [ ${category_id} -ne 1 ] && wp menu item add-term main-navigation category ${category_id}
done

# assign navigaiton to primary location
case ${site_theme_activate} in
	polite)	menu="menu-1";;
	*) 	menu="primary";;
esac
wp menu location assign main-navigation ${menu}

exit


clear

echo "================================================================="
echo "Installation is complete. Your username/password is listed below."
echo ""
echo "Username: $wp_user"
echo "Password: $password"
echo ""
echo "================================================================="

# Open the new website with Google Chrome
/usr/bin/open -a "/Applications/Google Chrome.app" "http://localhost/$currentdirectory/wp-login.php"

# Open the project in TextMate
/Applications/TextMate.app/Contents/Resources/mate /Applications/MAMP/htdocs/$currentdirectory/wp-content/themes/lt-theme

