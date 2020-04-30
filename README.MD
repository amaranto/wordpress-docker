# Wordpress Docker
Configure a wordpress environment automatically with SSL.
SSL certificates are created using lets encrypt and certbot, if certbot fails then selfsigned certificates will be use instead.

## Requirements
- git
- openssl
- curl
- [Install docker](https://docs.docker.com/engine/install/ubuntu/)
- [Install docker-compose](https://docs.docker.com/compose/install/)

## Containers documentations
- [Nginx](https://hub.docker.com/_/nginx)
- [Certbot](https://hub.docker.com/r/certbot/certbot)
- [Wordpress](https://hub.docker.com/_/wordpress)
- [MariaDB](https://hub.docker.com/_/mariadb)

## Setting up wordpress
**Note:** If docker is configured to run only with root user then you have to issue `sudo -s`.

The following environment variables are required. You can edit setup script or issue these commands

`export DOMAIN_NAME="Replace with your domain here. Example: wp.example.org"`

`export EMAIL_ADMIN="Your email here"`

`export MARIADB_PWD="Your new MariaDB password to connect wordpress"`

Now run setup script

`./setup.sh`

