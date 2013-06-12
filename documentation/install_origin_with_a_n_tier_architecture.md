# @markup markdown
# @title Installing OpenShift Origin with a n-tier architecture

# Install OpenShift Origin with a n-tier architecture

A basic install of OpenShift will need you to setup a delegation from your entreprise DNS to the OpenShift DNS.
But you can also setup OpenShift, to use a private DNS not exposed to any other services than OpenShift.

In this setup, user applications will be accessible via nginx.
SSH and git will be accessible with the IP address directly.

This setup is quite interesting for companies wanting the broker, the console, SSH and git being only available on the private network.

```
      Internet
         |
         |
        \|/
    /---------\
    |  Front  |
___ |  -----  | ______________________________________
    |  Nginx  |\             
    |  80/443 | \          LAN
    \---------/  \
         |        \
         |         \
         |          /----------\
         |          |  Middle  |
         |          |  ------  |
         |          |  Broker  |
         |          |  Console |
         |          |    DNS   |
         |          \----------/
         |              / /|\
         |             /   |
         |            /    |
         |           /     |
         |          /      |
        \|/        /       |
/----------------------\   |
|    OpenShift Node    |   |
|    --------------    |   |
|   user applications  |   |
\----------------------/   |
        /|\                |
         |                 |
         |                 |
      Git Push        Admin Access
   (from the LAN)
   
```

## Setup nginx

Front servers accessible from internet, will proxy request to users applications via nginx.

Put the following block in your nginx configuration file.
For openshift alias to works, this block should be a catchall (put it at the begining).

Replace the following variables by the corresponding values.
* PUBLIC_IP: IP accessible from internet
* OPENSHIFT_DNS_MASTER: openshift master DNS IP
* OPENSHIFT_DNS_SLAVE: openshift slave DNS IP
* SSL_CERT: path to your SSL certificate
* SSL_KEY: path to your SSL key


    server {
            listen PUBLIC_IP:80;
            listen PUBLIC_IP:443 ssl;
            listen PUBLIC_IP:8000;
            listen PUBLIC_IP:8443 ssl;
            ssl_certificate SSL_CERT;
            ssl_certificate_key SSL_KEY;

            server_name  _;
            resolver OPENSHIFT_DNS_MASTER OPENSHIFT_DNS_SLAVE;

            proxy_read_timeout 1d;
            location / {
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header Host $host;
                    proxy_pass   $scheme://$host:$server_port$uri$is_args$args;
                    proxy_http_version 1.1;
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection "upgrade";
            }
    }

## Setup broker

Change the following line in your broker.conf file

    # Print SSH and GIT uri with fqdn. If "false", IP is printed
    SSH_FQDN="false"
