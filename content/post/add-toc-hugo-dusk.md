---
title: "Hugo DuskにToCをつける"
date: 2020-06-13T07:31:14Z
---

# TL;DR
* このサイトで採用しているテーマ:[gyorb/hugo-dusk](https://github.com/gyorb/hugo-dusk)ではToCを出せない
* 長い記事を書いたときに頭にToCがないと不便
* 次の記事を参考に実装した
  * [Hugo の目次について考える · k-kaz](https://k-kaz-git.github.io/post/hugo-custom-tableofcontents/#400%E5%AD%97%E6%9C%AA%E6%BA%80%E3%81%AE%E5%A0%B4%E5%90%88%E3%81%AF%E7%9B%AE%E6%AC%A1%E3%82%92%E5%87%BA%E3%81%95%E3%81%AA%E3%81%84)
  * [各ページに目次を表示する (.TableOfContents) | まくまくHugo/Goノート](https://maku77.github.io/hugo/template/table-of-contents.html#%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%81%AE%E8%A8%98%E8%BF%B0%E6%96%B9%E6%B3%95v060%E4%BB%A5%E9%99%8D)
* 全てはこのdiffに書いてある
  [Add ToC · fono09/hugo-dusk@d0c86c4](https://github.com/fono09/hugo-dusk/commit/d0c86c448e7228672c856a2b927d132ce43a52f7)
# テンプレートにToC用のpartialを追加する

テンプレート本体を肥大化させたくないためpartialに押し込む

```
--- a/layouts/_default/single.html
+++ b/layouts/_default/single.html
@@ -2,6 +2,7 @@
 
 <article class="post">
     <h1 class="title"> {{ .Title }} </h1>
+    {{ partial "toc.html" . }}
     <div class="content"> {{ .Content }} </div>
     {{ partial "postfooter.html" . }}
 </article>
```

# partialでToCのテンプレートを書く

[Hugo の目次について考える · k-kaz](https://k-kaz-git.github.io/post/hugo-custom-tableofcontents/#400%E5%AD%97%E6%9C%AA%E6%BA%80%E3%81%AE%E5%A0%B4%E5%90%88%E3%81%AF%E7%9B%AE%E6%AC%A1%E3%82%92%E5%87%BA%E3%81%95%E3%81%AA%E3%81%84) を参考にしつつ、`details` `summary` タグで折り畳めるHTMLを書く。

```diff
--- /dev/null
+++ b/layouts/partials/toc.html
@@ -0,0 +1,6 @@
+{{ if and (gt .WordCount 400) (ne .Params.toc false) }}
+<details>
+  <summary>目次</summary>
+  <div class="toc">{{ .TableOfContents }}</div>
+</details>
+{{ end }}
```

# ToCに適用するCSSを追記する

[各ページに目次を表示する (.TableOfContents) | まくまくHugo/Goノート](https://maku77.github.io/hugo/template/table-of-contents.html#%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%81%AE%E8%A8%98%E8%BF%B0%E6%96%B9%E6%B3%95v060%E4%BB%A5%E9%99%8D) を見ながら、リストスタイルをやめてインデントを加える部分だけ真似して終了。 

```
--- a/static/css/layout.css
+++ b/static/css/layout.css
@@ -510,3 +510,20 @@ th, td {
   }
 }
 
+/* TableOfContents */
+#TableOfContents > ul {
+  font-size: smaller;
+}
+#TableOfContents ul {
+  list-style-type: none;
+       text-align: left;
+}
+#TableOfContents li {
+  padding-top: 0;
+}
+#TableOfContents li > ul {
+  padding-left: 1em;
+}
+#TableOfContents a {
+  font-weight: normal;
+}
```

