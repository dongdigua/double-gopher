FROM alpine AS buildtime

ENV VERSION '3.1.1'
WORKDIR /build

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
RUN apk --no-cache add -t build-deps build-base gcc abuild binutils make
RUN curl -sLO https://github.com/gophernicus/gophernicus/releases/download/${VERSION}/gophernicus-${VERSION}.tar.gz && \
    tar xf "gophernicus-${VERSION}.tar.gz" && \
    cd gophernicus-${VERSION}/ && ./configure --listener=inetd --prefix=/ && make && mkdir -p /build/artifacts && \
    mv src/gophernicus gophermap.sample /build/artifacts && rm -rf /build/gophernicus*



FROM alpine
# debian don't have frp (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1030841)

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
COPY --from=buildtime /build/artifacts/gophernicus /usr/local/bin/gophernicus
RUN apk --no-cache add frp busybox-extras nc-openbsd

COPY inetd.conf        /etc/
COPY *.sh              /
COPY gophermap         /var/gopher/

CMD inetd -fe
