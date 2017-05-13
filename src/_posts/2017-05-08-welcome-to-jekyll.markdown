---
layout: post
title:  "Jekyllはじめました"
date:   2017-05-13 14:58:24 +0900
categories: jekyll
---

タイミングがタイミングで、jekyllの標準ページだと恥ずかしいので、自己紹介と、最初の記事を追加した。技術的には以下のような作業を実施した。

Gitで記事を管理し、commitしたら自動でjekyllを走らせることで、簡単に版管理・更新が行える。
そのために、git-hookを用いた。

`.git/hooks/pre-commit`に以下のスクリプトを設置
```
#!/bin/sh
docker run -d -v $PWD:/srv/jekyll jekyll/jekyll jekyll b -s src
CTID=`docker ps -ql`
EC=$(docker wait $CTID)

if [ $EC -eq 0 ]; then
	docker rm $CTID
else
	echo "jekyll build failed!!"
fi

exit $EC
```
流れ的には、
1. 静的コンテンツをビルドするためのコンテナ作成
2. コンテナのIDを`CTID`に取得
3. コンテナ`CTID`の終了を待ちつつ、`EC`へ終了コードを取得
4. 終了コードが非ゼロならば騒いでコンテナを残しておく
5. 何もなければコンテナ消して終了

べーんり！

