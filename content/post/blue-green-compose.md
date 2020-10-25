---
title: "docker-composeでBlueGreenDeployment"
date: 2020-10-25T19:28:32+09:00
tags:
  - docker
  - mastodon
---

# 免責事項
切替中にいくつかのリクエストを零している可能性があります。

# 3行でまとめるとこう
* docker-composeだけで無停止っぽいデプロイをしたい
* k8sとかそこらを手元でセットアップする気がない
* シェル芸とnginx-proxyの組み合わせでできた: [fono09/BlueGreenCompose](https://github.com/fono09/BlueGreenCompose)

# 結論
[nginx-proxy](https://github.com/nginx-proxy/nginx-proxy)とシェルスクリプト芸でできる。
nginx-proxyがDocker側でサービス検知のような挙動をしてくれるので、あとは後はそれに乗っかるだけ。

# モチベーション
自宅サーバーや個人サービスで止めたくない。加えて、がそこまでクリティカルじゃない。k8sを建てるほどスケーリングとディスカバリのメリットがない。
そういう微妙な環境でもBlueGreenDeploymentっぽいことしたい。docker-composeで全てを管理するときに使う。

だいたい、自宅の個人用マストドンの無停止アップグレード(https://ma.fono.jp/)に利用する。

# 動作

1. docker-compose.yml内でYAMLのマージを使ってサービスの名前のサフィックスが違う2つのサービスを立てる
1. dockerのhealthcheckと、ログ監視等を使ってコンテナにアクセスが来ているか確認する
1. 動作しているようなら前のを落として完全に切り替える

# 使用例

1. [fono09/BlueGreenCompose](https://github.com/fono09/BlueGreenCompose)をサブモジュールに追加
1. サブモジュール側でフォークしてこんなふうに編集
https://github.com/fono09/BlueGreenCompose/commit/b1d1ebfd7c51266dce2c8d569b6032a6158e892d
1. 編集したのをフォークとして上げて保存
https://github.com/fono09/mastodon/commit/25e21ebae7c509d0fe29855230548ed37d2b1ab8
1. `(リポジトリルート)/BlueGreenCompose/autodeploy.sh` を叩いて無停止デプロイ

# 感想

単純なので扱いやすし実際動いた。ただ、BlueGreenDeploymentっぽくはなったけれど、「動いていること」を正しく見れているとは言えない。一定時間内のログに`GET` `POST` が出現した行数、という危うい基準で切り替えている。

基本的に立てて60秒程度ではhealthcheckのアクセスしかなく、動作していた側を落とした後、アクセスが来るような挙動になってしまっている。

本来、切替先が健全であることを外部から切替先にしか行かないリクエストを投げて確認するのが一番だが、結局docker-composeとnginx-proxyでできるかどうかは怪しい。 下手すると古典的なローカルDNSによる切替に落ち着く未来が見える。
