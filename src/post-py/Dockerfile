FROM python:3.6.0-alpine

RUN apk add --no-cache gcc musl-dev

WORKDIR /app

COPY * ./

RUN pip install -r requirements.txt

ENV POST_DATABASE_HOST=post_db \
    POST_DATABASE=posts

ENTRYPOINT ["python3", "post_app.py"]
