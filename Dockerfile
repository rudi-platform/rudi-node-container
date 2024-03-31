FROM mongo:7.0.7

RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs netcat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/rudi-node 
WORKDIR /app/rudi-node

COPY ./src/ ./install/* env/* ./
RUN ./oci-setup.sh && \
    rm ./oci-setup.sh 

EXPOSE 3000-3003
CMD ./oci-startup.sh