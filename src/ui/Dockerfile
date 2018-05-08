FROM ruby:2.2

# hadolint ignore=DL3008
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* config.ru helpers.rb middleware.rb ui_app.rb ./
COPY views/* ./views/
RUN bundle install

ENV POST_SERVICE_HOST=post \
    POST_SERVICE_PORT=5000 \
    COMMENT_SERVICE_HOST=comment \
    COMMENT_SERVICE_PORT=9292

CMD ["puma"]
