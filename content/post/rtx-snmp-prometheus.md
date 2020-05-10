---
title: "PrometheusとSNMPv3とRTX810"
date: 2020-05-09T15:24:23+09:00
draft: true
---

# TL;DR
* とある使用頻度が低い拠点ルータが落ちてた
* アラートも上がらないので気付かなかった
* 会社の同僚が自宅のトラフィックのグラフとかカジュアルに貼ってきて羨ましい
* Prometheusで監視に手を付けることにした
  * [SNMP Exporter](https://github.com/prometheus/snmp_exporter)を使ってSNMP受信
  * [prometheus-webhook-snmp](https://github.com/SUSE/prometheus-webhook-snmp)を使ってSNMP Trap受信

# 動機 

* 利用頻度が低い拠点B(後述)のルータが落ちていたが気づけなかった
* 会社の同僚が自宅のトラフィックのグラフとかをカジュアルに貼ってくるので羨ましくなった
* かなり昔はLinuxサーバがルーターを兼ねていてmuninで全部取れてたが今は何も取れていない
* COVID-19のおかげで休日は悪い方向に暇を持て余しがち

# 実際の構成

* 3拠点に3つのRTX810(長野県[A], 長野県[B], 東京都[C])
* フルメッシュVPN(IPv4 over IPv6/IPsec with OSPF)
* アドレス帯域
  * A: 192.168.100.0/24
  * B: 192.168.200.0/24
  * C: 192.168.0.0/24

# 各拠点の説明

* 拠点A
	* 実家
  * fono.jpサーバー
  * ブラウジング、動画視聴などの利用
  * COVID-19の影響でおちおち行けない
* 拠点B
	* 実家から峠1つ超えたところ
  * ブラウジング、動画視聴などの利用(低頻度)
  * COVID-19の影響でおちおち行けない
* 拠点C
  * 自宅
  * 設定/オペレーションもここから
  * COVID-19の影響で1ヶ月近く引き篭もっている

# 説明用構成

* SNMP Agent
	RTX810(192.0.2.254)
* Prometheus用サーバー
	Docker on Ubuntu Server 18.04.4(192.0.2.1)

# 実装

1. RTX810のSNMP設定
1. SNMP Exporterの設定
1. Prometheusの設定
1. prometheus-webhook-snmpの設定

## RTX810(A)のSNMP設定

YAMAHAのサイトを参考に以下の設定を書く  
[SNMP](http://www.rtpro.yamaha.co.jp/RT/docs/snmp/index.html#command_common)

尚、目一杯長いパスワードを入力すると折返しなどで設定に失敗するケースがあるので注意(半日溶かした)

```
diff --git a/config/RTX810 b/config/RTX810
index 29b3aea..1e617a2 100644
--- a/config/RTX810
+++ b/config/RTX810
@@ -309,6 +309,10 @@ dns server dhcp lan2
 # SNMP configuration
 #

+snmpv3 context name foo.jp
+snmpv3 usm user 1 foo sha UWAApasswordOOOO aes128-cfb UWAAprivPasswordOOOOO
+snmpv3 host 192.0.2.1 user 1
+snmpv3 trap host 192.0.2.1 user 1
```

## SNMP Exporterの設定

[SNMP Exporter](https://github.com/prometheus/snmp_exporter)の設定は基本的に自動生成が推奨されているため、以下の手順に従う

1. SNMP Exporter Config Generatorの利用
	リポジトリ配下の`generater/`にある`SNMP Exporter Config Generator`を使って設定を生成
1. SNMP ExporterをDockerで実行

### SNMP Exporter Config Generatorの利用

#### MIBのダウンロード

`make mibs`

`generator`ディレクトリに入って、`make mibs`を行う前に以下のパッチを当てて自分用にこの差分をおいておくと今後     ExporterでYAMAHA機材のMIBを使って監視するときに困らない。

```
diff --git a/generator/Makefile b/generator/Makefile
index de897e0..8b13eed 100644
--- a/generator/Makefile
+++ b/generator/Makefile
@@ -39,6 +39,7 @@ UBNT_AIRFIBER_URL := https://www.ui.com/downloads/firmwares/airfiber5X/v4.0.5/UB
 UBNT_DL_URL       := http://dl.ubnt-ut.com/snmp
 RARITAN_URL       := http://cdn.raritan.com/download/PX/v1.5.20/PDU-MIB.txt
 INFRAPOWER_URL    := https://www.austin-hughes.com/support/software/infrapower/IPD-MIB.7z
+YAMAHA_URL                             := 'http://www.rtpro.yamaha.co.jp/RT/docs/mib/yamaha-private-mib.zip'

 .DEFAULT: all

@@ -52,7 +53,9 @@ clean:
                $(MIBDIR)/.cisco_v2 \
                $(MIBDIR)/.net-snmp \
                $(MIBDIR)/.paloalto_panos \
-               $(MIBDIR)/.synology
+               $(MIBDIR)/.synology \
+               $(MIBDIR)/yamaha \
+               $(MIBDIR)/.yamaha

 generator: *.go
        go build
@@ -100,7 +103,8 @@ mibs: mib-dir \
   $(MIBDIR)/UBNT-AirFiber-MIB \
   $(MIBDIR)/UBNT-AirMAX-MIB.txt \
   $(MIBDIR)/PDU-MIB.txt \
-  $(MIBDIR)/IPD-MIB_Q419V9.mib
+  $(MIBDIR)/IPD-MIB_Q419V9.mib \
+  $(MIBDIR)/.yamaha

 mib-dir:
        @mkdir -p -v $(MIBDIR)
@@ -238,3 +242,11 @@ $(MIBDIR)/IPD-MIB_Q419V9.mib:
        @curl $(CURL_OPTS) -o $(TMP) $(INFRAPOWER_URL)
        @7z e -o$(MIBDIR) $(TMP)
        @rm -v $(TMP)
+
+$(MIBDIR)/.yamaha:
+       $(eval TMP := $(shell mktemp))
+       @echo ">> Downloading yamaha"
+       @curl $(CURL_OPTS) -o $(TMP) $(YAMAHA_URL)
+       @unzip -j -d $(MIBDIR) $(TMP)
+       @rm -v $(TMP)
+       @touch $(MIBDIR)/.yamaha

```

#### ジェネレータの設定

設定を生成するためにMIBとにらめっこしながらwalk属性を書いていく

```
modules:
  rtx810:
    walk:
      - sysUpTime
      - interfaces
      - ifXTable
      # http://www.rtpro.yamaha.co.jp/RT/docs/mib/index.php
      #- 1.3.6.1.4.1.1182
      ## 1.3.6.1.4.1.1182.2.1 yamahaRTHardware
      - 1.3.6.1.4.1.1182.2.1.4  # yrhMemoryUtil
      - 1.3.6.1.4.1.1182.2.1.5 # yrhCpuUtil5sec
      - 1.3.6.1.4.1.1182.2.1.6 # yrhCpuUtil1min
      - 1.3.6.1.4.1.1182.2.1.7 # yrhCpuUtil5min
      - 1.3.6.1.4.1.1182.2.1.15 # yrhInboxTemperature
      - 1.3.6.1.4.1.1182.2.1.16 # yrhSystemAlerm
      ## 1.3.6.1.4.1182.2.2 yamahaRTFirmware
      - 1.3.6.1.4.1.1182.2.2.4 # yrfUptime
      - 1.3.6.1.4.1.1182.2.2.8 # yrfLoginRemote
      ## 1.3.6.1.4.1.1182.2.3 yamahaRTInterfaces
      ## 1.3.6.1.4.1.1182.2.4 yamahaRTIp
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifAlias
    overrides:
      ifAlias:
        ignore: true # Lookup metric
      ifDescr:
        ignore: true # Lookup metric
      ifName:
        ignore: true # Lookup metric
      ifType:
        type: EnumAsInfo
    version: 3
    max_repetitions: 25
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

#### ジェネレータの実行

[snmp_exporter/generator at master · prometheus/snmp_exporter](https://github.com/prometheus/snmp_exporter/tree/master/generator#docker-users)にあるとおり、ジェネレータの実行でコンテナのホスト側や作業している手元の環境を汚さないようにDockerで実行する

```
docker build -t snmp_exporter .
docker run --rm -ti \
	-v "${PWD}:/opt/" \
	snmp-generator generate
```

ジェネレータを実行した作業ディレクトリに`snmp.yml`ができる。

### SNMP ExporterをDockerで実行

Prometheus実行用のディレクトリを作り、そこにdocker-compose.ymlを配置。
Prometheusの設定はあとで書くことにして、SNMP Exporterの動作設定を書く。

`snmp.yml`もVOLUMEのパスに合わせて移動またはコピーしておく。

```
version: '2'
services:
  snmp-exporter:
    image: prom/snmp-exporter:v0.17.0
    ports:
      - "9116:9116"
    volumes:
      - $PWD/snmp-exporter/snmp.yml:/etc/snmp_exporter/snmp.yml
    restart: always
```

### SNMP Exporterの動作確認

```
docker-compose up -d snmp-exporter
curl 'http://192.0.2.1:9116/snmp?target=192.0.2.254&module=rtx810'
```

これで内容が返ってきていれば問題ない。

## Prometheusの設定

まず、実行用の`docker-compose.yml`を書く

```
  prometheus:
    image: prom/prometheus:v2.18.1
    ports:
      - "9090:9090"
    volumes:
      - $PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - $PWD/prometheus/data:/etc/prometheus/data
    restart: always
```

次に、設定を書く。
[prometheus/snmp_exporter: SNMP Exporter for Prometheus](https://github.com/prometheus/snmp_exporter#prometheus-configuration)

上記URLのPrometheus Configurationの節にあるとおり、設定を書いていく。

`target_label: __address__`の`replacement`が`snmp-exporter:9116`となっているが、
`docker-compose`を利用することでdockerのnetworkが勝手に作成されるため、名前解決はサービス名で行える。

```
scrape_configs:
  - job_name: snmp
    static_configs:
      - targets:
        - 192.0.2.254
    metrics_path: /snmp
    params:
      module: [rtx810]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116
```


## Prometheusの動作確認

```
docker-compose up -d prometheus
```

これで、`192.0.2.1:9090`にアクセスすると、PrometheusのWebUIが表示され、
`SNMP Exporter`も認識され、対象の数値が取れる状態になっている
