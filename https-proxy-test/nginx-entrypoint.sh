set -e

if [ ! -e /tmp/archiva-key.pem  ]
then
  apt-get update 
  apt-get install -y openssl
  # Generate the certificate to use
  openssl req -x509 -nodes \
    -newkey rsa:4096 -keyout /tmp/archiva-key.pem \
    -out /tmp/archiva-cert.pem \
    -days 365 \
    -subj '/C=US/ST=San Jose/L=California/O=Archiva/OU=Archiva/CN=archiva.test'
fi

sed s,PROXY_URL,$PROXY_URL, /tmp/nginx.conf > /etc/nginx/conf.d/default.conf

exec nginx -g "daemon off;"