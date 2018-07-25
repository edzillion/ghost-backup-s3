FROM alpine:3.6
LABEL version="0.5"
LABEL maintainer="edzillion@gmail.com"

RUN apk update && apk --no-cache add bash py-pip mysql-client sqlite && pip install awscli
COPY watch.sh watch.sh
COPY backup.sh backup.sh
COPY restore.sh restore.sh
RUN chmod +x watch.sh && chmod +x backup.sh && chmod +x restore.sh

# -----------------------
# Default configuration
# -----------------------

# Backup daily at 3am    
ENV BACKUP_INTERVAL "1d" 

# S3 Region - warning! this needs to be the region in which your s3 bucket is located
ENV AWS_DEFAULT_REGION "eu-central-1"

# This needs to be changed if you want to restore on `docker run`
ENV BACKUP_ONLY "true"

# -----------------------

VOLUME /data

ENTRYPOINT [ "./watch.sh" ]
CMD ["/data"]
