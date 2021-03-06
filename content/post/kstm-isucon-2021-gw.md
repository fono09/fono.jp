---
title: "出身サークルのISUCONに雑に参加した話"
date: 2021-05-10T08:26:30+09:00
tags:
  - Ruby
  - Linux
  - ISUCON
---

# なにこれ

主催者の記事: https://goryudyuma.hatenablog.jp/entry/2021/05/10/005033  
主催者に誘われたので他人のリソースでISUCONして優秀な後輩に負けてきた。

大体以下のコミットログを元に雑に説明する。  
[参加記録リポジトリ(Github)](https://github.com/fono09/kstm-isucon-2021-gw)

![負けたと書くだけでこの厚み？](/assets/maketa-atsumi.jpg)


# 結論・感想

5位。7万点ぐらい。リポジトリを見ればいつ何をやったかわかる。終盤の変更は全て改悪で最終スコアは5万点だったが、わざと提出しなかったため7万点となっている。

敗因は、雑なペース配分、貧弱なプロファイリング、RubyでのISUCON経験値不足と見ている。

まず、雑なペース配分。せめて48時間のハッカソンをしなければならないのに、24時間で体力がほぼ尽きるペース配分をいていて24時間やって、4時間仮眠した後はほぼ脳死の上、計測・分析・対処という基本が疎かになっており打ち手の精彩を欠いた。

次に、貧弱なプロファイリング、`top`コマンドと`rack-lineprof`だけ。つまり限られたリソースでどこが詰まっているか系は勘でやったでやっていた。そのため、スコアが明らかに上がるはずの施策で下がった原因を正しく理解できなかった。

最後に、RubyでのISUCON経験値不足。殆どの高速化をRedisに依存しまくったし、なんならRedisのチューニングはしたことがない。本当は同じマシン上に別プロセス立てて依存するだけでCPUのコンテキストスイッチが増えて負ける。なので、GoみたくオンメモリDBをお手製で作って永続化したい。しかし、Rubyのメモリをかなり理解していないとできないし、Sinatra上で付け焼き刃でやろうとするとまずできない。

# 参加経緯

* 主催者に煽られた
* Ruby(Sinatra)+Redisという初期方針でどこまでいけるか試したかった
* ~~後輩相手にイキりたかった~~(ポジティブな意味で煽りたかった)

# 学び
* 最初に計測は仕込んで徹底的に分析しろ  
  金曜日の退勤後、雑なノリで着手したのでこの段階で詰んでた  
  途中からやると[木こりのジレンマ](https://webtan.impress.co.jp/e/2017/06/27/26149)に陥って敗北する
* トータルシステムで見ろ  
  エディタ開いて見ているのはリクエストを受けてから返すまでの一部分に過ぎない  
  見ていない場所がボトルネックだったらその変更は無意味だ
* メモリ管理を意のままにできる言語・環境でやれ  
  メモリ上で無理やり永続化する必要に迫られるのでこれができないと負ける  
  RedisでキャッシュしてやってもAPとRedis間通信のオーバーヘッドで負ける  
  今回は、Ruby(Sinatra)のメモリ管理を理解していなかったので負けた
* Rubyがウィークポイントだと思ったならnginxでできることをもっとやれ  
  単純な文字列組み立てなら下手するとAPに行くまでにnginxのLuaでやったほうが早い  
  ユーザー名を無暗号化状態でクッキーに仕込んでLuaでレンダリングもアリだった  
  例えばこんな感じの合せ技  
  * [node.js - Can we use NGINX as webapp for template engine - Stack Overflow](https://stackoverflow.com/questions/48577858/can-we-use-nginx-as-webapp-for-template-engine)
  * [How to extract some value from cookie in nginx - Stack Overflow](https://stackoverflow.com/questions/26128412/how-to-extract-some-value-from-cookie-in-nginx)
* やったことがないことはできない: Rubyでもメモリキャッシュ利用実装ができたはずだができなかった
  * [ruby - In Sinatra, is it possible to save global data in memory? - Stack Overflow](https://stackoverflow.com/questions/33890582/in-sinatra-is-it-possible-to-save-global-data-in-memory)
  * [Sinatra with caching example · GitHub](https://gist.github.com/mwpastore/dc8f39cdadac4a6e32ad)

# 何をやったか

大体リポジトリのコミットログに言い訳をつけたもの  
ここと一緒に見ること: [Commits · fono09/kstm-isucon-2021-gw](https://github.com/fono09/kstm-isucon-2021-gw/commits/master)

1. `/home/ishocon` 配下をgitリポジトリに沈める  
  VCS使わないのは敗因になりうるのでまずそこはやる
1. 15,555点: MySQLに勘でindexを貼る
 勘とはいうものの、一応発行されるクエリは見てやった  
 SQLのslow logをなぜ見なかったかは今となってはわからない
1. 15,938点:ページネーションを`products.id`のBETWEWENにする  
 `LIMIT OFFSET`してやがったのでやめさせた
1. 15,805点: セッションストアをRedisにした  
 `users`あたりの頻繁に引かれている情報をRedisに載せ、クッキーの肥大を抑える
1. 18,858点: `index`にある`products`と`comments`のN+1を解消
 それでもクエリが重たいことには変わりない
1. 20,223点: `current_user`の情報はRedisに聞く  
 問い合わせている頻度が高そうなのでとりあえずやった  
 懺悔:ここらで `users` のRedisへの格納をHASHでやれば属性をたくさん生やすことができた
1. 点数不明: publicをnginxで返し、`last_login`を廃止  
 **ここらからオペレーションに綻びが出始めた**  
 やっていることは妥当なはず。この差分で`nginx`のライトチューンもした
1. 点数不明: `histries`に`product_id, user_id`の複合index  
 これミスじゃないかな……とりあえず露骨な悪影響なさそうだけど
1. 70,893点: コメントの件数をRedisに入れてキャッシュ  
 明らかにMySQLを重たくしているしRedisで良いと判断  
 `row_number`振って上位5件とか言うのをリクエスト毎やっていたのでどう見ても重い
1. 71,018点: MAX(product.id) をDBで引かない  
 当初の設計では何も考えずやったが、`products`の更新系ないのに気がついた
1. 73,112点: 過去の購入判定をRedis化  
 `histories` を `user_id` で舐めて集計させてたのをやめた
1. 74,705点: `cache-control` を吐かせてみる  
  ここらは勘。適切なヘッダを吐かせる努力おしていなかったので多分あまり効果がない  
  なんなら、キャッシュ戦略をするならフラグメントキャッシュでない限りnginxに任せるべきだった
1. 45,371点: コメントをRedisに入れたが遅くなった(これは直後にRevert)  
  入れ方が悪いのでやめた普通に時系列なので`users.name` `comments.content` の2つのリストで良い
1. 69,411点: 大量のキーでRedisが潰れたので初期化を `redis.flushall` する  
  明らかに重たくなっていたのでなにかおかしいと思ったらこれだった
1. 点数不明: ドメインソケットでRedisに繋ぐ  
  そろそろMySQLの肩代わりをしたRedisが重たくなると思ってここでやった
1. 71,073点: `/products/:product_id` で`comment`を見ていないので外した  
  ほぼ無意味。イテレータで舐めているから実際にクエリは飛んでないのかも
  **ここらで提出をやめた**
1. 52,255点: コメントをRedis化  
  LISTでRedis化したが悪化したが、点数が上がらない。  
  原因の計測・分析をする心身の余裕はもうなく、ここからは定期的に奇声を上げながらデスマーチしていた。
1. 43,277点: mypageのproductをRedis化  
  productsに更新系はない。ならすべてキャッシュしてしまえば良い。  
  という発想だったが、更新がないならばRedisではなく本当はAPのオンメモリにしたかった。  
  しかし、Ruby(Sinatra)でやる方法がわからん。freezeしたり参照をApplicationのクラスに持たせたりとやったがデストラクトされてしまう。
1. 56,222点: 説明文を切り詰めた  
  切り詰めた説明文を用意した。70文字目までしか見ていないならば切った状態でRedisに格納すれば良い。
1. 51,012点: フラグメントキャッシュを入れた  
  productsの更新がないならば、一部はレンダリング済みのページを配信すれば良い。  
  が、今思うとこれはnginxでのテンプレート処理まで落とせたかもしれない。  
1. 51,193点: productsのMySQLの参照を一つ減らした
  Redis依存を強めた分だけちょっと早くなった
