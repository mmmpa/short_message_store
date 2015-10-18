# Short Message Store

メッセージをためて、送信して、削除する。

# 必要環境変数

Redisまわりがあれば動くはず。

変数名|目的
:---|:---
BASIC_AUTH_USERNAME|ベーシック認証のID
BASIC_AUTH_PASSWORD|ベーシック認証のパスワード
ENV|productionとか。redis-namespace用
FROM_ADDRESS|rake sweeper:sendの送り主と送り先
TO_ADDRESS|rake sweeper:sendの送り先
REDIS_HOST|RedisのURL
REDIS_PORT|Redisのポート番号
SENDGRID_DOMAIN|SendGrid設定用
SENDGRID_USER_NAME|SendGrid設定用
SENDGRID_USER_PASSWORD|SendGrid設定用

# 注意

`rake sweeper:sweep!`と`rake sweeper:send_and_sweep!`は`Redis.current.flushall`するので本気で全部消えます。
