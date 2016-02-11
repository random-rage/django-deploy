 ##############################################
#                                              #
# Django app "Create&Deploy" script for Debian #
#            by random_rage @ 2016             #
#                                              #
 ##############################################

# GLOBAL SCRIPT CONSTANTS
DJANGO_VERSION="1.9.2"
PYTHON_VERSION="3"

# Is sudo available?
if [ ! -f "/etc/sudoers" ];
then
	echo "You need to install sudo and add user to the sudo group! Run as root:"
	echo "apt-get install sudo"
	echo "adduser `whoami` sudo"
	echo "And reboot."
	exit
fi

# Read project name
echo "Please enter project name to create:"
read PROJECT_NAME

# Install Python, Gunicorn and NGINX
echo "Installing python and nginx..."
sudo apt-get update
sudo apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-dev nginx supervisor

# Upgrade PIP
echo "Upgrading pip..."
sudo pip$PYTHON_VERSION install --upgrade pip

# Install and upgrade VirtualEnv
echo "Installing virtualenv..."
sudo pip$PYTHON_VERSION install virtualenv
sudo pip$PYTHON_VERSION install --upgrade virtualenv

# Create and activate a virtual environment
echo "Creating a virtual environment..."
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"
mkdir "env"
virtualenv -p python$PYTHON_VERSION "env"

echo "Activating the virtual environment..."
source "env/bin/activate"

# Upgrade PIP
echo "Upgrading pip..."
pip$PYTHON_VERSION install --upgrade pip

# Install Django and Gunicorn
echo "Installing Django and Gunicorn..."
pip$PYTHON_VERSION install Django==$DJANGO_VERSION
pip$PYTHON_VERSION install gunicorn
pip$PYTHON_VERSION install --upgrade gunicorn

# Create a Django project
echo "Creating a Django project..."
django-admin.py startproject $PROJECT_NAME .

# Configure Django project
echo "Configuring Django project..."
echo "STATIC_ROOT = os.path.join(BASE_DIR, \"static/\")" >> "$PROJECT_NAME/settings.py"
python$PYTHON_VERSION manage.py collectstatic --noinput

# Configure Supervisor
echo "Configuring Supervisor..."
SV_CONFIG="/etc/supervisor/conf.d/$PROJECT_NAME.conf"

sudo rm -f $SV_CONFIG
sudo touch $SV_CONFIG
echo "[program:$PROJECT_NAME]" | sudo tee -a $SV_CONFIG
echo "command=`pwd`/env/bin/gunicorn --bind unix:`pwd`/$PROJECT_NAME.sock $PROJECT_NAME.wsgi:application" | sudo tee -a $SV_CONFIG
echo "directory=`pwd`" | sudo tee -a $SV_CONFIG
echo "user=`whoami`" | sudo tee -a $SV_CONFIG
echo "autostart=true" | sudo tee -a $SV_CONFIG
echo "autorestart=true" | sudo tee -a $SV_CONFIG
echo "redirect_stderr=true" | sudo tee -a $SV_CONFIG

# Configure NGINX
echo "Configuring NGINX..."
NGINX_CONFIG="/etc/nginx/sites-available/$PROJECT_NAME"

sudo rm -f $NGINX_CONFIG
sudo touch $NGINX_CONFIG
echo "server {" | sudo tee -a $NGINX_CONFIG
echo "    listen 80;" | sudo tee -a $NGINX_CONFIG
echo "    server_name 0.0.0.0;" | sudo tee -a $NGINX_CONFIG
echo "    location = /favicon.ico { access_log off; log_not_found off; }" | sudo tee -a $NGINX_CONFIG
echo "    location /static/ {" | sudo tee -a $NGINX_CONFIG
echo "        root `pwd`;" | sudo tee -a $NGINX_CONFIG
echo "    }" | sudo tee -a $NGINX_CONFIG
echo "    location / {" | sudo tee -a $NGINX_CONFIG
echo "        include proxy_params;" | sudo tee -a $NGINX_CONFIG
echo "        proxy_pass http://unix:`pwd`/$PROJECT_NAME.sock;" | sudo tee -a $NGINX_CONFIG
echo "    }" | sudo tee -a $NGINX_CONFIG
echo "}" | sudo tee -a $NGINX_CONFIG
sudo ln -s "$NGINX_CONFIG" "/etc/nginx/sites-enabled"
sudo rm -f "/etc/nginx/sites-enabled/default"

# Configure DB // TODO: need to be done
#python$PYTHON_VERSION manage.py makemigrations
#python$PYTHON_VERSION manage.py migrate

# Start services
echo "Starting services..."
sudo service supervisor restart
sudo service nginx restart
echo "Done!"
