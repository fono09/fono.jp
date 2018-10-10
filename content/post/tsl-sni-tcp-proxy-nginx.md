---
title: "nginxをTSL-SNI対応TCPプロキシとして使う"
date: 2018-10-10T06:22:59Z
---

以下の作業を実施．

SoftetherとTLS-SNIなバーチャルホストを同居させる設定を行った．

もっと丁寧な記事だったが，RAID1の`/var/www/`が私のミスで消し飛んだ上にこの記事はバックアップされていなかったのでこのようなものになった．

何卒ご了承いただきたい．

```
# apt install libpcre3-dev libssl-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev libgeoip-dev nginx #必要ライブラリのインストール
# nginx -V #configureオプションを確認
# apt purge nginx && apt autoremove #用済み
% ./configure --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-QTAlz1/nginx-1.14.0=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream --with-stream_ssl_preread_module --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module #--with_streamの=dynamicを削除, --with-stream_ssl_preread_moduleを追加
% make
# make install
# ln -s /usr/share/nginx/sbin/nginx /usr/sbin/nginx #デフォルトの場所にシンボリックリンクを置く
# cat > /lib/systemd/system/nginx.service
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
# systemctl unmask nginx
# systemctl enable nginx
# sed -e 's/443/8443/g' /etc/nginx/site-available/* # 全てのバーチャルホストのListenポートを8443に
# diff /etc/nginx/nginx.conf nginx.conf.before
11,14d10
< stream {
<     include /etc/nginx/stream.conf.d/*.conf;
< }
< 
# mkdir /etc/nginx/stream.conf.d # 設定用ディレクトリを作成
# cat > /etc/nginx/stream.conf.d/vpn.foo.bar
map $ssl_preread_server_name $name {
    vpn.foo.bar softether;
    default normal_https;
}

upstream normal_https {
    server localhost:8443;
}

upstream softether {
    server localhost:1194;
}
# ほとんどこのため

log_format stream_routing '$remote_addr [$time_local] '
    'with SNI name "$ssl_preread_server_name" '
    'proxying to "$name" '
    '$protocol $status $bytes_sent $bytes_received '
    '$session_time';


server {
    listen 443;
    listen [::]:443;
    proxy_pass $name;
    ssl_preread on;
    access_log  /var/log/nginx/access_stream_log.log stream_routing;
}
# nginx -t #確認して良ければ
# systemctl start nginx #後はお幸せに
```

