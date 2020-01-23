FROM golang:1.13

RUN mkdir /TaskProject
ADD . /TaskProject
WORKDIR /TaskProject

ENV GO111MODULE=on
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ./build/app -x github.com/elizavetamikhailova/TasksProject/cmd

RUN ls

FROM alpine:latest

RUN apk add --no-cache --update ca-certificates tzdata \
    && cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime \
    && echo "Europe/Moscow" >  /etc/timezone

RUN apk --no-cache add ca-certificates
WORKDIR /root/
ADD configs /root/configs
# ADD data /root/data
COPY --from=0 /TaskProject/build/app .
CMD ["/root/app"]
