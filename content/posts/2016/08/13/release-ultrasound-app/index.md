---
title: "超音波を使ったアプリをリリースして思ったこと"
date: 2016-08-13
tags:
  - プログラミング
  - アプリ開発
  - iOS
  - 超音波
  - リリース
---

{{% figure src="cover.jpg" alt="Hzをリリースしました" %}}

## アプリの概要
ワンタップでその場の全員と Facebook アカウントを交換できる iOS アプリ「Hz」をリリースした（一週間くらい前に）。

アプリのコンセプトは、Facebook アカウント交換の煩わしさをボタンひとつで済ませられるようにするというところ。

その場に何人いても、誰か一人がボタンをワンタップするだけなので、特に飲み会などの席で役に立つと思う。

詳細は下記 LP と、一緒に作った pika\_shi の記事がアツい。

- [Hz (ヘルツ) - 5 秒でその場の全員とつながる Facebook アカウント交換アプリ](http://hz.matataki.team/)
- [Facebook アカウント交換アプリ「Hz」をリリースした - Hello World!!](http://pika-shi.hatenablog.com/entry/2016/08/07/152528)

自分はアカウント交換のコアロジックとデザインを担当した。

## 超音波

Hz では、端末のペアリングに超音波による通信技術を利用した。

超音波通信技術なんていうとかなり細かいことをやっているのかと思われるかもしれないが、端末から非可聴域の高周波な音を出し、別の端末では常に FFT を回し続けるだけなので、シンプルといえばシンプル。

ただ、思考の順序としては実は逆で、先に iOS で超音波で通信できることを調べてから、「じゃあ、これ何に使えるか」と考えて Facebook アカウント交換アプリという形になった。

アイデアをまとめていく過程、実装する過程で気づいた超音波による信号通信の長所と短所をまとめておく。

### 長所

#### 高速

インターネット通信をしないというメリットはすごく大きい。単に音を出す、音を聞くだけなので、通信のオーバーヘッドはほぼゼロと言える。Bluetooth なども一旦ペアリングしてしまえば強力だが、ペアリングは手間だったりする。

#### デバイスに依存しない

発信に必要なのはスピーカーだけ。受信に必要なのはマイクと FFT が行えるくらいのメモリとプロセッサだけ。お店に設置したスピーカーから超音波を出して、キャッチしたアプリにクーポンを表示する、とかもできる。

#### ブロードキャストできる

1対1の通信でなく、1対Nの通信を1度に行える。スタジアムの大きいスピーカーを使えば、スポーツ観戦している人全員に一斉に信号を配信することも理論上は可能。

#### 通信範囲を「空間」で区切れる

超音波は音に過ぎないので、隣の部屋までは飛んでいかない。「この部屋に入ってきた」ということを、電波や GPS より明確に区別できる。

#### 電子機器に影響しない

繰り返しになるが、超音波は音に過ぎないので、他の電子機器への干渉はほぼない。特に精密機械が多い医療分野への貢献はあるかもしれない。

### 短所

#### 通信できる情報が少ない

PIN コードを送るくらいが限度。テキストを送るとなると、相当うまく作らないと HTTP のほうが高速になってくると思う。

#### 帯域が狭い

デバイスのサンプリング周波数に依存するところだが、FFT で判別できる周波数には上限がある。なので、仮に超音波が街中いろんなところで使われるようなことになったとしたら、帯域が競合してしまうことになる。同じ理由で、同じロジックを持ったプロダクトが世の中に共存できないので、基本的に超音波通信の OSS というのも考えにくい。

#### セキュリティが脆弱すぎる

単にマイクがあれば通信傍受できてしまう。傍受して信号を解析すると（信号も単純なので解析は容易）、あとはスピーカーがあるだけで操作もできてしまう。

と、こんな感じ。

長所も多いが短所も多い。ただ、引き出しとしてひとつ持っておくと、なにか面白いことができるかも？

