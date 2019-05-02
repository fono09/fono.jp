---
title: "NAT64/DNS64で遊んだ"
date: 2019-05-03T01:23:36+09:00
---

# TL;DR

* Cat6成端のスキルを失ってしまったのでケーブルを買った
* Ubuntu18.04(Hyper-V)の上でjoolとunboundを使ってNAT64/DNS64を構築した
* ちょっとした設定でWindowsから実際に利用できた
* 一部のアプリはオフライン判定になって壊れる

以下、`$HOGE`と`%HOGE%`は環境に合わせて置換すること。

# NAT64/DNS64とは

IPv6のみのネットワークからIPv4にアクセスするための技術。
詳細は[JPNICニュースレター**No.64**](https://www.nic.ad.jp/ja/newsletter/No64/0800.html)が詳しいのでそちらに譲る。

# Ubuntu18.04 on Hyper-Vのセットアップ

まず、IPv4/6の疎通を得るためにはデフォルトの仮想スイッチのNATが使えないので、別のイーサネットインターフェイスにぶら下がる形にする。

1. 「Hyper-Vマネージャー」
1. 右側の「操作」から「仮想スイッチマネージャー」
1. 「新しい仮想ネットワークスイッチ」
1. 「外部」
1. 「接続の種類」>「外部ネットワーク」からお好みのインターフェイスを選択<F11>

以上の手順でスイッチ作成はあっさり終了。

インターフェイスを使うのに、自宅のメインスイッチから手元端末に配線を行う必要があった。
Cat6ケーブルの成端をしてサクっとケーブルを作るつもりだったが、いささか高いCat6口金を6個費やしてまともなケーブルができなかった。
やむを得ず、通常のケーブルを購入した。箱で残ってるケーブルの行く末が思いやられる。

## Hyper-V仮想スイッチとトランクポートに関する注意点

Hyper-VでVLANを利用する場合、仮想スイッチにバインディングされたインターフェイスの対向をトランクポートとしても、Hyper-V側のゲストではVIDを指定してインターフェイスを作るしかない。
VID未指定にしてもトランクポートにはならず、ネイティブVLANとの疎通となる。

# 事前のカーネル設定

NATするので下記の設定は必須
```
# sysctl -w net.ipv4.conf.all.forwarding=1
# sysctl -w net.ipv6.conf.all.forwarding=1
```
また、IPv6/v4アドレスを固定

# Joolのインストールとセットアップ

Joolのインストールは[Download](https://www.jool.mx/en/download.html)へ行き、Version 4.0.1のアドレスをコピー、wgetで端末に落とした。
インストール方法は公式の[Installation](https://www.jool.mx/en/install.html)を読むと良い。
コマンドにまとめると下記の通り。

```
# apt install build-essential pkg-config linux-headers-$(uname -r) libnl-genl-3-dev libxtables-dev dkms
% tar zxvf jool_4.0.1.tar.gz
# dkms install jool-4.0.1
```

設定も同じく、公式の[Stateful NAT64 Run](https://www.jool.mx/en/run-nat64.html)が易しい。 
コマンドにまとめると下記の通り。

```
# modprobe jool
# jool instance add $INSTNACE_NAME --iptables --pool6 64:ff9b::/96
# ip6tables -t mangle -A PREROUTING -d 64:ff9b::/96 -j JOOL --instance $INSTNACE_NAME
# iptables -t mangle -A PREROUTING -d $NAT64_GW_V4_ADDR -p tcp --dport 61001:65535 -j JOOL --instance $INSTANCE_NAME
# iptables -t mangle -A PREROUTING -d $NAT64_GW_V4_ADDR -p udp --dport 61001:65535 -j JOOL --instance $INSTANCE_NAME
# iptables -t mangle -A PREROUTING -d $NAT64_GW_V4_ADDR -p icmp -j JOOL --instance $INSTANCE_NAME
```

NAT64のIPv6のプレフィクス`64:ff9b`以下にIPv4アドレスを埋め込むのでプレフィクス長は`128-32 = 96`となる。

# 試しにNAT64を使う

Windows側で行う設定は下記の通り。管理権限のPowerShellで行う。
この段階ではまだIPv4を無効化する必要はない。

```
PS > route add 64:ff9b::/96 %NAT64_GW_V6_ADDR%
```

NAT64のプレフィクスが付いたものはすべて先程作成したホストに吸い込まれる。

この設定の後、アドレスバーに`http://[64:ff9b::192.168.0.254]`等と打ち込むと、Jool経由でIPv4疎通を得られたことが分かる。

# unboundのセットアップ

```
# apt install unbound
# cat > /etc/unbound/unbound.conf.d/dns64.conf
server:
  module-config: "dns64 iterator"
  dns64-prefix: 64:ff9b::/96
  dns64-synthall: no
  interface: ::0
  access-control: $NAT64_GW_V6_PREFIX allow

forward-zone:
  name: "."
  forward-addr: 1.1.1.1
# systemctl restart unbound
```

セットアップしたら、上記の設定を行う。
なお、`dns64-synthall`を`yes`にすると、たとえ`AAAA`があっても`NAT64`のアドレスを返す。

# DNS64のチェック

```
% dig +short AAAA twitter.com $NAT64_GW_V6_ADDR
64:ff9b::68f4:2a01
64:ff9b::68f4:2a41
```

上記のように、`64:ff9b::`から始まる返答が得られれば成功。

# DNS64の利用

WindowsのネットワークアダプタのIPv6設定からネームサーバとして当該のNAT64/DNS64のIPv6アドレスを設定し、
IPv4を無効化した状態で、`twitter.com`にアクセスできれば成功。

# 不安定になるアプリ

NAT64経由の疎通をデフォルトとして設定すると以下のような不調が発生する。
DNS64経由のIPv4疎通はどうやら、IPv4疎通と判定されないのが原因かと思われる。

* Windowsの右下で「イーサネット / インターネットなし」となる
* Spotifyはインターネット疎通なしと判断される

# まとめ

* Jool/unboundによるNAT64/DNS64は容易に構築できる
* Windows側での対応は不十分な可能性がある

