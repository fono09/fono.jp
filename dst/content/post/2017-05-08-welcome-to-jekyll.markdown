---
date: 2017-05-08T14:48:24Z
title: Jekyllはじめました
url: /2017/05/08/welcome-to-jekyll/
---

タイミングがタイミングで、jekyllの標準ページだと恥ずかしいので、自己紹介と、最初の記事を追加した。技術的には以下のような作業を実施した。

Gitで記事を管理し、commitしたら自動でjekyllを走らせることで、簡単に版管理・更新が行える。
そのために、git-hookを用いた。

`.git/hooks/pre-commit`に以下のスクリプトを設置
```
#!/bin/sh
cd $(git rev-parse --show-toplevel)
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
1. jekyllを実行するパス(Gitリポジトリのルート)へ移動
2. 静的コンテンツをビルドするためのコンテナ作成
3. コンテナのIDを`CTID`に取得
4. コンテナ`CTID`の終了を待ちつつ、`EC`へ終了コードを取得
5. 終了コードが非ゼロならば騒いでコンテナを残しておく
6. 何もなければコンテナ消して終了

べーんり！

## 参考サイト
* [Jekyll を Docker でやる](http://jyane.jp/2016/02/03/jekyll.html)
* [how to get project path in hook script post-commit?(git) - Stack Overflow](http://stackoverflow.com/questions/5248587/how-to-get-project-path-in-hook-script-post-commitgit)
