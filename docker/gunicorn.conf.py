accesslog = "logs/gunicorn.access.log"
errorlog = "logs/gunicorn.error.log"
reload = True
bind = "0.0.0.0:8080"
workers = 4
user = "assetnote"
group = "assetnote"