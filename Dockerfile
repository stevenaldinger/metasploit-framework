FROM ruby:2.4.1-alpine

ARG BUNDLER_ARGS="--jobs=8 --without development test coverage"

ENV \
 APP_HOME='/usr/src/metasploit-framework/' \
 MSF_USER='msf' \
 NMAP_PRIVILEGED=''

WORKDIR $APP_HOME

COPY Gemfile* m* Rakefile "$APP_HOME"

COPY lib "$APP_HOME/lib"

RUN apk upgrade --update && apk add --update --no-cache \
            sqlite-libs \
            nmap \
            nmap-scripts \
            nmap-nselibs \
            postgresql-libs \
            ncurses \
            libcap \
 && apk add --update --no-cache --virtual .ruby-builddeps \
            autoconf \
            bison \
            build-base \
            ruby-dev \
            openssl-dev \
            readline-dev \
            sqlite-dev \
            postgresql-dev \
            libpcap-dev \
            libxml2-dev \
            libxslt-dev \
            yaml-dev \
            zlib-dev \
            ncurses-dev \
            git \
 && echo "gem: --no-ri --no-rdoc" > /etc/gemrc \
 && bundle install --system $BUNDLER_ARGS \
 && apk del .ruby-builddeps \
 && rm -rf /var/cache/apk/* \
 # fix for robots gem not readable (known bug)
 # https://github.com/rapid7/metasploit-framework/issues/6068
 && chmod o+r /usr/local/bundle/gems/robots-*/lib/robots.rb \
 # add msf user
 && adduser -g msfconsole -D "$MSF_USER" \
 && /usr/sbin/setcap cap_net_raw,cap_net_bind_service=+eip $(which ruby) \
 && /usr/sbin/setcap cap_net_raw,cap_net_bind_service=+eip /usr/bin/nmap

USER $MSF_USER

ADD ./ "$APP_HOME"

CMD ["./msfconsole", "-r", "docker/msfconsole.rc"]
