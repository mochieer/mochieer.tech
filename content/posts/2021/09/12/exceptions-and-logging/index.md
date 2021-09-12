---
title: "例外とログとログレベル"
date: "2021-09-12T00:00:00+09:00"
tags:
  - プログラミング
  - PHP
---

## 経緯と結論

業務でエラーログのモニタリングをもっと整備していかないとね、という話題が最近ホットになっている。その会話の中でちょっと思いついた例外とログ（とログレベル）の話を深堀りしてみようと思う。

結論としてはシンプルで、「例外を投げるならログは出力するべきでない（出力できるはずがない）」「例外を適切にハンドリングできる責務を持ったモジュールが適切にログ出力するべき」というところに落ち着いた。

業務では主に PHP なので、サンプルコードは PHP で。

## エラーログの監視

### ログレベル

御存知の通り、単に error.log を舐めて、なにか出力されるたびにそれを眺めればよいのではない。

- [Yahoo!ショッピングにおけるログ設計と監視 - Yahoo! JAPAN Tech Blog](https://techblog.yahoo.co.jp/web/shopping/yahoo_1/)

適切なログを適切に把握するためにはログ設計が重要で、特にログレベルは最も基本的なログの分類方法だと思う。ヤフーショッピングの場合は

> 私たちはこの中の[info][notice][warn][err][crit][alert]の6つを使用しています。

とある。（古い記事なので、今は多少違っているかもしれないが、ログ監視の基礎なのでそんなには変わっていないと思う）

ちなみに、 PHP の場合は [PSR-3](https://www.php-fig.org/psr/psr-3/) で

```php
<?php

namespace Psr\Log;

/**
 * Describes log levels.
 */
class LogLevel
{
    const EMERGENCY = 'emergency';
    const ALERT     = 'alert';
    const CRITICAL  = 'critical';
    const ERROR     = 'error';
    const WARNING   = 'warning';
    const NOTICE    = 'notice';
    const INFO      = 'info';
    const DEBUG     = 'debug';
}
```

のように 8 段階が定義されている。

### ログレベルの基準

どのレベルのログがどういったことを意味するのかは統一されていなければならない。上述のヤフーショッピングの場合でもやはり定義されているようで、例えば、 notice は「通常とは違うルートで終了したが、問題がない場合のログ」で、 err は 「1回発生した時点で対応が必要になる場合のログ」といった具合だ。

ヤフーショッピングではこうやっている（いた）というだけで、このあたりは対象としているシステムの領域や運用体制なども加味して、それぞれのケースで適切な基準を設けられるのがよいと思う。

## ソースコード上でのエラーの表現

### よくあるコード

PHP だと例外を利用することが多いはずだ。

```php
class FooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      throw new Exception("HTTP status is $status");
    }

    return new Foo($response->getBody());
  }
}
```

200 系以外のレスポンスは失敗という扱いにして例外を投げている、よくあるコードだと思う。

では、この失敗をログで補足したいと考えて、ここにエラーログを仕込んでみよう。

```php
class FooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      $message = "HTTP status is $status";
      Log::error($message); // ←ログ出力を追加した
      throw new Exception($message);
    }

    return new Foo($response->getBody());
  }
}
```

まあ特に問題はない気がする。

### 本当に問題ない？

前述したとおり、ログレベルには基準が存在する。「error は 1 回発生した時点で対応が必要になる場合のログ」という具合だ。では `FooApiClient` が非 200 であることと、それが error のレベルに該当することはイコールかと考えると、必ずしもそうではない。

例えば、負荷軽減のため、何らかのキャッシュされたデータが存在し、そちらからの取得を試みるが、バッチが動く前とかでキャッシュにデータが存在しないこともあるので、キャッシュから取れなければオリジナルの DB から取ってね、みたいなシステム構成だったとしたらどうだろう。

```php
class CachedFooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/cached/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      $message = "HTTP status is $status";
      Log::error($message); // ここでログ出力は正しい？
      throw new Exception($message);
    }

    return new Foo($response->getBody());
  }
}

class OriginalFooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/original/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      $message = "HTTP status is $status";
      Log::error($message); // ここでログ出力は正しい？
      throw new Exception($message);
    }

    return new Foo($response->getBody());
  }
}

class FallbackFooRepository
{
  public function get(string $id): Foo
  {
    $cachedClient = new CachedFooApiClient();
    try {
      return $cachedClient->get($id);
    } catch($e) {
      Log::notice("Get foo from cache is failed: {$e->getMessage()}");
    }

    $originalClient = new OriginalFooApiClient();
    try {
      return $originalClient->get($id);
    } catch($e) {
      Log::error("Get foo from original is failed: {$e->getMessage()}");
      throw $e;
    }
  }
}
```

サンプルが少しずつ長くなってきたが、要するに `FooApiClient` が `CachedFooApiClient` と `OriginalFooApiClient` のふたつになって、それらを順序付けて利用する `FallbackFooRepository` という新しいクラスが出現した。

さて、この場合だと `CachedFooApiClient` の非 200 レスポンスはいわゆる「エラー」ではなくなっている。キャッシュから取れなくても、オリジナルの DB から値が取得できれば、システムとしては問題なく動作できるからだ。

ただし、想定より多くの `CachedFooApiClient` の失敗が出ている場合、それは不具合の可能性があるのでログとして補足できるようにしておきたいので、 `FallbackFooRepository` で `notice` している。そして、 `OriginalFooApiClient` もまた失敗した場合にはじめて foo が取得できなかったという「失敗」になる。

このように考えると、 `CachedFooApiClient` は error ログを出力するのは適切ではなさそうだ。では `OriginalFooApiClient` で error ログを出力しているのはどうだろう？

## 「失敗」とはなんだろう

ユースケースによっては、そもそも foo が取得できなくても「エラー」ではないのかもしれない。

foo からデータが取得できなくても、実は bar からでも欲しい情報は取得可能かもしれないし、バッチの定期実行などでまた次のタイミングで成功すればいいかもしれない。あるいは foo を取得したい目的が極めて些末なもので、実際のところ異常終了してもなんら問題ない程度の存在かもしれない（そんな些末なコードはできれば書かされたくないが）。

つまり、なんらかの処理の「失敗」というのは、それが即ログレベル（＝ことの重大さ）と結びつくわけではなく、なぜその処理を実行したのかというコンテキストに依存するものと認識したほうが良さそうだ。

個別の処理には「失敗」しても、システム全体として見れば「失敗」のうちに入らないかもしれない、ということだ。

### 例外とはなんだろう

> 「例外」は、エラーや例外イベントを呼び出し元のコードに渡すことができる特別な手段である。<br>
> （略）<br>
> エラー状況に対処できないコードはエラーを解釈してそれをうまく処理する機能を持っていると期待して、システムの他の部分に制御を渡すことできる。<br>
> <cite>[コードコンプリート第2版](https://amzn.to/2XeLsDO)</cite>

つまり、あるクラス、あるメソッドのにおいて「対処できない」ことが起こったことを、その呼び出し元に伝える手段である。

すなわち責務の外にあるのだと解釈できそうで、例えば最初の例に立ち戻ると、

```php
class FooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      throw new Exception("HTTP status is $status");
    }

    return new Foo($response->getBody());
  }
}
```

`FooApiClient::get` メソッドの責務は、何らかの手段でもって `Foo` オブジェクトを返却することなのである。何らかの手段というのは外部に対してつまびらかにする必要はなく、 `Foo` オブジェクトを返せるか、返せないかが問われている。

そして、非 200 系のレスポンスが返ってきた場合、 `FooApiClient` としては「返せない」となり、また、 `Foo` が返せなかった場合にどのようなハンドリングを行うべきかは `FooApiClient` の知るところではない（責務外）ので例外を投げるということになる。

例えば失敗した場合にも何らかのダミーオブジェクトを返して良い場合はどうだろう。

```php
class FooApiClient
{
  public function get(string $id): Foo
  {
    $response = $this->client->get("/path/to/foo?id=$id");

    $status = $response->getStatus();
    if ($status < 200 && 300 <= $status) {
      return Foo::dummy(); // これで見た目上Fooオブジェクトを返却できる
    }

    return new Foo($response->getBody());
  }
}
```

API での取得が失敗した場合にダミーオブジェクトを返却することをこの API クライアントの責務とするべきかは、まあ一般論からしても否定的だろうが、仮に `FooApiClient` の責務にダミーオブジェクトの返却が含まれるのであれば、責務の範囲内において非 200 系レスポンスをハンドリングできるので例外を投げる必要がなくなる。

ただし、失敗したのでダミーを返したよ、ということは補足できるべきなので、やはり notice あたりでログに出力するべきだろう。つまり、適切なハンドリングを行うことと、それをログに出力することは責務としてセットだと考えるべきなのだろう。なぜならば、ログというのは「ことの重大さ」が定まらないとログレベルを決定できず、適切なハンドリングを行う責務の中に「ことの重大さ」の判定が含まれているからだ。

## 結論

- 自身の責務において判断ができないことが起こった場合に例外を投げ、判断を呼び出し元に委ねる
  - 判断のできないことに対してログレベル（＝ことの重大さ）を判定することはできないので、ログ出力はできない
- 呼び出し元は、呼び出し元の責務において投げられた例外を判断する
  - 呼び出し元の責務でハンドリングできる場合は、適切にハンドリングを行い、必要に応じて適切なログレベルで出力する
  - 呼び出し元の責務でもハンドリングができない場合は、さらに上位の呼び出し元へ投げる
- 最終的に誰も適切にハンドリングできない例外は、多くの場合はフレームワークがキャッチし 500 エラーを返したりする
  - フレームワークはユーザーに対して何らかのレスポンスを返すことを責務としているので、よく分からないからといって何もしないわけにはいかない
