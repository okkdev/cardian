FROM hexpm/elixir:1.19-erlang-28.1-alpine-3.22.2 AS builder

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
RUN mix sentry.package_source_code
RUN mix release

FROM alpine:3.22 AS runner

RUN apk update && \
  apk add --no-cache bash libstdc++ openssl ncurses-libs

RUN mkdir /app
WORKDIR /app
COPY --from=builder /app/_build/prod/rel/cardian ./

CMD [ "/app/bin/cardian", "start" ]
