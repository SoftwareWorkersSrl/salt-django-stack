#!/bin/bash -e
# this script may need to run with source to switch the virtualenv correctly, like this: $ source thisscript.sh

# Pass the parameter "dev" to start Django's development server.
# thiscript dev
# Pass "production" and "--log-level=LOGLEVEL" to start Gunicorn with a specific log level.
# thiscript production --log-level=debug
# Pass no parameter to start a production setup, like Gunicorn.

{% set dummy_db = salt['pillar.get']('postgres:lookup:dummy_db', '') -%}
{% if dummy_db != '' -%}
export PROJECT_DATABASES_DEFAULT_NAME="{{ dummy_db }}"
{% else -%}
{% for db_name, db_values in salt['pillar.get']('postgres:databases', []).items() -%}
export PROJECT_DATABASES_DEFAULT_NAME="{{ db_name }}"
export PROJECT_DATABASES_DEFAULT_USER="{{ db_values.user }}"
{% for user_name, user_values in salt['pillar.get']('postgres:users', []).items() -%}
{% if user_name == db_values.user -%}
export PROJECT_DATABASES_DEFAULT_PASSWORD="{{ user_values.password }}"
{% endif -%}
{% endfor -%}
{% endfor -%}
{% for id, postgresql_server in salt['pillar.get']('zinibu_basic:project:postgresql_servers', {}).iteritems() %}
export PROJECT_DATABASES_DEFAULT_HOST="{{ postgresql_server.private_ip }}"
export PROJECT_DATABASES_DEFAULT_PORT="{{ postgresql_server.port }}"
{% endfor -%}
{% endif -%}

{% for id, redis_node in salt['pillar.get']('zinibu_basic:project:redis_nodes', {}).iteritems() %}
export PROJECT_REDIS_HOST="{{ redis_node.private_ip }}"
{% endfor -%}

# user/group to run as
USER={{ user }}
GROUP={{ group }}
export HOME="/home/$USER"

# PROJECTNAME is used by the Python virtual environment, the Django project and the log file.
PROJECTNAME={{ project_name }}
PROJECTDIR=/home/$USER/$PROJECTNAME
PROJECTENV=/home/$USER/pyvenvs/$PROJECTNAME
export DJANGO_SETTINGS_MODULE=$PROJECTNAME.settings.local

#LOGFILE=/home/$USER/logs/$PROJECTNAME.log
LOGFILE=/var/log/upstart/$PROJECTNAME.log
LOGDIR=$(dirname $LOGFILE)

NUM_WORKERS=3
BIND_ADDRESS={{ private_ip }}:{{ gunicorn_port }}

source $PROJECTENV/bin/activate

cd $PROJECTDIR
export LC_ALL="en_US.UTF-8"

# logging inside /var/log/upstart, the directory should already be present
#test -d $LOGDIR || mkdir -p $LOGDIR

if [ "$1" == "dev" ]; then
  # development server
  # no need for calling python first for django-admin.py
  echo "==================================="
  echo "Django development server"
  echo "==================================="
  # Using DJANGO_SETTINGS_MODULE environment variables as we are not specifying --settings
  #django-admin.py runserver --pythonpath=`pwd` --settings=$PROJECTNAME.settings $BIND_ADDRESS
  django-admin.py runserver --pythonpath=`pwd` $BIND_ADDRESS
  # thin wrapper for django-admin.py, no need for --pythonpath or --settings but it requires to use python first
  #python manage.py runserver $BIND_ADDRESS
elif [ "$1" == "shell" ]; then
  django-admin.py shell --pythonpath=`pwd`
elif [ "$1" == "setenv" ]; then
  echo "Environment variables to run $PROJECTNAME"
  echo "You can use any django-admin.py command from $PROJECTDIR (note the use of --pythonpath and pwd between backticks), for example:"
  echo "django-admin.py shell --pythonpath=\`pwd\`"
elif [ "$1" == "production" ]; then
  # production server (gunicorn)
  # see http://docs.gunicorn.org/en/latest/settings.html#loglevel
  # possible values: debug, info, warning, error, critical
  if [ "$2" == "--log-level=debug" ]; then
    LOGLEVEL=debug
  elif [ "$2" == "--log-level=critical" ]; then
    LOGLEVEL=critical
  else
    LOGLEVEL=info
  fi
  gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application --log-level=$LOGLEVEL --log-file=$LOGFILE 2>>$LOGFILE
  # I don't think exec is important anymore here to keep environment variables when running any of the commands with upstart
  #exec gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application --log-level=$LOGLEVEL --log-file=$LOGFILE 2>>$LOGFILE
elif [ "$1" == "collectstatic" ]; then
  echo "==================================="
  echo "Django collect static files"
  echo "==================================="
  #django-admin.py collectstatic --pythonpath=`pwd` --settings=$PROJECTNAME.settings --noinput
  # Using DJANGO_SETTINGS_MODULE environment variables as we are not specifying --settings
  django-admin.py collectstatic --pythonpath=`pwd` --noinput
else
  ## production server (gunicorn) with log to console
  echo "==================================="
  echo "Gunicorn with log to console"
  echo "==================================="
  gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application
fi
