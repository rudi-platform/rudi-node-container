FROM node:20-alpine3.19
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories
RUN apk add --no-cache mongodb mongodb-tools

RUN mkdir -p /home/rudi-node/mongo /data/db
WORKDIR /home/rudi-node

COPY ./src/ ./install/* env/* ./
RUN ./internal-setup.sh && rm ./internal-setup.sh 

EXPOSE 3000-3003
CMD ./start.sh