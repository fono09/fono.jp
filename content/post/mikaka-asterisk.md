---
title: "某有名VoIPネットワークの話"
date: 2018-12-08T00:00:00+09:00
---

# 挨拶


最近冷え込みますね．私は，11月25日を最後にバイクを寝かせてしまいました．
しかし，ここ最近まで市街地の道は全くドライな状態で，
つい先日行った，実家への帰省もバイクで走りたいような路面でした．

どうやら今年は暖冬のようです．でも寒いです．
今日の天気予報は雨まじりの雪になっています．

そんなことはどうでもよくって，私はこの記事を
信州大学 kstm Advent Calendar 2018，8日目の記事として書きました．

[信州大学 kstm Advent Calendar 2018 - Qiita](https://qiita.com/advent-calendar/2018/kstm)


# 免責事項

責任が伴う箇所やミッションクリティカルな箇所での利用は想定していませんので，いろいろと設定漏れがあったりするかもしれません．
この設定を実運用に用いられた場合の保証は一切致しませんので，その点ご注意ください．

また，同様の環境での安定稼働ならば，[Asterisk FreeSWITCH対応 ひかり電話ゲートウェイiGW-N01](http://www.iweave.jp/iGW-N01/)などもあり，そちらのほうが安定しています．

# 背景

こんな寒い日が続くならば，玄関から一歩も出ずに，暖房をかけるかあるいはコタツに潜り込むなどして，
一日中端末に向かって，進捗を生み出すなり，ゲームするなり，SNSに入り浸る等して，過ごすのが良さそうです．

しかし，現実は非情であって，家から出なければならない用事は山ほどあります．
人間は社会性を持たなければならないのです．

家を出ると，当然ながら，自宅警備が疎かになって多大なデメリットを背負うことになるます．具体的には以下のように．

1. 宅配便を受け取れない
2. 自作PCに代表される自宅インフラが使えない
3. 固定電話に出られない

いずれも，技術によって対処が可能な時代になってきました．

1は宅配ボックス等によって
2はVPCやVPN等によって．
3に関しては，今回紹介するもので対処しようという話です．

具体的には，[asterisk][] とVPNの合わせ技を使うことで，スマートフォン等をつかって，
どこでもお家の電話に出られるようにしようという話です．

VPNに関しては，[SoftEther][]を使っているので，接続性に関してはあまり問題はありません．
[SoftEther][]が`TCP/443`を塞いで邪魔だとかいう人は下記のページが参考になると思います．

* [nginxをTSL-SNI対応TCPプロキシとして使う](https://fono.jp/post/tsl-sni-tcp-proxy-nginx/)
* [inconshreveable/slt: A TLS reverse proxy with SNI multiplexing in Go](https://github.com/inconshreveable/slt)

# asteriskってなんぞや

[asterisk][] 公式によると

> Asterisk is a free and open source framework for building communications applications and is sponsored by Digium.

翻訳すると

> アスタリスクは，無料でオープンソースなコミュニケーションアプリケーション作成フレームワークで，Digiumによってスポンサーされています．

だそうです．

今回はこいつのSIPサーバ/プロキシの機能を使います．

日本語での情報は [VoIP-Info.jp][] が参考になりますが，最新の[asterisk][]に対応するには
公式ドキュメントの読み込みか，英語情報の[Voip-info.org][]が参考になります．


# 某有名VoIPネットワークって何？

R&Dな部署に所属していたと思われる方々の退職エントリが相次いで話題になってしまっている会社
と同じグループの会社が保有する，アナログ電話回線を置き換えるっぽいSIPサーバ網のことです．

# 実装の解析

某SIPサーバにぶら下がるためONU直下から専用端末との間で通信を傍受できる環境を用意して，パケットキャプチャを実施しました．
その結果を解析したところ以下のシーケンス図の通りとなりました．

<div class="mermaid">
sequenceDiagram
    participant Client
    participant DHCP_Server
    participant SIP_Server
    Client->>DHCP_Server: DHCP Discover
    DHCP_Server-->Client: DHCP Offer
    Client->>DHCP_Server: DHCP Request
    DHCP_Server-->Client: DHCP ACK
    Client->>SIP_Server: SIP Requet REGISTER
    SIP_Server-->Client: SIP Status: 200 OK
</div>

どうやら，挙動を見ていると，
DHCPで特徴的なオプションを要求したり拾わなくても，
連動してSIPサーバが利用できなくなるということはないようです．

このオプションの中で特徴的なものを挙げていきますが，
これからの設定に利用するので，メモっておくと捗ります．

## DHCP Request

括弧内はオプションコードです

* (55) ParameterRequestList
    欲しいパラメータのうち
    * (120) SIP Serveres
        確かにSIPにつなぐなら欲しい
    * (124) V-I Vendor-specific Information
* (124) V-I Vendor Class (メーカー名を名乗っている / 機器認証に必要?)

## DHCP ACK

* (120) SIP Servers
* (125) V-I Vendor-specific Information
    * (202) 電話番号
    * (204) SIPのrealm
    * (210) 専用機器のバージョン情報取得先？

## SIP REGISTER

`Allow` ヘッダに `OPTIONS` がない
```
Allow: ACK, BYE, CANCEL, INVITE, PRACK, UPDATE
```
この通りです．


尚，SIPの元になった[RFC3261][]にはこうあります．

> All UAs MUST support the OPTIONS method.

`OPTIONS` メソッドは互いの端末の機能/能力確認に使われます．

こういったプロトコルの仕様が機器の適合認証などの煩雑な作業を回避し，
プロバイダは規格に従ってサービス提供と認証などに徹するようにできると思うのですが，
どうしてこうなったのかはわかりません．

某有名VoIPネットワークの中の人などからコメントを頂けると楽しいと思います．

# 実装/設定

以上の点を考慮しながら，設定を行っていきます．

## DHCP

まず，DHCPクライアントには特殊なオプションを加えなくても，
取得済みの情報で動作することが確認できていますので，通常のDHCPクライアントを利用します．

先程の通信を傍受したインターフェイスで既存の機器を取り外し，以下のコマンドでIPv4アドレスをもらいます．

`# dhclient $IFACE_NAME`


## Asterisk

AsteriskのセットアップはDockerを用い，以降は設定ファイル毎に説明していきます．
`$(variable)`は先程メモしたDHCPオプションなりに読み替えてください．

### docker-compose.yml

特徴的な項目としては，`extera_hosts`で SIPサーバのIPv4アドレスとドメイン名を解決可能している点があります．
これを行わないと希望した名前で問い合わせられません．

```
asterisk:
    image: andrius/asterisk:latest
    network_mode: "host"
    privileged: true
    extra_hosts:
        - "$(DHCP ACK 125 204):$(DHCP ACK 120)"
    volumes:
        - ${PWD}/asterisk/sip.conf:/etc/asterisk/sip.conf
        - ${PWD}/asterisk/extensions.conf:/etc/asterisk/extensions.conf
    command:
         - asterisk
         - -cvvvvv
     logging:
         options:
             max-size: '10m'
             max-file: '10'
         driver: json-file
```

### asterisk/sip.conf

特徴的な項目としては，

* `realm`をDHCPで取得したものに設定
* `register`を行う先の`realm`も同様  
SIPプロキシとサーバーが同じ`realm`になるのでやや混乱します．

* ピア`mikaka-gw`ついて`qualify=no`  
`OPTIONS`リクエストを無効化にして，`Method Not Allowed`が返ってくるのを防止します．
この設定を行わないといつまで経っても接続できません．

```
[general]

context=public
allowoverlap=no
realm=$(DHCP ACK 125 204)
tcpenable=no
transport=udp
srvlookup=yes

register => $(DHCP ACK 125 210)@$(DHCP ACK 125 204)/$(DHCP ACK 125 210)

[authentication]

[basic-options](!)
dtmfmode=rfc2833
context=from-office
type=friend
[natted-phone](!,basic-options)
directmedia=no
host=dynamic
[public-phone](!,basic-options)
directmedia=yes
[my-codecs](!)
disallow=all
allow=ilbc
allow=g729
allow=gsm
allow=g723
allow=ulaw
[ulaw-phone](!)
disallow=all
allow=ulaw


[mikaka-gw]
type=peer
host=$(DHCP ACK 120)
context=from_mikaka
disallow=all
allow=ulaw
directmedia=no
dtmfmode=inband
qualify=no

[801]
context=from_phone
secret=$(YOUR SECRET)
host=dynamic
dtmfmode=rfc2833
```

### asterisk/extensions.conf

とくに特徴的な項目はありません．
[asterisk][]の `extension.conf` は癖っぽいので，[VoIP-Info.jp][]の[Extension道場 - VoIP-Info.jp](https://voip-info.jp/index.php/Extension%E9%81%93%E5%A0%B4)なども参考になるでしょう．

実際，私も下手な英語でコミュニティに質問に行ったりしました．
[[Solved] CLI output and operation are different - Asterisk / Asterisk Dialplan - Asterisk Community](https://community.asterisk.org/t/solved-cli-output-and-operation-are-different/77263)

```
[from_mikaka]
exten => _X.,1,Dial(SIP/801)

[from_phone]
exten => _80Z,1,Dial(SIP/${EXTEN})
exten => _0.,1,Set(CALLERID(num)=$(DHCP ACK 125 202))
same => n,Dial(SIP/mikaka-gw/${EXTEN})
```

# 動作確認

Windowsならば[MicroSIP][]，Androidならば[CSipSimple][]が確認に使えます．
実家にVPNが張ってあったりするようならば，自宅の電話を自分で受けれなかった場合，
実家の人のスマートフォンが鳴るようにして取らせる，などといった事もできます．

尚，自宅から携帯に発信し，通話が行えました．
![](/assets/mikaka-asterisk.jpg)

では皆さん，良い[asterisk][]ライフを！



[SoftEther]: https://www.softether.jp/
[asterisk]: https://www.asterisk.org/
[VoIP-Info.jp]: https://voip-info.jp/
[Voip-info.org]: https://www.voip-info.org/asterisk/
[RFC3261]: https://tools.ietf.org/html/rfc3261
[MicroSIP]: https://www.microsip.org/
[CSipSimple]: https://code.google.com/archive/p/csipsimple/

