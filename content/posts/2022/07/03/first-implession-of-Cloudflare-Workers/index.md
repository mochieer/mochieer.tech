---
title: "Cloudflare Workers のファーストインプレッション"
date: "2022-07-03T00:00:00+09:00"
tags:
  - プログラミング
  - Cloudflare
  - エッジコンピューティング
---

かねてより評判の良い Cloudflare Workers を使ってみた。

- [Cloudflare Workers](https://workers.cloudflare.com/)
- [Cloudflare Workers documentation · Cloudflare Workers docs](https://developers.cloudflare.com/workers/)

以下の簡単な Web API を作った。リクエストのパスやクエリパラメータに応じて動的な SVG を返却する、というものだ。

- [mochieer/alteremoji: Generates an SVG that displays any number (even decimals) of emojis.](https://github.com/mochieer/alteremoji)
- [半端なサイズの絵文字を表示する技術](https://zenn.dev/mochieer/articles/4e1eef9de8c64e)

***

まず、開発者体験が非常に優れている。

wrangler という CLI を使うのだが、これが npm （または yarn）でインストールできる。認証、プロジェクトの作成、ローカルでの実行、デプロイまで全部これで完結していて、何も迷うことがない。

また、プロジェクトの作成時に TypeScript を選ぶと、作成された `index.ts` には `Request` を受けて `Response` を返すハローワールドが書き出されるので、それぞれの型定義を参照しつつ自分の作りたい `Request => Response` な関数を書いてあげればいいだけのイメージで、特定のインフラに依存しているという感覚が一切なかった。

TypeScript のコンパイルやファイルのバンドルは wrangler がやってくれているようで、 `wrangler dev`, `wrangler publish` とは別に webpack を動かさなきゃ、みたいなことはない。

おそらく普段から TypeScript を書いていればほとんどつまずくポイントはないように思う。フロントエンドエンジニアにとってネットワークやミドルウェアは心理的にハードルが高いが、丁寧に TypeScript をサポートしてくれていて、実際にはほとんどハードルなんてものはない。

***

出来上がったものはだいたい以下のようになった。

```ts
export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    try {
      return AlterEmojiResponse.createFromRequest(
        AlterEmojiRequest.createFromCloudflareWorkersRequest(request)
      ).toCloudflareWorkersResponse()
    } catch (_) {
      return AlterEmojiResponse.asError().toCloudflareWorkersResponse()
    }
  },
};

class AlterEmojiRequest {
  static createFromCloudflareWorkersRequest(req: Request): AlterEmojiRequest {
    return new AlterEmojiRequest(req.url)
  }

  constructor(
    private requestUrl: string
  ) {}

  /* ... */
}

class AlterEmojiResponse {
  static createFromRequest(req: AlterEmojiRequest): AlterEmojiResponse {
    return new AlterEmojiResponse(req.emoji, req.count, req.size)
  }

  static asError(): AlterEmojiResponse {
    return new AlterEmojiResponse('🤮', 1, 24)
  }

  constructor(
    private emoji: string,
    private count: number,
    private size: number
  ) {}

  toCloudflareWorkersResponse(): Response {
    return new Response(this.toString(), {
      headers: {
        'Content-Type': 'image/svg+xml',
        'Vary': 'Accept-Encoding',
      },
    })
  }

  /* ... */
}
```

一応、 Cloudflare Workers への依存はメインの関数のみにして、独自の Request, Response を実装している。どんな小さなプロジェクトでもインフラやフレームワークへの依存とビジネスロジックは混ぜるべきではない。

***

作ってみて、開発者体験的には最高だったのだが、さて、これはエッジでやる必要があったのか考えると、やや疑問であった。普通に Lambda 的な FaaS で良いのではないか、と。

ユーザーに近いエッジサーバーで実行されるのでレスポンスが早いというメリットは確かにある。が、別に Lambda の前に CloudFront がいれば同一リクエストに対してはキャッシュを返せるので応答速度的には劣っているとは言い切れない。

と思っていたらちょうど Twitter で興味深いやり取りがあった。

> deno deploy や cloudflare workers、ts 好きな人達なんでもっと使って遊ばないんだろうと思ってる。
> <cite>https://twitter.com/mattn_jp/status/1543217325998231552</cite>

> クライアントとサーバーの間に処理を置けたらいいのになぁ。ってクライアントの人が思うのかどうか。ワーカーだけで完結しようとするのは戦略として違う。
> <cite>https://twitter.com/voluntas/status/1543220179139964928</cite>

> なので Worker をサーバーとみなすのも違くてあれは前処理や後処理ができる Proxy なのです。それを踏まえて実装しないとダメなので興味持つ人が少ない気がする。
> <cite>https://twitter.com/voluntas/status/1543220798336679936</cite>

なるほど、そう考えると今回実装したレスポンスを自ら生成するのはむしろ邪道なようだ。

用途としては、

- リバプロ的にオリジンサーバーにリクエストを捌きつつ、ログサーバーにもログを送信する
- 特定の時間だけ S3 的なところに置いている静的なメンテナンスページを返す
- User-Agent に応じて独自ヘッダーを付けてオリジンサーバーに渡す
- 成功時には何もしないがオリジンが500系エラーを返したときだけ、ヘッダーやパスに応じてエラーメッセージを差し替える

みたいなのが王道のようだ。

調べてみると [@cloudflare/worker-sentry](https://github.com/cloudflare/worker-sentry#example) なんてものがあるようで、例としてまさにオリジンがエラーを返したときだけ Sentry に流すようなことをしている。確かにオリジンが本当に死んでしまったらエラーすら送信されないので、何らか別の方法で死活監視をしないと、というのは監視のジレンマなので、リバプロがエラーを吐いてくれると嬉しいように思う。

***

まとめると、

- とてもハードルが低い
  - 普段 JS/TS を書いているフロントエンドエンジニアはほぼ何も考えずに動かせる
- 一方で、「クライアントとサーバーの間に処理を置けたらいいのになぁ」というときに利用すると強力
  - フロントエンド視点ではなくではなくシステムとして見たときに、実は proxy にも処理を書けるんだよ、という視点を持てることが大事

のようだ。
