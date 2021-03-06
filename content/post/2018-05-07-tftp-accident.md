---
date: 2018-05-07T20:30:45+09:00
title: TFTP設定流し込みによる遠隔作業事故
---
# TL;DR
* Gitで設定バージョン管理
* 実家から自宅のサーバへ接続
    * 同セグメントのルータへTFTP設定流し込み
    * 流し込みファイルを誤選択
    * 設定保存コマンド入り
* 自宅接続断発生
* 今後の対策
    * 死活監視
    * 設定保存コマンドを確認するまで流さない
    * 死亡時の復旧手法確立
        * 設定を保存しない
        * PDUによるリブート
    * 最終生存時の設定から復旧するバッチ
    * Raspberry Pi設置
        * LTE回線接続端末として利用
        * バッチ動作ノードとして利用

# 背景

自宅,実家,祖母宅の3拠点にRTX810を導入しており、各々設定ファイルを `RTX810-(設置場所市名)` で同じディレクトリに配置し、Gitでバージョン管理。
設定変更時は、設定ファイルを編集してコミットの後、Githubへプッシュ。tftpで転送して、問題なければルータにて設定保存していた。

# 事故内容

## 事故直前までの経緯
実家から実家と自宅、2拠点間のIPsec-VPNの設定を試みていた。

実家から自宅拠点のサーバ`Server-A`へSSHでアクセスし、その環境にて自宅ルータ`RTX810-A`, 実家ルータ`RTX810-B`の設定ファイルを編集。コミットを重ねていた。

tftpで設定を流し込む際、`RTX810-A`には`Server-A`を用いて、`RTX810-B`には手元端末`Client-B`を用い、設定ファイルの融通にはGithubを利用していた。

その際、同じディレクトリに`RTX810-A`の設定と`RTX810-B`の設定を配置した状態であった。

## 事故
`Server-A`から`RTX810-A`への設定流し込み時に、tftpのコマンドを間違え、`RTX810-B`の設定を`RTX810-A`へ流し込んでしまった。

## 復旧不可

`RTX810-A`の設定ミスによる接続断は想定されており、`RTX810-A`のLTE回線からGoogleCloudPlatformへ張られたVPNを用いての復旧が想定されていた。

しかし、その設定も含めて書き換えられてしまったため、完全に遠隔からの復旧は不可能になってしまった。

今回は、自宅拠点に人が居なかったため影響しなかったが、転送した設定ファイルは保存コマンドが有効になっていた。
これは、オペレータでない第三者による電源操作を利用した復旧さえ不可能にしてしまう。

# 対策

そもそも死活監視をしていないので、死活監視を開始して、死亡時になんらかの処理をできるようにする。

復旧手法として、直前の設定を流し込む方式と、単純に設定転送時には保存コマンドを入れずに、PDUを用いて電源断を行う手法がある。

いずれも、意図しない設定の巻き戻りや、意図しない電源断を招く可能性があるので、死活判定時の死亡判定、復旧実行頻度をよく検討する必要がある。

1番簡単な手法として、各拠点にモバイル回線を用意したRaspberry Piを置くことだという指摘を頂いた。確かにそう。確かにそうだが。追加で月額800円(SIM追加2枚)を払うのは、上記に挙げた仕組みをラズパイで実現し維持するコストとどちらが安いのだろうか……。たしかに、仕組みの維持に1時間取られただけでパートタイム時給ですらペイできてしまう。うーむ。
