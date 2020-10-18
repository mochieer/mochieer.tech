---
title: "GitHub Actions でビルドするようにした"
date: 2020-10-18
tags:
  - このサイト
  - GitHub
  - GitHub Actions
  - Hugo
---

[peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)

こちらを利用した。基本的にはデフォルトの設定通りでいけたのでとても簡単だった。

自分のリポジトリはデフォルトブランチが `main` だったが、サンプルの設定ファイルでは `master` になっていたので、そこだけ直した。（これは誰が悪いのか）

あわせて、このサイトのソースコードを public にしてみた。

[mochieer/mochieer.tech](https://github.com/mochieer/mochieer.tech)

ソースコードの管理とビルドとホスティングをひとつのサービスで一貫できるというのはやはりかなり嬉しい。

Netlify は GitHub との連携がかなり良くて気に入っていたが、日本からだとネットワーク的に遠いのか、やたら遅い印象がある。
