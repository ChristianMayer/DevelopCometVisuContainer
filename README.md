Docker container for the CometVisu
==================================

This container will run the [CometVisu building automation visualization](https://www.cometvisu.org/). It also contains an Apache / PHP combo with the knxd (0.0.5.1) as well as RRD support for the diagram plugin.

Available versions:
-------------------

* `0.10.2`, `latest`:  
  [![](https://images.microbadger.com/badges/version/cometvisu/cometvisu:latest.svg)](https://microbadger.com/images/cometvisu/cometvisu:latest "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/cometvisu/cometvisu:latest.svg)](https://microbadger.com/images/cometvisu/cometvisu:latest "Get your own image badge on microbadger.com")
* `testing`, `testing-<date>`:  
  [![](https://images.microbadger.com/badges/version/cometvisu/cometvisu:testing.svg)](https://microbadger.com/images/cometvisu/cometvisu:testing "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/cometvisu/cometvisu:testing.svg)](https://microbadger.com/images/cometvisu/cometvisu:testing "Get your own image badge on microbadger.com")

Environment parameters:
-----------------------

|Parameter              |Default                  |Description|
|-----------------------|-------------------------|-----------|
|KNX_INTERFACE          |iptn:172.17.0.1:3700     |Setting this to empty string, will prevent the knxd from beeing startet|
|KNX_PA                 |1.1.238                  ||
|KNXD_PARAMETERS        |-u -d/var/log/eibd.log -c||
|CGI_URL_PATH           |/cgi-bin/                |Set the URL prefix to find the `cgi-bin `ressources|
|BACKEND_PROXY_SOURCE   |                         |Proxy paths starting with this value, e.g. `/rest` for openHAB backend|
|BACKEND_PROXY_TARGET   |                         |Target URL for proxying the requests to BACKEND_PROXY_SOURCE, e.g. `http://<openhab-server-ip-address>:8080/rest` for openHAB backend|

Example configuration for an openHAB backend (running on host `192.168.0.10`):

```
KNX_INTERFACE=
CGI_URL_PATH=/rest/
BACKEND_PROXY_SOURCE=/rest
BACKEND_PROXY_TARGET=http://192.168.0.10:8080/rest
```

Setup:
------

**Please look at the manual on [https://www.cometvisu.org/](https://www.cometvisu.org/) for the usage instructions!**

The CometVisu should be installed to the directory `/var/www/html`. This would then result in the config files to be located at `/var/www/html/config` which should most likely be a volume then.

The RRD files, when that feature is desired to be used, must be located in the directory `/var/www/rrd/`. So this would also be a volume as the RRD files must be created and filled up from an external source to this container.  
**NOTE:** the RRD files must be compatible in architecture as they can't be used otherwise.