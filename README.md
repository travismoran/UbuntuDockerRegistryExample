# UbuntuDockerRegistryExample
Example of how to setup your own Docker Registry with Lets Encrypt

```
# use the helper script to install the latest docker version
curl -fsSL get.docker.com | sh

# in Ubuntu the group will already be created but if not add the docker group and then add your user so you don't have to sudo every command
sudo groupadd docker
sudo usermod -aG docker $USER

# install certbot and request a valid SSL cert for your registry
# https://certbot.eff.org/instructions?ws=other&os=ubuntufocal

sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# create your dns host record in your registrar or dns management portal/server(cloudflare), you will also need to create a dns txt record to validate you own the domain for certbot/lets encrypt.

sudo certbot -d exampleregistry.traviscloud.com --manual --preferred-challenges dns certonly
# add the providated txt record wait a few minutes and then continue the certbot script(this will only need to be the first time).


# since certbot creates new symlinks based on the current certificate renewal we want to copy the actual files into a directory that will be mounted into our registry container.  We can add a cronjob to automate this and the certbot renewals then restart the container to update the certificates.
cp /etc/letsencrypt/live/exampleregistry.traviscloud.com/ certs/

# create the auth records for your registry
docker run   --entrypoint htpasswd   httpd:2 -Bbn travisclouduser tcpassword123 > auth/htpasswd

# start the registry container bind mounting the certificates and encoded htpasswd file for authentication
docker run -d -p 443:5000 --restart=always --name registry -v ./auth:/auth -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v ./certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem registry:2.7.1

# test connecting to your newly created registry!
docker login exampleregistry.traviscloud.com
# test logging in manually with travisclouduser tcpassword123

# automated build example Dockerfile example proivded in repo
# set variables
export dregu=travisclouduser
export dregp=tcpassword123

# login to your new registry
docker login --username $dregu --password $dregp exampleregistry.traviscloud.com

# build image
docker build -t exampleregistry.traviscloud.com/tcnginxexample:latest .

# push to the new registry
docker push exampleregistry.traviscloud.com/tcnginxexample:latest
# run test image
docker run -it -d -p 80:80 exampleregistry.traviscloud.com/tcnginxexample:latest
# curl it or visit http://exampleregistry.traviscloud.com
curl localhost