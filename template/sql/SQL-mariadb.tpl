#!/bin/sh

helm_ns={{ .global.namespace }}
POD=(`kubectl get pod -n ${helm_ns} | grep mariadb-galera-0`)

echo "[INFO] Start mariadb-galera SQL"

kubectl -n ${helm_ns} exec ${POD} -- mysql -uroot -pcrossent12 -se "CREATE DATABASE IF NOT EXISTS gitea;
CREATE DATABASE IF NOT EXISTS gitea_session;
CREATE USER IF NOT EXISTS 'gitea'@'%' IDENTIFIED BY 'gitea';
GRANT ALL ON gitea.* TO 'gitea'@'%' IDENTIFIED BY 'gitea' WITH GRANT OPTION;
GRANT ALL ON gitea_session.* TO 'gitea'@'%' IDENTIFIED BY 'gitea' WITH GRANT OPTION;
GRANT ALL ON gitea.* TO 'gitea'@'localhost' IDENTIFIED BY 'gitea' WITH GRANT OPTION;
GRANT ALL ON gitea_session.* TO 'gitea'@'localhost' IDENTIFIED BY 'gitea' WITH GRANT OPTION;
FLUSH PRIVILEGES;

USE gitea_session;
CREATE TABLE IF NOT EXISTS \`session\` (
 \`key\` CHAR(16) NOT NULL,
 \`data\` BLOB,
 \`expiry\` INT(11) UNSIGNED NOT NULL,
 PRIMARY KEY (\`key\`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE DATABASE IF NOT EXISTS keycloak default CHARACTER SET UTF8;
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY 'keycloak';
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';"
