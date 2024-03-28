FROM mongo:7.0.7
# RUN cat /etc/os-release
RUN apt-get update
RUN apt-get install curl; curl -fssL https://deb.nodesource.com/setup_20.x | bash; apt-get install -y nodejs
RUN mkdir -p /home/rudi-node /data/db
WORKDIR /home/rudi-node

COPY ./src/ ./install/* env/* ./
RUN ./oci-setup.sh && rm ./oci-setup.sh 

EXPOSE 3000-3003
CMD ./oci-startup.sh