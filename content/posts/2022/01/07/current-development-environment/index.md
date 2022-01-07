---
title: "現在の開発環境"
date: "2022-01-07T00:00:00+09:00"
tags:
  - プログラミング
  - 作業環境
---

我が家はマンションのメゾネットタイプで、 Wi-Fi ルーターは下の階、作業部屋は上の階にある。したがってやや電波が届きにくい。また、マンションあるあるだがインターネットがあまり速くない。結果的に下りで 10 Mbps も出ないなんてこともよくある。

そういう事情もあり、 Ubuntu Server をインストールした古い ASUS のラップトップをルーターに直結し、作業部屋の MacBook から VS Code の [Remote SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) でログインして開発を行っていた。

私のプログラマのキャリアの初期は、サーバーに SSH で入ってサーバーの中で開発して Makefile でビルドしてファイルを配置していたような時代だったので、そういう旧時代的な開発スタイルは肌に合うし、牧歌的な感じで好きだったりする。したがって、趣味（物理的サーバー）と実益（通信速度）を兼ね備えた開発スタイルだったと言える。

また、 macOS 上での Docker が遅すぎてストレスが半端でないので、ローカルで仮想 Linux を動かすくらいなら余っている別マシンで Linux を動かすというのは合理的でもあった。

---

さて、前置きは長くなったが、現在は MacBook に完結して、 [Multipass](https://multipass.run/) で Ubuntu Server を動かして開発するようになった。

きっかけは年末年始の 2 年ぶりの帰省で、「あれ、これはラップトップを 2 台持って実家に帰ることになるのか？」と気づいてしまったことにある。

また、タイミングよく下記の記事が目に入ったのも良かった。この記事がなかったら EC2 的なインスタンスを作っていたり、 Cloud9 を試したりしていたかもしれない。

- [Docker + Mac どうする問題 - Mirrativ Tech Blog](https://tech.mirrativ.stream/entry/2021/12/21/125127)

ということで、今は Multipass で Ubuntu Server を動かし、 VS Code の Remote SSH で開発している。もともと物理ラップトップに同じバージョンの Ubuntu Server をインストールして使っていたので、比較的スムーズに移行できた。

ASUS のラップトップも、思えばそろそろ 10 年選手なので天寿を全うする前に引っ越しできてよかったかもしれない。

---

最後に、つまづいたポイントと、解決に役立った記事を書いておく :pray:

- [特にオプションを付けずにインスタンスを作ると disk=5G / memory=1G で生成される](https://multipass.run/docs/launch-command)
  - Node を使う場合は 1G なんかでは絶対足りない
  - [インスタンスを作った後に割り当てを変更する方法](https://github.com/canonical/multipass/issues/1158#issuecomment-548073024)もあるので、やってみてダメだったら増やすのもあり
- [apt で Node をインストールすると古かったりするので n を使う](https://qiita.com/seibe/items/36cef7df85fe2cefa3ea)
- [watch 数の上限に達したので、上限を引き上げる](https://www.virment.com/how-to-fix-system-limit-for-number-of-file-watchers-reached/)
