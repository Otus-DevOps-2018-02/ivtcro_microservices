FROM alpine:3.6

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1

WORKDIR /app
COPY * ./
COPY views/* ./views/

# __start base from from https://github.com/andrius/alpine-ruby/blob/master/Dockerfile + bson_ext and unf_ext installation

# hadolint ignore=DL3018,DL3019
RUN apk update \
&& apk add ruby \
           ruby-bigdecimal \
           ruby-bundler \
           ruby-io-console \
           ruby-irb \
           ca-certificates \
           libressl \
           ruby-dev \
&& apk add --virtual build-dependencies \
           build-base \
           ruby-dev \
           libressl-dev \
\
&& gem install bundler --no-rdoc --no-ri \
&& bundle install \
&& bundle config build.nokogiri --use-system-libraries \
&& bundle config git.allow_insecure true \
\
&& gem cleanup \
&& apk del build-dependencies \
&& rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
/var/tmp/*

# __end

ENV POST_SERVICE_HOST=post \
    POST_SERVICE_PORT=5000 \
    COMMENT_SERVICE_HOST=comment \
    COMMENT_SERVICE_PORT=9292

CMD ["puma"]
