---
title: "Docker で Composer を使う"
date: "2021-10-25T00:00:00+09:00"
tags:
  - プログラミング
  - Docker
  - Composer
  - PHP
---

## まとめ

```yml
version: "3"
services:
  app:
    image: php:8-apache
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
  composer:
    image: composer
    command: "composer install"
    volumes:
      - ./:/app
```

`docker-compose.yml` をこんな感じにして、

```sh
$ docker-composer up --build
```

とかすれば `composer.lock` に従ってパッケージのインストールをしてくれる。

新しく require を追加したかったら、

```sh
$ docker-compose run --rm --no-deps composer composer require phpunit/phpunit --dev
```

とかすればよい。

```sh
#!/usr/bin/env bash
docker-compose run --rm --no-deps composer composer "$@"
```

くらいのシェルスクリプトをエイリアス的に用意してあげても良い。

**ただし、この方法では PHP 本体のバージョンや PHP の拡張に対する依存の宣言は正しく評価されない。実際のアプリケーションなどで利用する場合は、アプリケーションの実行環境としての PHP 環境で `composer install` する必要がある。**

## 詳細

### why

そもそもの課題感として、

1. ローカルで `composer install` したくない
    - そもそもローカルに PHP 入っていない
    - 入っていたとしても `ext-*` は入っていない
2. 一方で、 Composer でインストールしたファイル群（ `composer.lock` と `vendor/` 以下）はローカルにも存在してほしい
    - エディタの補完を使いたい
    - 期待しない動作をするライブラリのコードを読みたい
    - `composer.lock` は git で管理したい

なので、 `composer` コマンドはコンテナ内部で実行し、その結果はローカルと同期したい。

### composer イメージ

composer イメージというのがあるようで、これを使う。

- [hanhan's blog - Dockerにcomposerをインストールする方法の正解](https://blog.hanhans.net/2019/01/08/docker-composer/)

上記のブログでは Dockerfile で `/usr/bin/composer` を配置しているが、そうすると git など Composer が依存する各種コマンドが利用できる必要があり、それは本来のアプリケーションには必要ないもの（ビルドにのみ必要なもの）なので、 Docker Compose で別 service として実行して、実行結果のファイルのみマウントするような方針を取ることにした。

ということで、 `docker-compose.yml` がこうなる。

```yml
version: "3"
services:
  app:
    image: php:8-apache
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
  composer:
    image: composer
    command: "composer install"
    volumes:
      - ./:/app
```

ただし、ディレクトリ構成は

- src/
- vendor/
- composer.json
- composer.lock
- docker-compose.yml

がルートに並んでいるものとする。

### 使い方

簡単なシェルスクリプト

```sh
#!/usr/bin/env bash
docker-compose run --rm --no-deps composer composer "$@"
```

を設置して、

```sh
$ ./bin/composer.sh install
$ ./bin/composer.sh phpunit/phpunit --dev
$ ./bin/composer.sh update
```

みたいな感じで使うと、ローカルの `composer.json`, `composer.lock`, `vendor/` も更新される。

### ただし…

ところで、 composer イメージで依存の解決がされるとき、 PHP そのもののバージョンや `ext-*` はどのように評価されるのだろう。

私はふんいきで Docker をやっているのであくまで雰囲気だが、 app とは無関係なところで `composer install` が実行されてファイルのみ同期されているのだと思う。とすると、例えば `ext-mbstring` を必要とするパッケージをインストールする際に、 app 側の PHP 環境として mbstring 拡張が存在しなくても、 composer install は成功してしまい、実行時（それも mbstring を利用する際）に初めて mbstring がなくて死ぬ、ということになるのだろうか。

と思ったら、やはり Docker Hub にそのような注意書きがあった。

> Our image is aimed at quickly running Composer without the need for having a PHP runtime installed on your host. You should not rely on the PHP version in our container. We do not provide a Composer image for each supported PHP version because we do not want to encourage using Composer as a base image or a production image.
>
> We try to deliver an image that is as lean as possible, built for running Composer only. Sometimes dependencies or Composer scripts require the availability of certain PHP extensions.
>
> <cite>[Composer - Official Image | Docker Hub](https://hub.docker.com/_/composer)</cite>

なのでこの方法は

- とりあえず試したい
- ローカルを汚さず `composer install` をクリアしたい
- 実行環境は特に問わないライブラリの開発を行いたい

など、限られた場合で使うべきだろう。

そうでなく、自身で PHP 環境をホストしてアプリケーションを提供する場合は、[前述のブログ記事](https://blog.hanhans.net/2019/01/08/docker-composer/)にあるように、その環境に

```Dockerfile
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
```

で composer 本体をコピーしてコマンドを実行する方法が良いだろう。（それでも[インストーラーをダウンロードしてごにゃごにゃするやり方](https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md)よりはかなり良い）
