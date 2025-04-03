FROM golang:1.23.1-alpine as base
RUN apk add curl file
RUN go install github.com/githubnemo/CompileDaemon@latest
RUN go install github.com/go-delve/delve/cmd/dlv@latest
RUN curl -sLo /tmp/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64 && mv /tmp/aws-lambda-rie /usr/local/bin/aws-lambda-rie && chmod +x /usr/local/bin/aws-lambda-rie

WORKDIR /app

COPY ./cmd /app/cmd
COPY ./internal /app/internal
COPY ./pkg /app/pkg
COPY go.mod go.sum ./


ARG BUILD_COMMAND="go build  -C ./cmd/lambda -v -gcflags "\\all=-N-l\\" -o /var/task/main"

## HOT RELOAD

FROM base as hotreload

CMD CompileDaemon -log-prefix=false -build="$BUILD_COMMAND" -build-dir="/app" -command="/usr/local/bin/aws-lambda-rie /var/task/main"

FROM base as build

# ENV CGO_ENABLED=0
RUN $BUILD_COMMAND

## DEBUG - WIP
FROM base as debug

COPY --from=build /var/task/main /var/task/main

CMD dlv --listen=:4000 --headless=true --api-version=2 --accept-multiclient exec /usr/local/bin/aws-lambda-rie /var/task/main

FROM debug as servermode

ENV _LAMBDA_SERVER_PORT=8081

RUN apk add socat
CMD socat TCP-LISTEN:9000,fork TCP:127.0.0.1:${_LAMBDA_SERVER_PORT} & /var/task/main

# CMD dlv --listen=:4000 --headless=true --api-version=2 --accept-multiclient exec /var/task/main
# CMD ["dlv", "dap", "--listen=0.0.0.0:2345", "--log"]
