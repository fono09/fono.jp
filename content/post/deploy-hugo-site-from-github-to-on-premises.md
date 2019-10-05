---
title: "HugoサイトをGihubリポジトリからオンプレへデプロイする"
date: 2019-10-05T16:54:06+09:00
tags:
  - Hugo
  - Github
  - Linux
---

# 概要

[fono09/hugo-deploy-on-premises: Githubに置いたHugoをオンプレにデプロイしてくれるやつ](https://github.com/fono09/hugo-deploy-on-premises)

こいつを作って、設定して、この記事を自動デプロイした。

# どうして

このサイトをより手軽に更新したかった。要するに、更新時には毎回サーバーに入って毎回`git pull`、`hugo`を打つのは面倒。

また、 自宅サーバーで`hugo server`記事をプレビューしながら書くときに、VPNで自宅に繋いだ手元端末からプレビューが見れるよう、わざとバインドアドレスを設定しなければならない。
e.g.`hugo server -D --bind 192.168.0.222`

# 解決法

実際の動きを以下のシーケンス図で示す。
要するにGithubのWebhookで`git pull`して`hugo`動かして

* `workstation`: 手元端末
* `Github`: 謎の設計図共有サイト
* `nginx`: 謎のウェブサイト高速配信システム
* `deploy`: 今回作ったやつ
* `hugo`: 謎のウェブサイト高速生成システム

<div class="mermaid">
sequenceDiagram
    participant workstation
    participant Github
    participant nginx
    participant deploy
    participant hugo
    workstation->>Github: git push
    Github-->workstation: pushed
    Github->>nginx: HTTP Post(Webhook)
    nginx->>deploy: HTTP Post(Webhook)
    deploy->>Github: git pull
    Github-->deploy: contents
    deploy->>Github: git submodule update --init --recursive
    Github-->deloy: submodules(theme)
    deploy->>hugo: render
    hugo-->deploy: rendered
    workstation->>nginx: HTTP Get
    nginx-->workstation: contents
</div>

これでリモートからpushしても自動でデプロイされます。

# ハマりポイント

## Githubの多要素認証でもデプロイしたい

当初は専用の秘密鍵を預けてsshでやるつもりだったが、パーミッション諸々で設計が汚くなったのでやめた。
以下のドキュメントにしたがって発行できるGithubのPersonal Access Tokenを使う。

[コマンドライン用の個人アクセストークンを作成する - GitHub ヘルプ](https://help.github.com/ja/articles/creating-a-personal-access-token-for-the-command-line)

## ワーキングディレクトリで`hugo`打ってクリーンアップすると`public`も一緒に消える

CI/CDでよくある`Artifacts`と同じ発想で1階層上に吐き出すようにした。
下記のコマンドで解決。

`hugo -d ../public`
