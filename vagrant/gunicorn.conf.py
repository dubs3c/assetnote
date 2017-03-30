accesslog = "logs/gunicorn.access.log"
errorlog = "logs/gunicorn.error.log"
reload = True
bind = "127.0.0.1:8080"
workers = 4
user = "vagrant"
group = "vagrant"