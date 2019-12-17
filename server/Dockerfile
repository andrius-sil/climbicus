FROM python:3.7

RUN apt-get update && apt-get install -y \
    nginx \
    supervisor

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/
COPY uwsgi.ini /etc/uwsgi/
COPY supervisord.conf /etc/supervisor/
COPY . .

ENV FLASK_APP run.py

EXPOSE 5000
