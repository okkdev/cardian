FROM elixir:1.14-otp-25-alpine AS builder

ENV MIX_ENV=prod

RUN apk update && \
  apk add --no-cache git

RUN mix local.hex --force && \
  mix local.rebar --force

RUN mkdir /app
WORKDIR /app

COPY . .

RUN mix deps.get
RUN mix deps.compile
RUN mix release

FROM alpine:3.16 AS runner

RUN apk update && \
  apk add --no-cache bash libstdc++ openssl ncurses-libs

RUN mkdir /app
WORKDIR /app
COPY --from=builder /app/_build/prod/rel/cardian ./

CMD [ "/app/bin/cardian", "start" ]
