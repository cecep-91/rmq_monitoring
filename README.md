# RabbitMQ Monitoring
## Monitoring RabbitMQ Queues and notify user via notification or telegram bot

### Prerequisites:
- python3
- notify-send
- curl

### How to use:
- Clone repositor
    ```bash
    git clone https://github.com/cecep-91/rmq_monitoring.git
    ```
- Change directory to the root dir of repository
    ```bash
    cd rmq_monitoring
    ```
- Rename .env_example to .env
    ```bash
    mv .env_example .env
    ```
- Edit required environment
    ```bash
    nano .env
    ```
- Run the monitoring script
    ```bash
    ./rmqmonitoring.sh
    ```