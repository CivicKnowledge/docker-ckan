
##
## Postgres
## 

service postgresql start
pg_pid=$!


##
## Solr
###

service tomcat6 start
solr_pid=$!

##
## CKAN 
##

config=/etc/ckan/default/production.ini

## Expects to be called with these envvars set
##  ADMIN_USER_PASS
##  ADMIN_USER_EMAIL
##  ADMIN_USER_KEY
##  SITE_URL

if [ ! -f '/var/run/initialized' ]; then
  app_id=$(cat /proc/sys/kernel/random/uuid) 
  sed -i "s/app_instance_uuid.*/app_instance_uuid = $app_id/"  $config
  sed -i "s/ckan.site_url.*/ckan.site_url = http:\/\/$SITE_URL/"  $config

  session_secret=$(cat /proc/sys/kernel/random/uuid) 
  sed -i "s/beaker.session.secret.*/beaker.session.secret = $session_secret/"  $config
 
  paster user add admin apikey=$ADMIN_USER_KEY password=$ADMIN_USER_PASS email=$ADMIN_USER_EMAIL -c $config 
  paster sysadmin add admin -c $config 
  touch  /var/run/initialized
  
  cp $config /etc/ckan/default/development.ini
  sed -i "s/debug.*/debug = true/"  /etc/ckan/default/development.ini
  
  # THis is supposed to be done in the Dockerfile, but it doesn't work. 
  # the 'less' command fails without running it again. 
  npm install less nodewatch
  
fi


if [ -z "$DEBUG" ]; then
  gunicorn_paster --debug -b :80 --worker-class gevent -w 5 $config &
  ckan_pid=$!
else

  ./bin/less &
  paster serve --reload /etc/ckan/default/development.ini
fi


wait $ckan_pid
wait $solr_pid
wait $pg_pid