FROM node:slim

RUN mkdir -p /opt/apigee/microgateway


RUN npm install edgemicro@2.3.5 -g
RUN edgemicro init

RUN mkdir -p /root/.edgemicro/configmap
ADD start_microgateway.sh /root/.edgemicro
RUN chmod 775 /root/.edgemicro/start_microgateway.sh



WORKDIR /root/.edgemicro
CMD ["/bin/bash", "-c","./start_microgateway.sh"]

EXPOSE 8000
