#!/bin/bash
# Ubuntu 16.04 MariaDB Password fix.
# @HimaJyun( http://jyn.jp/ )

# sudo Check.
if [ "$(whoami)" != "root" ];then
  echo "This script requires superuser."
  echo "Excecute->sudo $0"
  echo 'Was interrupted.'
  exit 1
fi
# LANG Set.
LANG=C

echo 'When perform all account will be deleted.'
printf 'OK?[y/N]:'
read CONFIRM
echo ""

case ${CONFIRM,,} in
  'yes' | 'y')
    ;;
  *)
    echo 'Was interrupted.'
	exit 1
esac

printf 'Enter new password:'
read -s MARIA_PASSWORD
echo ""
if [ -z ${MARIA_PASSWORD} ];then
  echo ""
  echo 'Password is enpty.'
  echo 'Was interrupted.'
  exit 1
fi

printf 'Re enter new password:'
read -s CONFIRM
echo ""
echo ""

if [ "${MARIA_PASSWORD}" != "${CONFIRM}" ];then
  echo 'Password do not match.'
  echo 'Was interrupted.'
  exit 1
fi

service mysql stop
mysqld_safe --skip-grant-tables --skip-networking &
sleep 5

tmp=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 16)

mysql -u root << __EOL__
use mysql;
truncate table user;
flush privileges;
grant all privileges on *.* to 'root'@'localhost' identified by '${MARIA_PASSWORD}' with grant option;
grant all privileges on *.* to 'root'@'127.0.0.1' identified by '${MARIA_PASSWORD}' with grant option;
grant all privileges on *.* to 'root'@'::1' identified by '${MARIA_PASSWORD}' with grant option;
grant all privileges on *.* to 'root'@'$(hostname)' identified by '${MARIA_PASSWORD}' with grant option;
grant all privileges on *.* to 'debian-sys-maint'@'localhost' identified by '${tmp}' with grant option;
update user set Create_tablespace_priv="N" WHERE User='debian-sys-maint' ;
flush privileges;
__EOL__

sed -i -e '/^user/c user     = debian-sys-maint' /etc/mysql/debian.cnf
sed -i -e "/^password/c password = ${tmp}" /etc/mysql/debian.cnf

kill -SIGTERM $!
sleep 5
service mysql start

echo 'done.'
