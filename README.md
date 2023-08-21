# django-blog

## How to set up Django with Docker (this works for any project, so feel free to use )

### Part 1: Creating the Django project.
1. Create a new directory with `mkdir example`;
2. Access such directory with `cd example`;
3. Create a virtual environment. I'm using `python3 -m venv EXAMPLEENV` in this app, now access it with `source example/bin/activate`. To leave the virtual environment, just type `deactivate EXAMPLEENV`;
4. Install Django with `pip install django` and see which version it's installing. In my case, the version installed is Django 4.2.4. You'll need to know it when creating a `requirements.txt` file for Docker;
5. Create a Django project with `django-admin startproject exampleapp`. Access the `exampleapp` folder with `cd example app`, perform a database migration `django manage.py migrate` and start the local server `python manage.py runserver`. You can now use your browser and go to http://localhost:8000. You should see something like the Image 1. **Warning: a different page may appear (they might change according to the installed Django version), but that doesn't mean something went wrong. Check the [Django official documentation](https://docs.djangoproject.com/) in case of doubt.**

![image](https://github.com/daniel-web-developer/django-blog/assets/107224353/3d510c45-11b9-4c0d-ae44-9f9121dfb81d "Image 1. Django install working successfully")

Your project directory's tree should look like this:

example (this is the root folder of your project)
```
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
1. Create the requirements.txt file in `root/exampleapp`. There's more than one way to do it, but from the root folder of your project `example` (from now on, in this `README.md` file, referred only as root folder for the sake of simplicity), you can enter `cd exampleapp` and then `touch requirements.txt`. In this file, we'll type the names and versions of the**dependencies** (packages your project can't work without, e.g. Django) so Docker will automatically download and add them to the project.
2. Add `Django==VERSION` to `requirements.txt`. VERSION should be the Django version intended to be used in this project. In my case, I'm adding `Django==4.2.4`.
3. 
4. #### Creating the first Dockerfile:

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
5. #### Creating the Docker Compose file:

   1. Go to the root directory of your project (`/example/`), create a `docker-compose.yml` file with `touch docker-compose.yml`.
  
       
