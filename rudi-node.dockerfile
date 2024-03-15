FROM node:20-alpine3.19

RUN mkdir -p /home/rudi-node
WORKDIR /home/rudi-node

COPY ./src/ ./internal-setup.sh .bashrc ./
RUN ./internal-setup.sh