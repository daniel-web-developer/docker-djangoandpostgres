# using the official python image with Alpine Linux
FROM python:3.10.12-alpine

# to set the work directory
WORKDIR /usr/src/app

# python environment variables. Read more in https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUNBUFFERED and https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUNBUFFERED
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# updating and system dependencies
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

# update pip, copy requirements.txt into the work directory, then install dependencies defined in requirements.txt
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy everything inside this specific directory, and not all others, to the work directory. 
COPY . .

