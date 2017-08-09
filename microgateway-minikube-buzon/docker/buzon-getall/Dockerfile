FROM node:4.2
COPY . /src
RUN cd /src && npm install
EXPOSE 5552
CMD ["node", "/src/server.js"]
