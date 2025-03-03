docker rm -f mysql-1 mysql-2 mysql-3 2>/dev/null
rm -rf dockerProjects/mysql-1 dockerProjects/mysql-2 dockerProjects/mysql-3

docker network create common 2>/dev/null

mkdir -p dockerProjects/mysql-1/volumes/etc/mysql/conf.d
chmod 644 dockerProjects/mysql-1/volumes/etc/mysql/conf.d/my.cnf 2>/dev/null
cat <<EOF > dockerProjects/mysql-1/volumes/etc/mysql/conf.d/my.cnf
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW
enforce-gtid-consistency=ON
gtid-mode=ON
log-slave-updates=ON
EOF
chmod 444 dockerProjects/mysql-1/volumes/etc/mysql/conf.d/my.cnf

mkdir -p dockerProjects/mysql-2/volumes/etc/mysql/conf.d
chmod 644 dockerProjects/mysql-2/volumes/etc/mysql/conf.d/my.cnf 2>/dev/null
cat <<EOF > dockerProjects/mysql-2/volumes/etc/mysql/conf.d/my.cnf
[mysqld]
server-id=2
log-bin=mysql-bin
binlog-format=ROW
enforce-gtid-consistency=ON
gtid-mode=ON
log-slave-updates=ON

relay_log_recovery=ON
EOF
chmod 444 dockerProjects/mysql-2/volumes/etc/mysql/conf.d/my.cnf

mkdir -p dockerProjects/mysql-3/volumes/etc/mysql/conf.d
chmod 644 dockerProjects/mysql-3/volumes/etc/mysql/conf.d/my.cnf 2>/dev/null
cat <<EOF > dockerProjects/mysql-3/volumes/etc/mysql/conf.d/my.cnf
[mysqld]
server-id=3
log-bin=mysql-bin
binlog-format=ROW
enforce-gtid-consistency=ON
gtid-mode=ON
log-slave-updates=ON

relay_log_recovery=ON
EOF
chmod 444 dockerProjects/mysql-3/volumes/etc/mysql/conf.d/my.cnf

docker run -d --name mysql-1 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-1/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-1/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

sleep 20

docker exec mysql-1 mysql -uroot -plldj123414 -e "
CREATE USER 'repl'@'%' IDENTIFIED WITH caching_sha2_password BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

CREATE USER 'lldj'@'%' IDENTIFIED WITH caching_sha2_password BY 'lldj123414';
GRANT ALL PRIVILEGES ON *.* TO 'lldj'@'%';

CREATE DATABASE surl;

FLUSH PRIVILEGES;
"

docker run -d --name mysql-2 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-2/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-2/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

sleep 20

docker exec mysql-2 mysql -uroot -plldj123414 -e "
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-1',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='replpass',
  SOURCE_AUTO_POSITION=1,
  SOURCE_SSL=1;
START REPLICA;
"

docker exec mysql-2 mysql -uroot -plldj123414 -e "
SHOW REPLICA STATUS\G;
"

docker run -d --name mysql-3 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-3/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-3/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3308:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

sleep 20

docker exec mysql-3 mysql -uroot -plldj123414 -e "
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-1',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='replpass',
  SOURCE_AUTO_POSITION=1,
  SOURCE_SSL=1;
START REPLICA;
"

docker exec mysql-3 mysql -uroot -plldj123414 -e "
SHOW REPLICA STATUS\G;
"