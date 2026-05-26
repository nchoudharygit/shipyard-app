FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 1000
ENV APP_ENV="production"
CMD ["node", "app.js"]

