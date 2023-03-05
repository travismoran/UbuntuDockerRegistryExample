FROM nginx:stable
COPY html /usr/share/nginx/html
COPY conf/nginx.conf /etc/nginx/nginx.conf
