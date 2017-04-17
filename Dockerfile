FROM debian:latest

MAINTAINER @mjdubell

RUN adduser --disabled-password --gecos "" assetnote

ADD . /var/www/assetnote/
WORKDIR /var/www/assetnote/

RUN apt-get update && apt-get install -y \
    python3 \
    vim \
    python3-dev \
    libmysqlclient-dev \
    python3-bcrypt \
    python3-pip \
    python3-venv \
    libffi-dev \
    build-essential \
    libssl-dev \
    cron

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN chown assetnote:assetnote -R /var/www/assetnote

#USER assetnote
#RUN crontab docker/crontab.txt
ADD docker/crontab.txt /etc/cron.d/cronjob
RUN chmod 0644 /etc/cron.d/cronjob
RUN /usr/bin/crontab /etc/cron.d/cronjob
RUN touch /var/log/cron.log
CMD cron