---
title: "Jekyll to hugoしたサイトはhugoアップデートで死ぬ"
date: 2019-09-18T06:46:04+09:00
tags:
  - hugo
  - Jekyll
categories:
  - 技術
---

## どうして

`Jekyll`から移行を行うとブランクの`content/index.md`が配置されるため。

Jekyllからhugoに[fredrikloch/JekyllToHugo: Small script for converting jekyll blog posts to a hugo site](https://github.com/fredrikloch/JekyllToHugo)を使って移行すると、`index.md`が自動生成される。
そして、hugoの特定バージョンからは`content/index.md`がある状態でレンダリングするとすべての投稿を無視してトップページのみレンダリングされる現象が発生する。

参考: [fono.jp/index.md at 251809e97e98e1171728cdeff7714f87fcf98122 · fono09/fono.jp](https://github.com/fono09/fono.jp/blob/251809e97e98e1171728cdeff7714f87fcf98122/content/index.md)

## ハマりポイント

設定とテーマを疑ってしまい、`index.md`だとは自力で気づけなかった。
テーマでは対策済みの[Pagination | Hugo](https://gohugo.io/templates/pagination/)の仕様変更も疑って更に時間を空費した。

バージョンアップを忘れて、久々にテーマと本体の更新を行うと死ぬという現象なので、`content` フォルダを疑わないという認知バイアスがかかった。
視野狭窄マンなのでエンジニア向いてないのかも知れない。

もし、`index.md`を疑ったとしても、ファイルのコメントで「自動生成だから触(らなくていいよ|るなよ)」と書いてあるからより凶悪。

## 経緯

経緯は以下の通り

1. GithubのWebhook使ってオンプレで自動デプロイしたくなる
1. hugoの最新バイナリを落としてくるようにしたため今回の現象が発生して一旦中断
1. メンテナンスが不足していたのでメンテナンスする気になる
1. テーマをバージョンアップする(自前フォークだったので最新追従)
1. テーマ指定のhugoのバージョンが上がっているのでhugoバージョンアップ
1. トップページ以外投稿も含めてレンダリングされなくなる
1. `config.toml` を疑う
1. テーマを差し替える
1. テーマを元に戻す
1. 今の手元クローンを削除して新規にクローンする
1. hugoとテーマのバージョンを下げる
1. 諦める
1. Candle氏に依頼して3連休を過ごす
1. `index.md` が原因だと判明する

## ソースコード読めよ

わかる。だが、2日以上溶かして趣味プロダクトかつ、踏み抜いているのは自分だけとなると熱量失せる。

## 謝辞

[蝋燭(Candle Doe)（@candle1388）さん / Twitter](https://twitter.com/candle1388)
助かりました。認知バイアス下では頼める他人が一番です。ありがとうございました。
