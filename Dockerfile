ARG ALPINE_VERSION=3.16

FROM alpine:$ALPINE_VERSION as builder

ARG MYSQL_VERSION=8.0.33

RUN cd /tmp \
  && apk --no-cache add build-base cmake eudev-dev gcompat ncurses-dev openssl-dev linux-headers patch \
  && wget https://dev.mysql.com/get/Downloads/mysql-$MYSQL_VERSION.tar.gz -O - | tar zvxf -

RUN cd /tmp && tar zxf mysql-$MYSQL_VERSION.tar.gz
COPY patches /tmp/patches

RUN cd /tmp/mysql-$MYSQL_VERSION \
  && find /tmp/patches -type f | xargs -I{} patch -p1 -i {}

RUN cd /tmp && mkdir -p mysql-$MYSQL_VERSION/build && cd mysql-$MYSQL_VERSION/build \
    && ls -al .. \
    && cmake .. -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/tmp -DWITHOUT_SERVER=1 -DWITH_BUILD_ID=0 \
    && make && make install

FROM ruby:3.0.6-alpine$ALPINE_VERSION AS publish
RUN apk --no-cache add ncurses-libs libgcc libstdc++ build-base openssl-dev ncurses-dev
COPY --from=builder /usr/local/mysql/include /usr/local/mysql/include
COPY --from=builder /usr/local/mysql/lib /usr/local/mysql/lib
RUN gem install mysql2 -- --with-mysql-dir=/usr/local/mysql
