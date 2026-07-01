FROM postgres:18-alpine

# Install gzip for compression, tzdata for timezone, and dos2unix for line ending fixes
# (postgresql-client is already included in the postgres base image)
RUN apk add --no-cache gzip tzdata dos2unix

# Set timezone to Philippines
ENV TZ=Asia/Manila

WORKDIR /app

# Copy the backup script and crontab
COPY backup.sh .
COPY crontab /etc/crontabs/root

# Fix Windows line endings and make the script executable
RUN dos2unix backup.sh && chmod +x backup.sh

# Create the log file so Docker can attach to it via the CMD
RUN touch /var/log/backup.log

# Run cron daemon in the background (-d 8 logs to stderr), then tail the log file
# so docker compose logs actually shows us what is happening
CMD crond -b -d 8 && tail -f /var/log/backup.log
