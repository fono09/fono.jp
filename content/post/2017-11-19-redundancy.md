---
date: 2017-11-19T03:00:00Z
title: 自宅バックアップ回線を引いた話
url: /2017/11/19/redundancy/
---

# 問題
大学から自宅が地味に遠い(チャリで本気で飛ばして7分)
何らかの原因で自宅ルータの設定ミスした時、帰るのダルい

# 解決手法
契約しているMVNOのSIMを追加発行、docomo L-03Dに刺してバックアップ回線とする。
当該回線はCGN配下なのでグローバル疎通を取れない。
GoogleCloudPlatformのComputeEngineまでVPNを張り、そこで固定IPをもらう。

NGN系統が落ちた時は、GoogleCloudPlatformのインスタンスにSoftEther貼って復旧。  
モバイル系統が落ちた時は、NGN系統使っていつもどおり復旧。

あーんしん！

# 設定例

## GCP側
1. Compute Engineで最小インスタンスを立てる
2. VPCネットワークの外部IPアドレスで固定IPをもらう
3. ファイアウォールルールでallow-ipsecルールを作成 udp:500,1701,4500 を開放
4. SoftEther入れて動かす
5. `vpncmd`使ってアカウント追加したり`EtherIP`周りのコマンドでつなげるようにする
(gcloudコマンドに慣れていないのは内緒)

vpncmd例
```
vpncmd /server GCP\_ADDR
> Hub DEFAULT
> AccountCreate
> AccountPasswordSet
> IPsecEnable
> EtherIPClientAdd
```
ここらのコマンドでアカウント作成から、PSKとかikeのlocal nameとかが全部設定できる。

## RTX810側
モバイル設定の追加  
APNととか`auth myname`とかはMVNOの設定とかに書いてあるのでそこを参考に設定。
```
+ ip wan1 address dhcp
+ wan1 bind usb1
+ wan1 always-on on
+ wan1 auth myname XXXX@XXXX.tld XXXX 
+ wan1 auto connect on
+ wan1 disconnect time off
+ wan1 access-point name XXXX.tld
+ wan1 access limit duration 604800
+ wan1 access limit length 1000000000
+ wan1 access limit time off
+ mobile use usb1 on
```

ルーティングでGCP側へはモバイル回線経由で行くように設定
```
+ ip route GCP\_ADDR gateway dhcp wan1
```

SoftEther周りのトンネリング設定(非固定IP/NAT配下で動作)
```
+ tunnel select 2
+ tunnel encapsulation l2tpv3
+ tunnel endpoint address GCP\_ADDR
+ ipsec tunnel 101
+  ipsec sa policy 101 1 esp aes-cbc sha-hmac
+  ipsec ike duration ipsec-sa 1 691200 rekey 90%
+  ipsec ike duration isakmp-sa 1 691200 rekey 90%
+  ipsec ike keepalive use 1 on dpd 10 6 0
+  ipsec ike local name 1 YAMAHA\_RTX810 fqdn
+  ipsec ike nat-traversal 1 on keepalive=30 force=off
+  ipsec ike pre-shared-key 1 text PSK
+  ipsec ike remote address 1 GCP\_ADDR
+  ipsec ike restrict-dangling-sa 1 off
+ l2tp always-on on
+ l2tp tunnel disconnect time off
+ l2tp keepalive use on 5 10
+ l2tp remote end-id PSK
+ tunnel enable 2
+ bridge member bridge1 lan1 tunnel2
```

# 参考URL
* [YAMAHA RTX シリーズからの L2TPv3 を用いた VPN 接続方法 (IPv4, IPv6 対応) - SoftEther VPN プロジェクト](https://ja.softether.org/4-docs/2-howto/Other_VPN_Appliance_Setup_Guide/9-yamaha-rtx-l2tpv3)
* [6. コマンドライン管理ユーティリティマニュアル - SoftEther VPN プロジェクト](https://ja.softether.org/4-docs/1-manual/6)
* [IPsec 設定例集](http://www.rtpro.yamaha.co.jp/RT/docs/ipsec/example.html)
