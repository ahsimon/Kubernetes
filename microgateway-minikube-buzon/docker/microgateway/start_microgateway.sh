#!/usr/bin/env bash


# Setting ENV variables passed in secrets
source /opt/apigee/microgateway/config.txt
  
# copy default config from configmap volume
cp /root/.edgemicro/configmap/default.yaml /root/.edgemicro/default.yaml

# Configure microgateway

echo "edgemicro private configure -o "$EDGEMICRO_ORG " -e "$EDGEMICRO_ENV " -u "$EDGEMICRO_USER "-p "$EDGEMICRO_PASS"  -r "$EDGEMICRO_R "-m "$EDGEMICRO_M " -v " $EDGEMICRO_V 
edgemicro private configure -o $EDGEMICRO_ORG -e $EDGEMICRO_ENV -u $EDGEMICRO_USER -p $EDGEMICRO_PASS  -r $EDGEMICRO_R -m $EDGEMICRO_M -v $EDGEMICRO_V > /tmp/output && \

cat   /tmp/output  | sed 's/.*\(.\{64\}\)/\1/' |  grep -oP "^[[:alnum:]]{64}" > /tmp/keyoutput && \
echo "# use these environment variables to start edgemicro"

cat /tmp/keyoutput | head -n 1 | awk '{print "export EDGEMICRO_KEY="$1}'  && \
cat /tmp/keyoutput | tail -n 1 | awk '{print "export EDGEMICRO_SECRET="$1}' 

eval $(cat /tmp/keyoutput | head -n 1 | awk '{print "export EDGEMICRO_KEY="$1}'  )
eval $(cat /tmp/keyoutput | tail -n 1 | awk '{print "export EDGEMICRO_SECRET="$1}'  )


rm /tmp/keyoutput 


# Run microgateway

edgemicro verify -o $EDGEMICRO_ORG -e  $EDGEMICRO_ENV -k $EDGEMICRO_KEY -s $EDGEMICRO_SECRET 2>&1

edgemicro start -o $EDGEMICRO_ORG -e  $EDGEMICRO_ENV -k $EDGEMICRO_KEY -s $EDGEMICRO_SECRET 2>&1
