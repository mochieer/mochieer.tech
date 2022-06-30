---
title: "このサイトのタイポグラフィ"
date: "2022-06-30T00:00:00+09:00"
tags:
  - このサイト
  - プログラミング
  - タイポグラフィ
---

## 文字サイズ

少し前まで大きめの文字を使っていたが、ブラウザ規定の文字サイズをそのまま `1rem` として以下の倍率で5種類のサイズを定義して使っている。

```scss
$font-xl: 2rem; // 1rem=16pxのとき32px
$font-l: 1.375rem; // 1rem=16pxのとき22px
$font-m: 1rem;
$font-s: .875rem; // 1rem=16pxのとき14px
$font-xs: .75rem; // 1rem=16pxのとき
```

## カーニング

日本語ベタ組みメインなので、 `body` レベルでカーニングやプロポーショナルメトリクスを無効にしている。

```scss
body {
  font-feature-settings: "palt" 0;
  font-kerning: none;
}
```

一方で、見出しとかは詰め組したいので `.u-kerning` というユーティリティクラスを用意している。

```scss
.u-kerning {
  font-feature-settings: "palt" 1;
  font-kerning: normal;
}
```

## コンテナ幅

日本語ベタ組みの場合、幅は `1rem` の自然数倍がよい。ということでコンテナの幅は `42rem` としている。これは `1rem` が 16px としたときに 672px となるのだが、本文の幅は 600-700px くらいが読みやすいと言われているようなので、その範囲で好みで調節している。

ただ、レスポンシブのために `max-width: 42rem` となっているので、それより小さい画面幅では実際は `1rem` の自然数倍でなくなる場合がある。こうなると左右の余白のバランスが悪くなったり、行末が揃いにくくなったりする。

この対策として `display: grid` を使用して、 `1rem` のグリッドを中央寄せで画面幅いっぱいまで繰り返すようにしている。

```scss
.l-container {
  box-sizing: content-box;
  margin: 0 auto;
  max-width: 42rem;
  display: grid;
  grid-template-columns: repeat(auto-fill, 1rem);
  justify-content: center;
}

.l-container > * {
  grid-column: 1 / -1;
}
```

なお、この場合左右の余白が実際に何ピクセルで描画されているか判定が難しい。

画像やコードブロックは左右の余白なしで、本文より少し幅広になっているのが好きで、ここは拘りたいと思っている。左右にネガティブマージンを入れることで実現できるのだが、 grid で中央寄せするとそれができない。（ネガティブマージンとして何ピクセル広げればよいか分からないので）

ということで少し工夫して画面幅いっぱいを実現している。

```scss
figure {
  @media screen and (max-width: 44rem) {
    margin-right: calc(-50vw + 50%);
    margin-left: calc(-50vw + 50%);
  }
}
```

コンテナ幅とは関係ないが、縦を揃えるという意味でもうひとつ。箇条書きの左余白を `1rem` の自然数倍としている。

```scss
ul, ol {
  padding-inline-start: 2rem;
}
```

## Vertical Rhythm

縦方向にリズムを作りましょう、そのリズムを繰り返しましょうというのが vertical rhythm と呼ばれるものである。

具体的には縦方向の余白を1行の自然数倍にしてあげると良い、とされている。1行の高さを `$vr-unit` として、それを使いまわしている。

```scss
$vr-line-height: 1.9;
$vr-unit: 1.9 * 1rem;

body {
  line-height: $vr-line-height;
}

h1, h2, h3, h4, h5, h6 {
  margin: $vr-unit * 1.5 0 $vr-unit * .5 0;
  line-height: $vr-unit;
}

p, ul, ol, blockquote {
  margin: 0 0 $vr-unit 0;
}
```

## 禁則処理

前述の通りこのサイトでは現在1行最大で42文字、画面幅がそれ未満の場合は幅いっぱいに表示しているので、変なところで改行されてしまうことのデメリットが行末が揃わないことのデメリットより大きいと判断し、できるだけ厳しい `line-break: strict` を指定している。

1行あたりの文字数が少ない場合は割とゆるいほうが良い（行末がズレにくいほうがブロックとして視認性が高い）ので、このあたりはケースバイケースだと思う。

```scss
html {
  line-break: strict;
  hanging-punctuation: allow-end;
}
```

## 参考リンク

- [本文のタイポグラフィとCSS – Dropbox Paper](https://paper.dropbox.com/doc/CSS-wPD007Sd9dSeEDLP78jri)
- [CSSの単位px、em、remはどれをどこで使用するのがよいか、ピクセルとアクセシビリティにおける意外な真相 | コリス](https://coliss.com/articles/build-websites/operation/css/about-pixels-and-accessibility.html)
- [ウェブデザインの余白に規則性を持たせるためのパターン](https://gist.github.com/yuheiy/89ba79fd0510f98613c217a7dbeb8d03)
