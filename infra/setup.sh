# 기존 컨테이너 삭제
docker rm -f mysql-1 mysql-2 mysql-3 2>/dev/null
rm -rf dockerProjects/mysql-1 dockerProjects/mysql-2 dockerProjects/mysql-3

# common 네트워크 생성
docker network create common 2>/dev/null

# mysql-1(소스서버) 설정파일 생성
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

# mysql-2(리플리카1 서버) 설정파일 생성
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

# mysql-3(리플리카2 서버) 설정파일 생성
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

# mysql-1 서버 실행
docker run -d --name mysql-1 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-1/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-1/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

# 원활한 설정을 위해서 잠시 대기
sleep 20

# mysql-1 서버 초기화
## 리플리케이션 동기화용 계정 repl 생성 및 권한 부여
## 사용계정 lldj 생성 및 권한 부여
## 데이터베이스 surl 생성
docker exec mysql-1 mysql -uroot -plldj123414 -e "
CREATE USER 'repl'@'%' IDENTIFIED WITH caching_sha2_password BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

CREATE USER 'lldj'@'%' IDENTIFIED WITH caching_sha2_password BY 'lldj123414';
GRANT ALL PRIVILEGES ON *.* TO 'lldj'@'%';

CREATE DATABASE surl;

FLUSH PRIVILEGES;
"

# mysql-2 서버 실행
docker run -d --name mysql-2 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-2/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-2/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

# 원활한 설정을 위해서 잠시 대기
sleep 20

# mysql-2 서버 초기화, 리플리케이션(동기화) 시작
docker exec mysql-2 mysql -uroot -plldj123414 -e "
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-1',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='replpass',
  SOURCE_AUTO_POSITION=1,
  SOURCE_SSL=1;
START REPLICA;
"

# mysql-2 리플리케이션 상태 확인
docker exec mysql-2 mysql -uroot -plldj123414 -e "
SHOW REPLICA STATUS\G;
"

# mysql-3 서버 실행
docker run -d --name mysql-3 --network common \
  --restart unless-stopped \
  -v /${PWD}/dockerProjects/mysql-3/volumes/var/lib/mysql:/var/lib/mysql \
  -v /${PWD}/dockerProjects/mysql-3/volumes/etc/mysql/conf.d:/etc/mysql/conf.d \
  -p 3308:3306 \
  -e MYSQL_ROOT_PASSWORD=lldj123414 \
  -e TZ=Asia/Seoul \
  mysql:latest

# 원활한 설정을 위해서 잠시 대기
sleep 20

# mysql-3 서버 초기화, 리플리케이션(동기화) 시작
docker exec mysql-3 mysql -uroot -plldj123414 -e "
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-1',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='replpass',
  SOURCE_AUTO_POSITION=1,
  SOURCE_SSL=1;
START REPLICA;
"

# mysql-3 리플리케이션 상태 확인
docker exec mysql-3 mysql -uroot -plldj123414 -e "
SHOW REPLICA STATUS\G;
"