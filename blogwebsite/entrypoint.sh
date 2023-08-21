#!/bin/sh

if [  "DB_ENGINE" = "django.db.backends.postgresql" ]
then
    echo "Waiting for Postgres..."

    while ! nc -z $DB_HOST $DB_PORT; do
        sleep 0.1
    done

    echo "Postgres started!"
fi

python manage.py flush --no-input
python manage.py migrate

exec "$@"

