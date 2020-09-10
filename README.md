# Repository Mirroring Tool (RMT - containerized) for Cloud service providers

This tool allows you to mirror RPM repositories in your own private network.
Organization (mirroring) credentials are required to mirror SUSE repositories.

End-user documentation can be found in [RMT Guide](https://documentation.suse.com/sles/15-SP1/html/SLES-all/book-rmt.html).

## Benefits:
* RMT can be installed on SLES15 and higher but it takes time to install.
* Containerized version is easier and faster to get RMT up and working. Also you can run rmt in container on other linux distros and comfortable for CSP environment.

## Running with docker-compose
Although [SUSE CaasP](https://www.suse.com/products/caas-platform/) is the right tool to run containerized workload this time we want to keep it even easier and use docker-compose.

### Prerequisits:
* SLES15SP1 or higher
* docker engine installed e.g. zypper in -y docker
* download and install docker-compose:
    https://docs.docker.com/compose/install/
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    docker-compose --version
    ```
  __Cautious:__
  Do not install docker-compose from packagehub for SLES15SP1 as the docker-compose there needs python2 and not python3 which is installed on SLES15 and higher.
 
 __Remarks:__
 * __rmt-start.sh__ - When mariadb container starts for the first time it will init db and this process takes some time. To avoid db connect failure of rmt container a modified entrypoint script will sleep for 20 seconds followed by a db connect test. If db connect return is successful then the script will continue. 
 * __start delay__ - feel free to change the sleep time duration for your need.
 ``` sleep 20```
 * __mariadb__ - To keep mariadb init fast the below env parameter is in place and skip timezone table load.
 ```
 environment:
      - MYSQL_INITDB_SKIP_TZINFO=1
```
* __ssl__ - this subdirectory is needed. Place your self-signed CA and rmt ssl certificate into here otherwise nginx container will fail to start. If you don't need https connection then you have to use docker-compose-without-ssl.yml file or rename this file to docker-compose.yml. If you need a helping hand for generating self-signed ssl certs try [certstrap](https://github.com/square/certstrap)
* __docker images__ - we use opensuse built nginx, mariadb and rmt docker images. In the rmt image we added bind-utils for getting nslookup command. Changing image is ok but at your own risk. If you like just pull the images before hand:
```
docker pull registry.opensuse.org/home/bjin01/branches/opensuse/templates/images/15.2/images/opensuse/rmt-server:latest
docker pull registry.opensuse.org/opensuse/mariadb:latest
docker pull registry.opensuse.org/opensuse/nginx:latest
```
__In order to run the application locally using docker-compose:__

1. Copy `.env.example` file to `.env`;
2. Add your organization credentials to `.env` file. Mirroring credentials can be obtained from the [SUSE Customer Center](https://scc.suse.com/organization);
3. Start the containers by running `docker-compose up`. Running `docker-compose up -d` will start the containers in the background;
4. Execute commands in the container, e.g.:
    ```bash
    docker-compose exec rmt rmt-cli repos --help
    ```
    Alternatively, running `docker-compose exec rmt bash` will start the shell inside the container.
5. The web server will be accessible at [http://your-host-fqdn-or-ip](http://your-host-fqdn-or-ip/), this URL can be used for registering clients.
6. To test if repo is accessible open this url: http://your-host-fqdn-or-ip/repo you should see directory browsing which is empty as long as you have not synced any repo via scc.suse.com

Feedback is always welcome!
