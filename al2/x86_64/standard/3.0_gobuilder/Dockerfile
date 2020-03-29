FROM amazonlinux:2 AS core

ENV RICHANDERSONIO="hello from rich"

RUN yum install -y git go

RUN useradd codebuild-user

#****************     GOLANG 3rd partypackages for richandersio.io    ****************************************************

ENV GOPATH="/go"

RUN go get -u github.com/go-sql-driver/mysql
RUN go get -u github.com/go-redis/redis
RUN go get -u github.com/alicebob/miniredis/...
RUN go get -u github.com/google/uuid
RUN go get -u github.com/aws/aws-sdk-go/...

COPY dockerd-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["dockerd-entrypoint.sh"]

