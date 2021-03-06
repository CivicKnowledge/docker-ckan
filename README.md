# docker-ckan
Docker build directory for a single-machine instance of CKAN

````
docker run \
-e 'SITE_URL=ckan.sandiegodata.org' -e "ADMIN_USER_PASS=password"  \
-e "ADMIN_USER_EMAIL=eric@busboom.org" -e "ADMIN_USER_KEY=apikey"  \
-P --name ckan ckan_solo
```

For development run with:

```
docker run \
-e 'SITE_URL=ckan.sandiegodata.org' -e "ADMIN_USER_PASS=password"  \
-e "ADMIN_USER_EMAIL=eric@busboom.org" -e "ADMIN_USER_KEY=apikey"  \
-e "DEBUG=1" \
-P --rm -t -i --name ckan ckan_solo
```

Run a server that accesses the volumes: 
```
docker run --rm -t -i --volumes-from ckan ubuntu /bin/bash
```
The CKAN source directory is ``/opt/ckan/src/ckan``

## Adminstration

To run an ssh server on the container, set the ``ssh`` env var to the root password. Then, get the port mapped to the container's port 22 with ``docker ps`` and ssh in with the ``-p`` option. 

Running with ``$SSH`` set also create a ``ckpaster`` that will run paster commands without the need to specify the ckan plugin and configuration file.


