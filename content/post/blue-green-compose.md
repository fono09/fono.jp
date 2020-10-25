---
title: "docker-composeでBlueGreenDeployment"
date: 2020-10-25T19:28:32+09:00
tags:
  - docker
  - mastodon
---

# 免責事項
切替中にいくつかのリクエストを零している可能性があります。

# TL;DR
* docker-composeだけで無停止っぽいデプロイをしたい
* k8sとかそこらを手元でセットアップする気がない
* シェル芸とnginx-proxyの組み合わせでできた: [fono09/BlueGreenCompose](https://github.com/fono09/BlueGreenCompose)
* 実際に、個人用mastodonインスタンス https://ma.fono.jp/ にこれを適用した

# 結論
[nginx-proxy](https://github.com/nginx-proxy/nginx-proxy)とシェルスクリプト芸でできる。
nginx-proxyがDocker側でサービス検知のような挙動をしてくれるので、あとは後はそれに乗っかるだけ。

# モチベーション
自宅サーバーや個人サービスで止めたくない。加えて、がそこまでクリティカルじゃない。k8sを建てるほどスケーリングとディスカバリのメリットがない。

そういう微妙な環境でもBlueGreenDeploymentっぽいことしたい。docker-composeで全てを管理するときに使う。

# 動作

1. docker-compose.yml内でYAMLのマージを使ってサービスの名前のサフィックスが違う2つのサービスを立てる
1. dockerのhealthcheckと、ログ監視等を使ってコンテナにアクセスが来ているか確認する
1. 動作しているようなら前のを落として完全に切り替える

# 感想

単純なので扱いやすし実際動いた。ただ、BlueGreenDeploymentっぽくはなったけれど、「動いていること」を正しく見れているとは言えない。一定時間内のログに`GET` `POST` が出現した行数、という危うい基準で切り替えている。

基本的に立てて60秒程度ではhealthcheckのアクセスしかなく、動作していた側を落とした後、アクセスが来るような挙動になってしまっている。

本来、切替先が健全であることを外部から切替先にしか行かないリクエストを投げて確認するのが一番だが、結局docker-composeとnginx-proxyでできるかどうかは怪しい。 下手すると古典的なローカルDNSによる切替に落ち着く未来が見える。
