FROM elixir:1.13-alpine AS builder

ENV MIX_ENV=prod

RUN mix local.hex --force && \
  mix local.rebar --force

RUN mkdir /app
WORKDIR /app

COPY . .

RUN mix deps.get
RUN mix deps.compile
RUN mix release

FROM alpine AS runner

RUN apk update && \
  apk add --no-cache bash

RUN mkdir /app
WORKDIR /app
COPY --from=builder /app/_build/prod/rel/cardian ./

CMD [ "/app/bin/cardian", "start" ]