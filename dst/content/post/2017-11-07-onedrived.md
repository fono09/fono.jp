---
date: 2017-11-07T09:30:00Z
title: onedrivedのセットアップ
url: /2017/11/07/onedrived/
---

# 要求
LinuxでOneDrive使いたい。既存の実装は複数あるが、有名なものとしてはonedrivedがある。
こいつがリンク切れしてるとかいう人もいるけど、ちゃんと生きているし、インタラクティブな設定の出来も非常に良いので利用する

# 前提条件
* gcc
* python3-dev
* libssl-dev
* inotify-tools
* python3-dbus / libdbus-glib1-dev

# 手順
1. `$ sudo apt install build-essential python3-dev libssl-dev inotify-tools python3-dbus libdbus-glib-1-dev`
まずこれを実行して前提条件を満たす
1. `$ pip3 install --user git+https://github.com/xybu/onedrived-dev.git`
作者のGithubからもらってくる
1. `$ pip3 install keyrings.alt`
このまま利用すると、アカウント追加時に以下のようなキーリングに関する警告が出てコケるので、`keyrings.alt`パッケージを入れて対処しておく
`Failed to save account: No recommended backend was available. Install the keyrings.alt package if you want to use the non-recommended backends. See README.rst for details..`
1. `$ which ngrok`
デフォルトでngrokに依存しているので、公式へ貰いに行った後、
PATHを通すか起動時に`$NGROK`にngrok本体までのパスを渡すこと
ngrokに関しては参考URLで
1. `$ onedrived-pref account add`
ここで出たアドレスに飛んで、出たアドレスを貼るとログイン完了
`Successfully added account for XXXXXXX(XXX@XXXX.jp)!` こんなのが出る
1. `$ onedrived-pref drive set`
アカウントに対応するフォルダをインタラクティブに設定
1. `$ onedrived start`
直後、`$ onedrived status`見て死んでるようなら`--debug`とか付けて監視
大体`ngrok`とか`pyenv`系の問題でコケるのでセットアップ環境には注意

# Todo

必要な環境変数とかpyenvとsystemdとかをうまい具合にして自動的に立ち上げる。

# 参考URL
* [xybu/onedrived-dev: A Microsoft OneDrive client for Linux, written in Python3.](https://github.com/xybu/onedrived-dev)
* [ngrok - secure introspectable tunnels to localhost](https://ngrok.com/)
