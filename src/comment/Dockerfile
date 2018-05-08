FROM ruby:2.2

# hadolint ignore=DL3008
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* config.ru helpers.rb comment_app.rb ./
RUN bundle install

ENV COMMENT_DATABASE_HOST=comment_db \
    COMMENT_DATABASE=comments

CMD ["puma"]
