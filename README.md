# What is it?
Django app Create&amp;Deploy script

This script automatically installs and deploys Python + Django + Gunicorn + NGINX server.

# What to do?

1. Install Debian
2. Install sudo (as root):

  ```shell
  su root
  apt-get install sudo
  ```

3. Add user to the sudo group and reboot (as root):

  ```shell
  adduser <user> sudo
  reboot
  ```

4. Download django-deploy script
5. Run the script:

  ```shell
  chmod +x deploy.sh
  ./deploy.sh
  ```

6. Script will ask you project name, enter it.
7. Wait until the script has finished job.
8. Open browser in your Debian and go to http://127.0.0.1
9. Well done!
