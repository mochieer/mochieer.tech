---
title: "年、月、日ごとの記事一覧を作成した"
date: "2021-03-31T00:00:00+09:00"
tags:
  - esa
  - このサイト
  - プログラミング
  - Hugo
---

[情報共有サービスの esa](https://esa.io/) では[記事がストックとフローに分類されている](https://docs.esa.io/posts/298)。しっかりと[コンセプト](https://esa.io/concept)にも「チャットのように気軽に発信、Wikiのように整理・編集する。フローとストックの間をシームレスに繋げたい」と書かれているが、私はこの思想がとても良いと思っている。

情報を発信する敷居を下げつつ、しっかりとストックされる記事を、という意味ではこういう個人サイト（ブログ）でも同じことが言えると感じたので、あくまでその記事がある時点での情報であることを強調する記事 URL にすることで、「まだ考え中」のような記事の発信のハードルを下げつつ、年/月/日で絞り込んだ記事の一覧をサイトの機能として提供することで記事の階層的な整理をできるようにしてみた。

---

以下は技術的な話になる。

このサイトは [Hugo](https://gohugo.io/) で生成している。

Hugo ではこういう記事の階層構造は [Section](https://gohugo.io/content-management/sections/) を使って実現することになっているようなので、それに倣った。つまり、この記事でいうと `posts` も `2021` も `03` も `31` も `post-list-by-date` もすべて section ということになる。

躓いた点として、ある階層をセクションとして認識させるにはその階層に `_index.md` がないといけないらしい。


> The important part to understand is, that to make the section tree fully navigational, at least the lower-most section needs a content file. (e.g. _index.md).
>
> <cite>[Content Sections | Hugo](https://gohugo.io/content-management/sections/)</cite>

あるセクション（例えば `2021` ）に対して、固有の一覧ページを作りたいとかではなく、ルート (/posts) と同じ挙動でいいので `_index.md` は空ファイルとなっている。ひとつの記事を作るのにディレクトリと `_index.md` をたくさん作らないといけなくなったので、雑なシェルスクリプトを書いて対応した。

```sh
#! /bin/sh

read -p "year: " YEAR
read -p "month: " MONTH
read -p "day: " DAY
read -p "title (Japanese): " TITLE_JA
read -p "title (English) for URL: " TITLE_EN

while true; do
    read -p 'Okey? [Y/n] ' yn
    case $yn in
        [Y] )  break;;
        [Nn] ) exit;;
        * )    ;;
    esac
done

mkdir -p content/posts/$YEAR/$MONTH/$DAY/$TITLE_EN

touch content/posts/$YEAR/_index.md
touch content/posts/$YEAR/$MONTH/_index.md
touch content/posts/$YEAR/$MONTH/$DAY/_index.md
echo "---
title: \"${TITLE_JA}\"
date: \"${YEAR}-${MONTH}-${DAY}T00:00:00+09:00\"
tags:
  - foo
  - bar
---
" > content/posts/$YEAR/$MONTH/$DAY/$TITLE_EN/index.md
```

ちなみに、 `list.html` はこんな感じ。

```html
<h1>記事一覧</h1>
<ul>
  {{- if .Sections }}
    {{ range .Sections }}
      {{- range (site.GetPage "section" .File.Dir).RegularPagesRecursive }}
        {{ template "article-headline" . }}
      {{- end }}
    {{ end }}
  {{- else }}
    {{- range (site.GetPage "section" .File.Dir).RegularPagesRecursive }}
        {{ template "article-headline" . }}
    {{- end }}
  {{- end }}
</ul>
{{- define "article-headline" }}
<li>
  <time>
    <a href="{{ .Site.BaseURL }}/posts/{{ .PublishDate.Format "2006" }}">{{ .PublishDate.Format "2006" }}</a>
    /
    <a href="{{ .Site.BaseURL }}/posts/{{ .PublishDate.Format "2006" }}/{{ .PublishDate.Format "01" }}">{{ .PublishDate.Format "01" }}</a>
    /
    <a href="{{ .Site.BaseURL }}/posts/{{ .PublishDate.Format "2006" }}/{{ .PublishDate.Format "01" }}/{{ .PublishDate.Format "02" }}">{{ .PublishDate.Format "02" }}</a>
  </time>
  <h2>
    <a href="{{ .Permalink }}">{{ .Title }}</a>
  </h2>
</li>
{{- end }}
```

（ちょっと変えています。実際のコードは [GitHub](https://github.com/mochieer/mochieer.tech) を見てください）
