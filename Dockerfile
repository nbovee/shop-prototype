FROM python:3.12-alpine as base

FROM base as builder

RUN mkdir /install
WORKDIR /install
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r ./requirements.txt

FROM base
# installing in builder stage is not working
RUN apk --update add libpq ghostscript

ARG USER=user
ARG USER_UID=1001
ARG PROJECT_NAME=shop-inventory
ARG GUNICORN_PORT=8000
ARG GUNICORN_WORKERS=2
# the value is in seconds
ARG GUNICORN_TIMEOUT=60
ARG GUNICORN_LOG_LEVEL=info
ARG DJANGO_BASE_DIR=/usr/src/$PROJECT_NAME
ARG DJANGO_STATIC_ROOT=/var/www/static
ARG DJANGO_MEDIA_ROOT=/var/www/media
ARG DJANGO_SQLITE_DIR=/sqlite
# The superuser with the data below will be created only if there are no users in the database!
ARG DJANGO_DEV_SERVER_PORT=8000

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

ENV \
	USER=$USER \
	USER_UID=$USER_UID \
	PROJECT_NAME=$PROJECT_NAME \
	GUNICORN_PORT=$GUNICORN_PORT \
	GUNICORN_WORKERS=$GUNICORN_WORKERS \
	GUNICORN_TIMEOUT=$GUNICORN_TIMEOUT \
	GUNICORN_LOG_LEVEL=$GUNICORN_LOG_LEVEL \
	DJANGO_BASE_DIR=$DJANGO_BASE_DIR \
	DJANGO_STATIC_ROOT=$DJANGO_STATIC_ROOT \
	DJANGO_MEDIA_ROOT=$DJANGO_MEDIA_ROOT \
	DJANGO_SQLITE_DIR=$DJANGO_SQLITE_DIR \
	DJANGO_SUPERUSER_USERNAME=$DJANGO_SUPERUSER_USERNAME \
	DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD \
	DJANGO_SUPERUSER_EMAIL=$DJANGO_SUPERUSER_EMAIL \
	DJANGO_DEV_SERVER_PORT=$DJANGO_DEV_SERVER_PORT


COPY --from=builder /install /usr/local
COPY docker-entrypoint.sh /
COPY docker-cmd.sh /
COPY $PROJECT_NAME $DJANGO_BASE_DIR

# User
RUN chmod +x /docker-entrypoint.sh /docker-cmd.sh && \
    apk --no-cache add su-exec libpq-dev && \
    mkdir -p $DJANGO_STATIC_ROOT $DJANGO_MEDIA_ROOT $DJANGO_SQLITE_DIR && \
    adduser -s /bin/sh -D -u $USER_UID $USER && \
    chown -R $USER:$USER $DJANGO_BASE_DIR $DJANGO_STATIC_ROOT $DJANGO_MEDIA_ROOT $DJANGO_SQLITE_DIR

EXPOSE $GUNICORN_PORT
WORKDIR $DJANGO_BASE_DIR
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/docker-cmd.sh"]
