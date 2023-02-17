FROM php:7.2-apache
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
run apt update
run yes | apt install wget unzip
workdir /var/www/html/
run wget https://github.com/VictorAlagwu/CMSsite/archive/master.zip && unzip master.zip && rm -rf master.zip
run cp -rf CMSsite-master/* .
run rm -rf CMSsite-master
run chmod -R 777 img
RUN sed -i "s/ = '';/ = 'test';/" includes/db.php
RUN sed -i "s/localhost/mysql/" includes/db.php
RUN find . -type f -iname "*.php" | xargs -I{} sed -i -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba' -e 's|// \@.*;||' -e '/^\s*$/d' {}
RUN sed -i "1d" includes/navbar.php
expose 80

