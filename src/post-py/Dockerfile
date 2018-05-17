FROM python:3.6.0-alpine

WORKDIR /app

COPY helpers.py \
     post_app.py \
     requirements.txt \
     ./

RUN pip install -r requirements.txt

ENV POST_DATABASE_HOST=post_db \
    POST_DATABASE=posts

ENTRYPOINT ["python3", "post_app.py"]
