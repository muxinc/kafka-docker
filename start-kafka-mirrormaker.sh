#!/bin/bash

if [[ -z "$KAFKA_PORT" ]]; then
    export KAFKA_PORT=9094
fi

echo -e "\n" >> $KAFKA_HOME/config/consumer.properties
echo -e "\n" >> $KAFKA_HOME/config/producer.properties

for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_CONSUMER ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_CONSUMER_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/consumer.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/consumer.properties
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/consumer.properties
    fi
  fi
  if [[ $VAR =~ ^KAFKA_PRODUCER ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_PRODUCER_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/producer.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/producer.properties
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/producer.properties
    fi
  fi
  if [[ $VAR =~ ^LOG4J_ ]]; then
    log4j_name=`echo "$VAR" | sed -r "s/(LOG4J_.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    log4j_env=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$log4j_name=" $KAFKA_HOME/config/tools-log4j.properties; then
        sed -r -i "s@(^|^#)($log4j_name)=(.*)@\2=${!log4j_env}@g" $KAFKA_HOME/config/tools-log4j.properties #note that no config values may contain an '@' char
    else
        echo "$log4j_name=${!log4j_env}" >> $KAFKA_HOME/config/tools-log4j.properties
    fi
  fi
done

if [[ -n "$CUSTOM_INIT_SCRIPT" ]] ; then
  eval $CUSTOM_INIT_SCRIPT
fi

exec $KAFKA_HOME/bin/kafka-mirror-maker.sh --abortOnSendFail --whitelist $KAFKA_MM_WHITELIST --num.streams $KAFKA_MM_NUM_STREAMS  --consumer.config $KAFKA_HOME/config/consumer.properties --producer.config $KAFKA_HOME/config/producer.properties
