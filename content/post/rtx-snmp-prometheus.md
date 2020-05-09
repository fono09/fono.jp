---
title: "PrometheusとSNMPv3とSNMP Trap"
date: 2020-05-09T15:24:23+09:00
draft: true
---

# TL;DR
* とある使用頻度が低い拠点ルータが落ちてた
* アラートも上がらないので気付かなかった
* 会社の同僚が自宅のトラフィックのグラフとかカジュアルに貼ってきて羨ましい
* Prometheusで監視した
  * [SNMP Exporter](https://github.com/prometheus/snmp_exporter)を使ってSNMP受信
  * [prometheus-webhook-snmp](https://github.com/SUSE/prometheus-webhook-snmp)を使ってSNMP Trap受信

# 動機 

* 使用頻度が低い拠点B(後述)のルータが落ちていたが気づけなかった
* 会社の同僚が自宅のトラフィックのグラフとかをカジュアルに貼ってくるので羨ましくなった
* かなり昔はLinuxサーバがルーターを兼ねていてmuninで全部取れてたが最近はなにもしていない
* 監視したくなった

# 構成

* 3拠点に3つのRTX810(長野県[A], 長野県[B], 東京都[C])
* フルメッシュVPN(IPv4 over IPv6/IPsec with OSPF)
* アドレス帯域
  * A: 192.168.100.0/24
  * B: 192.168.200.0/24
  * C: 192.168.0.0/24

# 各拠点の説明

* 拠点A
  * fono.jpサーバー
  * ブラウジング、動画視聴などの利用
  * COVID-19の影響でおちおち行けない
* 拠点B
  * 低頻度
  * ブラウジング、動画視聴などの利用
  * COVID-19の影響でおちおち行けない
* 拠点C
  * 自宅
  * 設定/オペレーションもここから
  * COVID-19の影響で1ヶ月近く引き篭もっている

# 実装

1. RTX810(A)のSNMP設定
1. Prometheusの設定
1. SNMP Exporterの設定
1. 動作確認
1. RTX810 x2 のSNMP設定
1. 動作確認
1. RTX810 x3 のSNMPTrapのセットアップ
1. prometheus-webhook-snmpのセットアップ
1. 勝利

## RTX810(A)のSNMP設定

YAMAHAのサイトを参考に以下の設定を書く  
[SNMP](http://www.rtpro.yamaha.co.jp/RT/docs/snmp/index.html#command_common)

`snmpv3 usm user 1 foo sha UWAApasswordOOOO` について、暗号化の設定にかかるパラメータは設定ファイルに保存されないし、しないほうが好ましいとも思う。実際は、`snmpv3 usm user 1 foo sha UWAApasswordOOOO aes128-cfb UWAAAprivPasswordOOOO` と入力している

```
diff --git a/config/RTX810 b/config/RTX810
index 29b3aea..1e617a2 100644
--- a/config/RTX810
+++ b/config/RTX810
@@ -309,6 +309,11 @@ dns server dhcp lan2
 # SNMP configuration
 #

+snmpv3 engine id rtx810
+snmpv3 context name foo.jp
+snmpv3 usm user 1 foo sha UWAApasswordOOOO
+snmpv3 trap host 192.0.2.0 user 1
+snmp sysname rtx810
```

## Prometheusの設定

`docker-compose.yml`を書く
```
version: '2'
services:
  prometheus:
    image: prom/prometheus:v2.18.1
    ports:
      - "9090:9090"
    volumes:
      - $PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - $PWD/prometheus/data:/etc/prometheus/data
    restart: always
```


## SNMP Exporterの設定

設定を生成するためにMIBとにらめっこしながらwalk属性を書いていく
```
modules:
  yamaha_rt:
    version: 3
    max-repetitions: 25
    retries: 3
    timeout: 10s
    auth:
      username: foo
      security_level: authPriv
      password: "UWAApasswordOOOO"
      auth_protocol: SHA
      priv_protocol: AES
      priv_password: "UWAAAprivPasswordOOOO"
      context_name: foo.jp
```
