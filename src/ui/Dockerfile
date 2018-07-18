FROM alpine:3.6

# __start base from from https://github.com/andrius/alpine-ruby/blob/master/Dockerfile + bson_ext and unf_ext installation

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1

# hadolint ignore=DL3018,DL3019
RUN apk update \
&& apk add ruby \
           ruby-bigdecimal \
           ruby-bundler \
           ruby-io-console \
           ruby-irb \
           ca-certificates \
           libressl \
&& apk add --virtual build-dependencies \
           build-base \
           ruby-dev \
           libressl-dev \
\
&& bundle config build.nokogiri --use-system-libraries \
&& bundle config git.allow_insecure true \
&& gem install json --no-rdoc --no-ri \
&& gem install bson_ext -v '1.12.5' --no-rdoc --no-ri \
&& gem install unf_ext -v '0.0.7.4' --no-rdoc --no-ri \
&& gem install puma -v '3.10.0' --no-rdoc --no-ri \
\
&& gem cleanup \
&& apk del build-dependencies \
&& rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
/var/tmp/*

# __end

WORKDIR /app

COPY Gemfile* config.ru helpers.rb middleware.rb ui_app.rb ./
COPY views/* ./views/
RUN bundle install

ENV POST_SERVICE_HOST=post \
    POST_SERVICE_PORT=5000 \
    COMMENT_SERVICE_HOST=comment \
    COMMENT_SERVICE_PORT=9292

CMD ["puma"]
