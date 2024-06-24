#!/bin/bash

# ----- LOAD ENVIRONMENTS FROM .env
source .env

# Telegram Credentials
BOT_TOKEN="${ENV_BOT_TOKEN}"
CHAT_ID="${ENV_CHAT_ID}"

# RabbitMQ Credentials
RMQ_HOST="${ENV_RMQ_HOST}"
RMQ_PORT="${ENV_RMQ_PORT}"
RMQ_USERNAME="${ENV_RMQ_USERNAME}"
RMQ_PASSWORD="${ENV_RMQ_PASSWORD}"

# SCRIPT CONFIGURATION
INTERVAL="${ENV_INTERVAL}"
CHECK_MSG_READY=${ENV_CHECK_MSG_READY}
CHECK_MSG_UNACKNOWLEDGED=${ENV_CHECK_MSG_UNACKNOWLEDGED}
MSG_READY_THRESHOLD="${ENV_MSG_READY_THRESHOLD}"
MSG_UNACKNOWLEDGED_THRESHOLD="${ENV_MSG_UNACKNOWLEDGED_THRESHOLD}"
NOTIFY_NOTIFICATION=${ENV_NOTIFY_NOTIFICATION}
NOTIFY_TELEGRAM=${ENV_NOTIFY_TELEGRAM}

# ENVS
URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

# Variable for RabbitMQ messages_ready and messages_unacknowledged
declare -A msg_ready
declare -A msg_unack

while true; do
    # ----- GET AND PRINT RABBITMQ QUEUES
    echo "Monitoring RabbitMQ $(date)"
    rmqvalue=$(./rabbitmqadmin --host=${RMQ_HOST}\
            --port=${RMQ_PORT} --username=${RMQ_USERNAME} --password=${RMQ_PASSWORD}\
            list queues name messages_ready messages_unacknowledged)
    printf "%s\n" "$rmqvalue"

    # ----- SET msg_ready and msg_unack
    for i in $(echo "${rmqvalue}" | grep -P '\w' | awk 'NR > 1 {print $2}'); do
        msg_ready["$i"]=$(echo "${rmqvalue}" | grep -P '\w' | awk -v queue="$i" '$2 == queue {print $4}')
        msg_unack["$i"]=$(echo "${rmqvalue}" | grep -P '\w' | awk -v queue="$i" '$2 == queue {print $6}')
    done

    # ----- CHECK messages_ready
    for i in "${!msg_ready[@]}"; do
        if [ "${msg_ready[$i]}" -gt ${MSG_READY_THRESHOLD} ] && [ ${CHECK_MSG_READY} == true ]; then
            MESSAGE="Queue with more than ${MSG_READY_THRESHOLD} messages ready: $i"
            # ----- DEBUG TO TERMINAL AND APPEND TO LOG FILE
            echo "${MESSAGE}" | tee -a ./logs/rabbitmq_monitoring_$(date +"%Y-%m-%d").log

            # ----- NOTIFY VIA GNOME NOTIFICATION
            if [ ${NOTIFY_NOTIFICATION} == true ]; then
                notify-send -i ./rmq.png "RabbitMQ Monitoring: Data stuck detected" "${MESSAGE}"
            fi

            # ----- NOTIFY VIA TELEGRAM BOT
            if [ ${NOTIFY_TELEGRAM} == true ]; then
                curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" > /dev/null
            fi
        fi
    done

    # ----- CHECK messages_unacknowledged
    for i in "${!msg_unack[@]}"; do
        if [ "${msg_unack[$i]}" -gt ${MSG_UNACKNOWLEDGED_THRESHOLD} ] && [ ${CHECK_MSG_UNACKNOWLEDGED} == true ]; then
            MESSAGE="Queue with more than ${MSG_UNACKNOWLEDGED_THRESHOLD} messages unacknowledged: $i"
            # ----- DEBUG TO TERMINAL AND APPEND TO LOG FILE
            echo "${MESSAGE}" | tee -a ./logs/rabbitmq_monitoring_$(date +"%Y-%m-%d").log

            # ----- NOTIFY VIA GNOME NOTIFICATION
            if [ ${NOTIFY_NOTIFICATION} == true ]; then
                notify-send -i ./rmq.png "RabbitMQ Monitoring: Data stuck detected" "${MESSAGE}"
            fi

            # ----- NOTIFY VIA TELEGRAM BOT
            if [ ${NOTIFY_TELEGRAM} == true ]; then
                curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$MESSAGE" > /dev/null
            fi
        fi
    done
    sleep $INTERVAL
    echo -e "\n\n"
done