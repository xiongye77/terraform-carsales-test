FROM node:16

RUN apt-get update && apt-get install -y --no-install-recommends curl
# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
# If you are building your code for production
# RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE 80
ENTRYPOINT ["env"]
CMD [ "node", "server.js" ]

