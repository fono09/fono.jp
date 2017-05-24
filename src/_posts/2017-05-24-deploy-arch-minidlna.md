---
layout: post
title: minidlnaを一発展開するために
date: 2017-05-24 23:52:00 +0900
---

## 今日のメニュー

minidlnaを一発展開するためにこいつを使います。
[binhex/arch-minidlna - Docker Hub](https://hub.docker.com/r/binhex/arch-minidlna/)

## 下ごしらえ

1. まずはDLNAでみたいファイルが置いてあるディレクトリに行きます。
```
% cd ~/video 
```

2. DLNAで共有したいファイルとディレクトリのパーミッションとオーナーを揃えておきます。
```
% sudo chown -R foo:foo /home/foo/video
```

3. 先程オーナーとしたユーザーのUIDとGIDを把握しておきます。
```
% id foo
uid=1000(foo) gid=1000(foo) groups=1000(foo),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),110(lxd),113(sambashare),123(lpadmin),999(docker),127(kvm),128(libvirtd),1001(libvirt)
```
「`UID`は`1000`、`GID`は`1000`ですね。覚えておきましょう」「覚えなくてもわかるんじゃないでしょうか」

4. 設定ファイルが書かれるディレクトリを作っておきます。
```
% mkdir minidlna
```

## `docker-compose.yml`を書く

下ごしらえに合わせて書きます。
`docker-compose`は再起動時の立ち上げもやってくれるので楽ちんです。

```
version: "2"
services:
        mini-dlna:
                image: binhex/arch-minidlna
                network_mode: "host"
                volumes:
                        - /home/foo/video:/media
                        - /home/foo/video/minidlna:/config
                        - /etc/localtime:/etc/localtime:ro
                environment:
                        - SCHEDULE_SCAN_DAYS=06
                        - SCHEDULE_SCAN_HOURS=02
                        - SCAN_ON_BOOT=yes
                        - UMASK=000
                        - PUID=1000
                        - PGID=1000
                restart: always
```


## 美味しくいただく

```
% docker-compose up -d
```
上記のコマンド投入でminidlnaが上がってくるので、
あとは、DLNAクライアントを使うだけです。

