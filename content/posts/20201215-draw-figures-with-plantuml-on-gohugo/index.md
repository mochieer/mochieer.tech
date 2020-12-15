---
title: "Hugo で PlantUML を書きたい"
date: "2020-12-15T00:00:00+09:00"
tags:
  - プログラミング
  - Hugo
  - PlantUML
  - Gravizo
---

## やりたいこと

{{< plantuml "ユースケース" >}}
@startuml
left to right direction
:このサイト: --> (PlantUMLでクラス図とか書きたい)
@enduml
{{< /plantuml >}}

記事の Markdown 中に PlantUML 記法で記述したら、最終的に出力される HTML としては図が出力されている状態。

## いつ図を生成するか

このサイトは Hugo で生成している。静的なサイトなので、お作法的には必要な画像はビルド時に生成してホスティングしてあげるのが望ましい。

ただ、 Hugo はそういうプラグイン的な挙動にとても弱い。コミュニティとしても、そういうタスクランナー的なものは別途 Webpack でも Gulp でも動かしてねという雰囲気である。

が、 Hugo の watch とは別になんらかのタスクランナーが動くというのは個人的には好ましくない。なので、ユーザーがページを開いたときに図を生成するという方針を取る。

## PlantUML Server

[PlantUML Server](https://plantuml.com/ja/server) というものがある。

たとえば
```html
<img src="http://www.plantuml.com/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000" />
```
みたいな感じで画像を HTML に埋め込んであげれば、

{{% figure
  url="https://www.plantuml.com/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
  alt="PlantUML シーケンス図"
  width="200"
%}}

こんな感じの図が表示される。とても便利だ。

ただ、この URL に指定する文字列 `SyfFKj2rKt3CoKnELR1Io4ZDoSa70000` の仕様がとても厄介だったりする。

お察しの通り、この文字列は
```plain
@startuml
Bob -> Alice : hello
@enduml
```
を可逆変換したものなのだが、シンプルに base64 をかけたとかそういう類のものではない。

[PlantUML テキストエンコード](https://plantuml.com/ja/text-encoding)によると、

> 1. Encoded in UTF-8
> 2. Compressed using Deflate or Brotli algorithm
> 3. Reencoded in ASCII using a transformation close to base64

とのことで、 Deflate or Brotli アルゴリズムで圧縮し、 base64 に**よく似た**方法でエンコードする、とある。

この手順のエンコードはページが読み込まれたときに実行されれば良いので、ひとまず JS で書くことを考えるが、 Deflate や Brotli アルゴリズムはどこかの実装を持ってくれば良いとして、この base64 に**よく似た**方法というのが、要するに PlantUML Server の独自の変換で、できれば実装したくない。

## Gravizo

そこで代替案を探していたところ、 Gravizo というサービスを見つけた。

- [Your Graphviz, UMLGraph or PlantUML for your README](https://www.gravizo.com/)

こちらは

```html
<img src="https://g.gravizo.com/svg?
@startuml;
Bob -> Alice : hello;
@enduml
" />
```

と変なエンコードせずに URL に PlantUML をそのまま書くと、

{{% figure url="https://g.gravizo.com/svg?@startuml;Bob -> Alice : hello;@enduml" alt="Gravizo で生成した画像" width="200" %}}

と表示してくれる。ロゴが重なっているのが少し気になるが……（有料でロゴは消せるようだ）

## Hugo の shortcode を書く

ということで Gravizo を利用することに決めた。

あとは Hugo で使いやすいように shortcode を書く。 shortcode とは Markdown 中に独自の custom element を定義できるような Hugo の機能である。

```html
{{ $caption := "" }}
{{ if .IsNamedParams }}
  {{ with .Get "caption" }}
    {{ $caption = . }}
  {{ end }}
{{ else }}
  {{ with .Get 0 }}
    {{ $caption = . }}
  {{ end }}
{{ end }}

<figure class="c-plantuml">
  <object
    type="image/svg+xml"
    data="https://g.gravizo.com/svg?{{ .Inner }}"
  ></object>
  {{ with $caption -}}
    <figcaption>{{ . }}</figcaption>
  {{- end }}
</figure>
```

これを `shortcodes/plantuml.html` として保存し、 Markdown 中で

```text
{{</* plantuml "ユースケース" */>}}
@startuml
left to right direction
:このサイト: --> (PlantUMLでクラス図とか書きたい)
@enduml
{{</* /plantuml */>}}
```

こんな感じで呼び出してやれば良い。すると、この記事の一番上のユースケース図が表示される。

背景はついていたほうがいいので、適当にクラスを付けてスタイルを当てた。また、せっかく SVG なので `<img>` でなく `<object>` で描画するようにした。
