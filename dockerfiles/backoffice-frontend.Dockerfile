FROM node:18 AS builder
WORKDIR /app
COPY ./services/automation-backoffice/frontend/package*.json ./
RUN npm install
COPY ./services/automation-backoffice/frontend/ ./
ARG VITE_BACKEND_URL
ARG VITE_BASE_URL
ENV VITE_BACKEND_URL=$VITE_BACKEND_URL \
    VITE_BASE_URL=$VITE_BASE_URL
RUN npm run build
RUN mkdir -p dist/backoffice-frontend && mv dist/assets dist/backoffice-frontend/assets

FROM node:18-slim
WORKDIR /app
RUN npm install -g serve
COPY --from=builder /app/dist /app/dist
EXPOSE 5001
CMD ["serve", "-s", "dist", "-l", "5001"]
