Docker container for the CometVisu
==================================

This containter contains the CometVisu in release 0.10.2 together with a
 knxd (0.0.5.1) running on a Apache / PHP combo.
 
 Environment parameters:
------------------------

|Parameter|Default|Description|
|---------|-------|-----------|
|KNX_INTERFACE  |iptn:172.17.0.1:3700     ||
|KNX_PA         |1.1.238                  ||
|KNXD_PARAMETERS|-u -d/var/log/eibd.log -c||
|CGI_URL_PATH   |/cgi-bin/                |Set the URL prefix to find the `cgi-bin `ressources|