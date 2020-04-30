#!/bin/bash -e

DOMAIN_NAME="${DOMAIN_NAME:-}"
EMAIL_ADMIN="${EMAIL_ADMIN:-}"
CERTBOT_CONF_PATH="${CERTBOT_CONF_PATH:-./certbot/conf}"
CERTBOT_WWW_PATH="${CERTBOT_WWW_PATH:-./certbot/www}"

echo "Checking requirments ... "
docker-compose --version > /dev/null
docker --version > /dev/null
openssl version > /dev/null
curl --version  > /dev/null
echo "[ Ok ]"

[ -z ${DOMAIN_NAME} ] && echo "[ Error ] DOMAIN_NAME environment variable is not defined." && exit 1
[ -z ${EMAIL_ADMIN} ] && echo "[ Error ] EMAIL_ADMIN environment variable is not defined." && exit 2

[ -d ${CERTBOT_CONF_PATH} ] || mkdir -p ${CERTBOT_CONF_PATH}
[ -d ${CERTBOT_WWW_PATH} ]  || mkdir -p ${CERTBOT_WWW_PATH}

if [ ! -f "${CERTBOT_CONF_PATH}/options-ssl-nginx.conf" ] || [ ! -f "${CERTBOT_CONF_PATH}/ssl-dhparams.pem" ]; then
  echo "[ Info ] Downloading TLS config "
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "${CERTBOT_CONF_PATH}/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "${CERTBOT_CONF_PATH}/ssl-dhparams.pem"
fi

if [ ! -f ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/fullchain.pem ] || [ ! -f ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/privkey.pem ]
then
    echo "[ Info ] Creating dummy certificates for first run"
    mkdir -p ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}
    openssl req -x509 -nodes -newkey rsa:1024 -days 1 -keyout ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/privkey.pem -out ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/fullchain.pem 
fi 

echo "Configuring virtual hosts"
sed -i "s/{_APP_DOMAIN_}/${DOMAIN_NAME}/g" nginx/app.conf 

echo "Starting nginx"
docker-compose up --force-recreate -d nginx

echo "Bucking up self signed certificates"
mv ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME} ${CERTBOT_CONF_PATH}/live/selfsigned

echo "Cleaning cert bot certificates"
rm -rf ${CERTBOT_CONF_PATH}/archive/${DOMAIN_NAME}/* 
rm -rf ${CERTBOT_CONF_PATH}/renewal/${DOMAIN_NAME}/*

echo "Requesting Certificates"
docker-compose run --rm --entrypoint "certbot certonly --webroot \
    -w /var/www/certbot \
    --email ${EMAIL_ADMIN} \
    -d ${DOMAIN_NAME} \
    --agree-tos \
    --force-renewal" \
    certbot

if [ ! -f ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/privkey.pem ] || [ ! -f ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}/fullchain.pem ]
then
  echo ""
  echo "[ Error ]Certbot certificate request failed"
  echo "Using selfsigned certificates"
  rm -rf ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}
  ln -s ${CERTBOT_CONF_PATH}/live/selfsigned ${CERTBOT_CONF_PATH}/live/${DOMAIN_NAME}
fi 

echo "Reloading nginx"
docker-compose exec nginx nginx -s reload

echo "Start Wordpress and MariaDb"
docker-compose up --force-recreate -d wordpress