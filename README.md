# django-blog

## How to set up Django and Postgres with Docker

### Part 1: Creating the Django project.
1. Create a new directory with `mkdir example`;
2. Access such directory with `cd example`;
3. Create a virtual environment. I'm using [venv](https://docs.python.org/3/library/venv.html) (the command is `python3 -m venv EXAMPLEENV`) in this app, now access it with `source example/bin/activate`. To leave the virtual environment, just type `deactivate EXAMPLEENV`;
4. Install Django with `pip install django` and see which version it's installing. In my case, the version installed is Django 4.2.4. You'll need to know it to create a `requirements.txt` file for Docker;
5. Create a Django project with `django-admin startproject exampleapp`. Access the `exampleapp` folder with `cd example app`, perform a database migration `django manage.py migrate` and start the local server `python manage.py runserver`. You can now use your browser and go to http://localhost:8000 and should see something like Image 1. **Warning: a different page may appear** (they might change according to the installed Django version), but that doesn't mean something went wrong. Check the [Django official documentation](https://docs.djangoproject.com/) if something doesn't feel right.

![image](https://github.com/daniel-web-developer/django-blog/assets/107224353/3d510c45-11b9-4c0d-ae44-9f9121dfb81d "Image 1. Django install working successfully")

Your project directory's tree should look like this:

```
example (this is the root folder of your project)
├── exampleapp
│   ├── exampleapp
│   │   ├── asgi.py
│   │   ├── __init__.py
│   │   ├── __pycache__
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── db.sqlite3
│   └── manage.py
└── EXAMPLEENV
```

### Part 2: Configuring Docker.
1. Create the requirements.txt file in `root/exampleapp/`. There's more than one way to do it, but from the root folder of your project (`example`), you can enter `cd exampleapp` and then `touch requirements.txt`. In this file, we'll type the names and versions of the **dependencies** (packages your project can't work without, e.g. Django) so Docker will automatically download and add them to the project.
2. Add `Django==VERSION` to `requirements.txt`. ``VERSION`` should be the Django version intended to be used in this project. In my case, I'm adding `Django==4.2.4`.
3. #### Creating the first Dockerfile:

   1. In `root/exampleapp`, create a Dockerfile with `touch Dockerfile`.
   2. Add this to the newly created file:
    ```
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

    ```
4. #### Creating the Docker Compose file:

   1. Go to the root directory of your project (`/example/`), create a `docker-compose.yml` file with `touch docker-compose.yml`;
   2. Add this to the newly created file:
   ```
   services:
     web:
       build: ./exampleapp # this needs to be django's main folder
       command: python manage.py runserver 0.0.0.0:8000
       volumes:
         - ./exampleapp/:/usr/src/app # django's main folder:WORKDIR defined in /example/exampleapp/Dockerfile
       ports:
         - 8000:8000
       env_file:
         - ./.env.dev
   ```
5. Update Django settings:
   1. Open `settings.py` (located inside `/example/exampleapp/exampleapp/settings.py`);
   2. Add `import os` at the top of the file.
   3. Edit the following variables: `DEBUG`, `ALLOWED_HOSTS`, and `SECRET_KEY`. To simplify and make things more secure, we'll add variables that depend on `.env` files (defined on the `example/docker-compose.yml`). Edit each accordingly to my example:
      - `DEBUG = os.getenv('DEBUG_STATUS', False)`
      - `ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '127.0.0.1').split(',')`
      - `SECRET_KEY = os.getenv('SECRET_KEY')`
      Docker will look for the value of each of the above inside `.env` files, according to the Compose configuration.
6. Create a `.env.dev` file in the project's root folder. I'm using `touch .env.dev`.
7. Add this to `.env.dev` (if you're in the right directory but can't see this file, check how to see hidden files in your Operating System):
```
SECRET_KEY=secret
DEBUG_STATUS=True
ALLOWED_HOSTS=localhost
```
8. You can now, in the project's root folder, type `docker compose build` to build the project's image (you might need to write `sudo` alongside with all the Docker related commands. In this case, it would be `sudo docker compose build`) and then `docker compose up -d` to run the container. After everything loaded, you can head to http://localhost:8000 to check if the container is working. If not, you may check for errors by typing `docker compose logs -f`. **In order to stop the container(s), you can type `docker compose down -v`. The `-v` flag takes down any volumes that might be running (none so far, but we'll be adding some in the future)**.

If you've followed every step so far, your project directory should look like this:
```
example (project's root folder)
├── exampleapp
│   ├── exampleapp
│   ├── db.sqlite3
│   ├── Dockerfile
│   ├── manage.py
│   └── requirements.txt
├── docker-compose.yml
├── env
│   ├── bin
│   ├── include
│   ├── lib
│   ├── lib64 -> lib
│   └── pyvenv.cfg
├── LICENSE
└── README.md
```

### Part 3: Adding Postgres to the app
1. We'll now a service for the database by editing `example/docker-compose.yml`. This is how the file should look like now:
```
services:
  web:
    build: ./blogwebsite
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./blogwebsite/:/usr/src/app
    ports:
      - 8000:8000
    env_file:
      - ./.env.dev
    depends_on:
      - db
  db:
    image: postgres:15.4-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - ./.env.dev

volumes:
  postgres_data:

```
**IMPORTANT: Note how the service `web` now depends on the new service `db`. Don't forget to add these lines.**
2. Add new variables to the `example/.env.dev` file in order to configure the database. These will also be used by the `settings.py` file. Since this is only the **development environment**, you don't need focus on making the values extra safe. **For the production environment, however, it's recommended you use secure values** for your `.env` file. Since we're using Postgres, the value for the `DB_ENGINE` must not be changed (check [Django's documentation](https://docs.djangoproject.com/en/dev/ref/databases/#postgresql-connection-settings) on how to configure the database). These are the new lines:
```
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
POSTGRES_DB=django_dev_db
DB_ENGINE=django.db.backends.postgresql
POSTGRES_HOST=db
POSTGRES_PORT=5432
```
3. On the root folder, enter the virtual environment (if you're not using it right now) and install the psycopg2-binary package by entering `pip install psycopg2-binary`. Pay attention to which version you installed (just like you did with Django) or type `pip list` to see the version installed.
4. Open your `requirements.txt` file (it's in the same folder as `manage.py`, and you can find it by typing, from the project's root folder, `cd exampleapp/`) and add the line `psycopg2-binary==VERSION` to it. This is how my file currently looks like:
```
Django==4.2.4
psycopg2-binary==2.9.7
```
5. Go to the `settings.py` file (`example/exampleapp/exampleapp/settings.py`) and change the `DATABASES` dictionary. Afterwards, it should look like this:
```
DATABASES = {
    'default': {
        'ENGINE': os.environ.get("DB_ENGINE"),
        'NAME': os.environ.get("POSTGRES_DB"),
        'USER': os.environ.get("POSTGRES_USER"),
        'PASSWORD': os.environ.get("POSTGRES_PASSWORD"),
        'HOST': os.environ.get("POSTGRES_HOST"),
        'PORT': os.environ.get("POSTGRES_PORT"),
    }
}
```
6. Testing:
   1. Bring down your containers and volume (if they're running) with `docker compose down -v`, build (again) the image and start the containers with `docker compose up -d --build`;
   2. Run the migrations with `docker compose exec web python manage.py migrate --noinput`. If you get the error `django.db.utils.OperationalError: FATAL:  database "django_dev_db" does not exist`, bring down the containers and volume with `docker compose down -v`, and rebuild everything by typing `docker compose up -d --build`.
   3. Make sure the tables were created by typing `sudo docker compose exec db psql --username=user --dbname=django_dev_db` and then `\l`. Something like this should show up.
```
   django_dev_db=# \l
                                               List of databases
     Name      | Owner | Encoding |  Collate   |   Ctype    | ICU Locale | Locale Provider | Access privileges
---------------+-------+----------+------------+------------+------------+-----------------+-------------------
 django_dev_db | user  | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            |
 postgres      | user  | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            |
 template0     | user  | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/user          +
               |       |          |            |            |            |                 | user=CTc/user
 template1     | user  | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/user          +
               |       |          |            |            |            |                 | user=CTc/user
(4 rows)
 ```
   4. Type `\c` to check with which user you're logged in. It should return something like:
```
django_dev_db=# \c
You are now connected to database "django_dev_db" as user "user".
```
   5. To check the list of relations (or who owns what), type `\dt`. Result:
```
django_dev_db=# \dt
                  List of relations
 Schema |            Name            | Type  | Owner 
--------+----------------------------+-------+-------
 public | auth_group                 | table | user
 public | auth_group_permissions     | table | user
 public | auth_permission            | table | user
 public | auth_user                  | table | user
 public | auth_user_groups           | table | user
 public | auth_user_user_permissions | table | user
 public | django_admin_log           | table | user
 public | django_content_type        | table | user
 public | django_migrations          | table | user
 public | django_session             | table | user
(10 rows)
```
   6. To quit the Postgres CLI, type `\q`.
   7. Last but not least, type `docker volume inspect example_postgres_data` to make sure the Docker volume was created. My results:
```
[
    {
        "CreatedAt": "DATE",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "blog",
            "com.docker.compose.version": "2.17.3",
            "com.docker.compose.volume": "postgres_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/blog_postgres_data/_data",
        "Name": "blog_postgres_data",
        "Options": null,
        "Scope": "local"
    }
]
```
7. Create a `entrypoint.sh` inside `example/exampleapp/`, the directory with `manage.py`. Add the following code inside it:
```
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

```
Afterwards, make it an executable by typing `chmod +x entrypoint.sh` (you need to be in the same directory as the file).
8. Let's edit the `Dockerfile` (located in the same directory as `entrypoint.sh` and `manage.py`). We need to add lines so we can copy and work with `entrypoint.sh`, and then add one line to actually run the file. This is how the file will look like after the additions:
```
# using the official python image with Alpine Linux
FROM python:3.10.12-alpine

# to set the work directory
WORKDIR /usr/src/app

# python environment variables. Read more in https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUNBUFFERED and https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUNBUFFERED
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# updating and installing system dependencies
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

# update pip, copy requirements.txt into the work directory, then install dependencies defined in requirements.txt
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy entrypoint.sh to the work directory, run a stream editor, then allow the file to be executed
COPY ./entrypoint.sh .
RUN sed -i 's/\r$//g' /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# copy everything inside this specific directory, and not all others, to the work directory.
COPY . .

# run as soon as the container is started
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
```
By the way, you'll need `netcat` to run `entrypoint.sh`. Alpine already comes with it so that's why I'm not downloading it, but make sure your container's OS has it as well.

9. Bring everything down with `sudo docker compose down -v`, and then rebuild and run the containers with `sudo docker compose up -d --build`.

##You should now see the default Django page if you visit http://localhost:8000! Congratulations!

I recommend everyone to only set up the production environment **only after finishing the project**.

