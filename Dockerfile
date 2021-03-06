FROM alpine:3.8 AS build
RUN apk add --no-cache cabal ghc gmp-dev musl-dev wget zlib-dev
RUN cabal update
RUN cabal new-install hpack
WORKDIR /root/rattletrap
COPY . .
RUN ~/.cabal/bin/hpack --force
RUN cabal new-build --flags static
RUN cp $( cabal new-exec which rattletrap | tail -n 1 ) /usr/local/bin/

FROM alpine:3.8
COPY --from=build /usr/local/bin/rattletrap /usr/local/bin/rattletrap
CMD rattletrap
