FROM node:20-bullseye

COPY . /app
WORKDIR /app

# Removes compilation artifacts
RUN cd /app && rm -rf built node_modules
RUN cd /app && npm install

CMD npm run start
