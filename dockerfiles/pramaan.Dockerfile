FROM node:16-alpine
WORKDIR /app

ARG SERVICE_DIR
COPY ${SERVICE_DIR}/ .

RUN npm install

CMD ["node", "./src/server.js"]
