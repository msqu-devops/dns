# ClouDNS-Updater
ClouDNS updater script is able to be run either as generic Python 3 script or as Docker container. 

### Note: .env file format to Docker variables
When this app runs out of a container it uses an .env file to load config. The file format is as follows:

```
export URL_CDNS = 'https://ipv4.cloudns.net/api/dynamicURL/?q=..........'
export URL_IPIO = 'https://ipinfo.io/json'
export LOG_FILE = 'iplog.txt'
export HOSTNAME = 'put.yourhostname.here'
export SLEEPTIME = 600
```
____Notes:____ 
- In this script [IPInfo](https://ipinfo.io) service for IP resolution is used. The URL used returns a JSON with a key named "ip" with an IP address as value. You can change this service provider transparently without altering the code meanwhile a JSON is returned with a key named "ip", in lower case letters, and an IP address is included as value. 
- In order to get the __URL_CDNS__ for your ClouDNS __HOSTNAME__ you must follow guidance in ClouDNS KB at https://www.cloudns.net/wiki/article/36/. Please note __URL_CDNS__ and __HOSTNAME__ are related. Each __HOSTNAME__ in ClouDNS will have a unique __URL_CDNS__. 
- __SLEEPTIME__ value is seconds, thus, 600 in seconds is 10 minutes. 

## Link to the Docker Hub repository
- Repository: https://hub.docker.com/r/ea1het/cloudns-updater
- Alternatively you can pull directly from docker CLI with ```docker pull ea1het/cloudns-updater ``` 

## Docker run command
In Docker, the way to export variables is to define them on the ```docker run``` execution, on a execution line similar to this:

```
docker run \
    -d --restart unless-stopped \
    --name cloudns-updater \
    -e URL_CDNS="https://ipv4.cloudns.net/api/dynamicURL/?q=.........." \
    -e URL_IPIO="https://ipinfo.io/json" \
    -e LOG_FILE="iplog.txt" \
    -e HOSTNAME="put.yourhostname.here" \
    -e SLEEPTIME=600 \
    ea1het/cloudns-updater:latest 
```
__Note:__ It can happen that you cannot see logs from the docker container while it's in execution. This is caused due to Python buffered output. In order to see logs from the container buffered output must be disabled for this specific container. This can be done in two ways, a) setting an environment variable or b) using a modifier for the Python interpreter. The prefered option is the first because it doesn't imply modifying the container. In any case, for the sake of the explanation, following are the options explained:
  - Environment variable: set ```PYTHONUNBUFFERED=0``` in the container execution command (in CLI or in a UI like Portainer).
  - Interpreter modifier: use ```python -u app.py``` inside the container (in development or in run time) or craft the appropiate changes in the Dockerfile:
    ```
    ENTRYPOINT ["python3"]
    CMD ["-u", "app.py"]
    ``` 

## Docker build command
### Build standard for the PC/UNIX architecture you are using
``` 
docker build \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%d"` \
--build-arg VERSION=v1.0 \
-t ea1het/cloudns-updater:latest .
``` 
### Cross-compilation build sequence
Cross-compilation is an experimental Docker feature. You can enable it in your Docker Desktop settings. The procedure to cross-compile can be briefly resumed this way:

  1. Ensure cross-compiler is available: ```docker buildx ls```
  2. Create a new builder instance (a container): ```docker buildx create --name testbuilder```
  3. Switch to _'testbuilder'_ builder instance: ```docker buildx use testbuilder```
  4. Ensure _'testbuilder'_ builder is ready to be used: ```docker buildx inspect --bootstrap``` 
  5. If needed, authenticate against Docker Hub: ```docker login```
  6. Clone locally the repo you want to cross compile: ```git clone https://.....```
  7. Finally, execute buildx build sentences for the platform you want to cross-compile. Examples below. 

#### Cross-compilation for ARMv7
``` 
docker buildx build \
--platform linux/arm/v7 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%d"` \
--build-arg VERSION=v1.0 \
-t ea1het/cloudns-updater:latest-armv7 --push .
``` 
#### Cross-compilation for ARMv6
``` 
docker buildx build \
--platform linux/arm/v6 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%d"` \
--build-arg VERSION=v1.0 \
-t ea1het/cloudns-updater:latest-armv6 --push .
``` 
#### Cross-compilation for ARM64
``` 
docker buildx build \
--platform linux/arm64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%d"` \
--build-arg VERSION=v1.0 \
-t ea1het/cloudns-updater:latest-arm64 --push .
``` 
#### Cross-compilation for AMD64
``` 
docker buildx build \
--platform linux/amd64 \
--build-arg VCS_REF=`git rev-parse --short HEAD` \
--build-arg BUILD_DATE=`date -u +"%Y-%m-%d"` \
--build-arg VERSION=v1.0 \
-t ea1het/cloudns-updater:latest-amd64 --push .
