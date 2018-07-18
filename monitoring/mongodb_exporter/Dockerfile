FROM golang:alpine

RUN apk update \
&& apk add  make \
            git \
            gcc \
            build-base

ARG REL='0.6.1'

WORKDIR /go/src/github.com/percona

RUN git clone  -b ${REL} --single-branch --depth 1 https://github.com/percona/mongodb_exporter.git

WORKDIR ./mongodb_exporter

RUN make build && cp mongodb_exporter /bin/mongodb_exporter

EXPOSE      9216
ENTRYPOINT  [ "/bin/mongodb_exporter" ]
