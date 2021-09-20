---
title: "SVG アイコンのロードについて検証"
date: "2021-09-20T00:00:00+09:00"
tags:
  - プログラミング
  - SVG
  - Core Web Vitals
---

## アイコンとウェブページのパフォーマンス

私はウェブページに埋め込まれたアイコンが大好きで、日々アイコンを収集している。そんな私でもやはりスタンダードに [Font Awesome](https://fontawesome.com/) は素晴らしいと思っている。

ただし、やはりフォントファイルと CSS ファイルをロードするのはそれなりのサイズになってしまうので、各々で工夫して改善しようとしている現場も見受けられる。

ちなみに、今見てみたところ、 [fa-solid-900.woff2](https://github.com/FortAwesome/Font-Awesome/blob/master/webfonts/fa-solid-900.woff2) が 76.4 KB で、 [all.min.css](https://github.com/FortAwesome/Font-Awesome/blob/master/css/all.min.css) が 57.9 KB だった。もちろん gzip だともう少し減ると思うが。

- フォントファイル
  - フォントファイルが読み込まれるまで豆腐が表示される
  - フォントファイルが読み込まれると、ページ上で置換される
    - 高さは変わらないようだが、幅が豆腐より大きいのでインラインで使っているとレイアウトシフトの可能性がある
- CSS ファイル
  - 読み込まれるまでページが描画されない

なので、いわゆる [Core Web Vitals](https://web.dev/vitals/) に影響を与えることになってしまう。

## そこで SVG ですよ

SVG のアイコンも非常にたくさんあって、多くがオープンソースで利用可能だったりする。このサイトでも [Feather](https://feathericons.com/) にお世話になっているし、個人開発のプロダクトでも人気があるイメージだ。Font Awesome も個別に SVG ファイルとしてダウンロードすることができたりする。

SVG というのはグラフィックのパスを XML 形式で記述する画像フォーマットなので、 Feather をはじめ、シンプルな図形を表現するのに向いているし、そういった図形は少ない記述量で表現できる。

ところで、 SVG を HTML 上に描画する方法は様々で、また、その方法によって実際に SVG リソースを取得する通信も変わってくる。どういった方法で描画するのがパフォーマンス的に望ましいのかを簡単に検証することにした。

## 検証

### デモページ

- [Loading SVG Icons Demo](https://mochieer.github.io/svg-loading-demo/)
- [mochieer/svg-loading-demo](https://github.com/mochieer/svg-loading-demo)

全体的には軽量にしつつ、ただ、 SVG のロード以外にも多少の CSS のロードとかあったほうが現実的だと思ったので、軽量な CSS フレームワークを入れたりしている。肝心の SVG アイコン自体は前述 Feather から適当に 15 個ピックアップしてきた。

### 検証方法

[デモ (1)](https://mochieer.github.io/svg-loading-demo/demo1/) では SVG を HTML の中に埋め込む（インラインで記述する）方法をとった。

```html
<div class="icon-list">
  <div>
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-activity"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline></svg>
  </div>
  <div>
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-alert-triangle"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
  </div>
  ...
</div>
```

[デモ (2)](https://mochieer.github.io/svg-loading-demo/demo2/) では個別に `object` タグで SVG リソースを描画する方法をとった。

```html
<div class="icon-list">
  <div>
    <object type="image/svg+xml" data="../assets/svg/activity.svg" width="24" height="24"></object>
  </div>
  <div>
    <object type="image/svg+xml" data="../assets/svg/alert-triangle.svg" width="24" height="24"></object>
  </div>
  ...
</div>
```

[デモ (3)](https://mochieer.github.io/svg-loading-demo/demo3/) では SVG 自体はスプライトとして一括でロードし、個別に id で呼び出して描画する方法をとった。

```html
<div class="icon-list">
  <div>
    <svg width="24" height="24">
      <use
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xlink:href="../assets/svg/sprite.svg#activity"
      ></use>
    </svg>
  </div>
  <div>
    <svg width="24" height="24">
      <use
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xlink:href="../assets/svg/sprite.svg#alert-triangle"
      ></use>
    </svg>
  </div>
  ...
</div>
```

[デモ (4)](https://mochieer.github.io/svg-loading-demo/demo3/) は、ちょっと試してみたかった方法で、 SVG のデータ自体は JSON ファイルから取得し（API 呼び出しを行うイメージ）、それを HTML に注入する形で描画してみた。HTML の記述自体は Font Awesome などと似ていて、

```html
<div class="icon-list">
  <div>
    <i class="icon" data-id="activity"></i>
  </div>
  <div>
    <i class="icon" data-id="alert-triangle"></i>
  </div>
</div>
```

こんな感じで、これを JavaScript で操作していく。

```js
fetch('../assets/svg/all.json')
  .then(response => response.json())
  .then(
    (result) => {
      const data = result.data;
      const elements = document.getElementsByClassName('icon');

      for (let i = 0; i < elements.length; i++) {
        const element = elements[i];
        const id = element.getAttribute('data-id');
        const found = data.find(d => d.id === id);

        element.innerHTML = found.value;
      }
    }
  );
```

スプライトだとどうしてもそのページで表示しない SVG データも合わせてロードすることになる。欲しい SVG のデータだけ API で問い合わせたら返ってくる、というやり方にすればよいのではないかというイメージ。感覚的には、問い合わせに対して動的なスプライトを生成して返してもらっている感じと言えるかもしれない。

### 検証結果

[PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/) で計測した。

{{< figure
  url="https://i.gyazo.com/5cb594c689b57cfcd7edd3776807b355.png"
  alt="デモ (1) の結果"
  caption="デモ (1) の結果"
  width="1216"
  height="1070"
>}}
{{< figure
  url="https://i.gyazo.com/fbee041b9c15eba467d595cd249b3543.png"
  alt="デモ (2) の結果"
  caption="デモ (2) の結果"
  width="1190"
  height="1084"
>}}
{{< figure
  url="https://i.gyazo.com/7312e7810bbc7e113ebe135c88269e09.png"
  alt="デモ (3) の結果"
  caption="デモ (3) の結果"
  width="1174"
  height="1082"
>}}
{{< figure
  url="https://i.gyazo.com/ed8b15a1c3f187f7eca9dc7f910e1f16.png"
  alt="デモ (4) の結果"
  caption="デモ (4) の結果"
  width="1172"
  height="1064"
>}}

デモページが軽量すぎたせいか、いずれもほとんど差はなく、実際にトータルのスコアは全て 98 となった。以下、気になった項目を順に見ていく。

#### First Contentful Paint

HTML としてのファイルサイズが大きくなるデモ (1) では、 [First Contentful Paint](https://web.dev/first-contentful-paint/) が悪くなるかと思ったが、結果としては全て同じ (1.9s) となった。

手元の Chrome で見たところ、 `demo1/index.html` 自体は 1.7kB で、 150-300ms ほど応答している。ちなみに、ファイルサイズが最も小さい `demo4/index.html` は 877B だったが、時間はほとんど変わらなかった。この程度のファイルサイズの違いではパフォーマンスとして大きな違いになりようもないということだろう。

SVG アイコンは、どれだけ作り方が悪くてもせいぜい数 KB 程度に収まると思うので、HTML にインラインで書いてしまってもさほどパフォーマンスには影響しないと言えるかもしれない。

#### Speed Index

唯一違いがあったのは [Speed Index](https://web.dev/speed-index/) だった。「コンテンツが視覚的にどれだけ早く表示されるか」を示している、とのことだ。（やや曖昧）

- デモ (1): 2.8s
- デモ (2): 2.1s
- デモ (3): 1.9s
- デモ (4): 1.9s

人間の目で見ると明らかにデモ (2) が、パラパラとアイコンが描画されていて、最も描画に時間がかかっているように感じられたのだが、スコア自体はデモ (1) が最も悪かった。

ブラウザが SVG タグをどのようにレンダリングするかちゃんと調べないと分からないが、仮説としては、最初の DOM 構築からのレンダリングに SVG が全て組み込まれていて、 SVG の解釈が全て終わってからレンダリングしているのではないかと思う。（ただ、もしそうだとすると FCP に差がないというのと直感的には反する）

また、デモ (2) よりデモ (3) のパフォーマンスが優れていた。リソースは個別に HTTP するのでなく、一括で HTTP しなさい、という基本的なお作法は正しかった。

そのデモ (3) とデモ (4) を比べると、「リソースの一括取得」は共通していて、描画を `<use>` タグで行うか、 JavaScript で `<svg>` を HTML に挿入するか、という違いがある。ここにパフォーマンス的な違いが見られないというのは、 `<use>` に特に優位性はないと言えるかもしれない。

## まとめ

軽く検証しようと思ったくらいなのに、コードを書いている時間より記事を書いている時間のほうが長くなってしまった。

大前提として SVG アイコンは十分に軽量でウェブページ全体のパフォーマンスを著しく悪化させるようなものではなく、他に改善するべき点が残されているプロダクトではそちらを優先して対処すべきである。

その上で、 SVG のパフォーマンスを向上する方針としては、やはりスプライトは有効な手段である。一方で、スプライトだと、そのページで利用しないリソースまで一括して取得することになるので、より最適化するなら Web API 経由で SVG データを取得し、 JavaScript で `svg` タグを挿入するという方法にも可能性はありそうだ。

また、 Web API 経由ということは SVG データを動的に変更できるので、 API 呼び出しで 2 色指定して、いわゆるデュオトーンのように塗り分けられた SVG を返却することも可能だったり、拡張性というメリットもある。

さて、一方で、 [npm にある feather-icons](https://www.npmjs.com/package/feather-icons) のように、 JavaScript ライブラリの内部に SVG データを格納してしまう方針も考えられる。これは開発者体験としてはとても良いが、 Feather の全てのアイコンがバンドルされた JS ファイルを読み込むことになるので、 Font Awesome のフォントファイルを読み込むのと同様に、最適な方法とは言えなさそうだ。（Font Awesome の場合、よりクリティカルなのは CSS ファイルが初期レンダリングをブロックしてしまうことだとは思うが）
