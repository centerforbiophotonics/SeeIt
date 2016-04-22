SeeIt
================

Build Instructions
================

Docker makes it super easy. On OSX or Windows just install the docker toolbox https://www.docker.com/products/docker-toolbox

Then start the Docker Quickstart Terminal and run

    docker-compose build
    docker-compose up

The server is now running. To get its address open another Docker Quickstart Terminal and run:

    docker-machine ip

The server's address is usually

    192.168.99.100:3000

