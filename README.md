Dyn.com アップデートスクリプト
==============================
ダイナミック DNS サービス [Dyn.com][dyn.com] の IP アドレスを定期的に監視し、ルータの再起動などで IP アドレスが変わったときに、自動で IP アドレスを更新します。要するに公式の [ddclient][ddclient] の動作を模したものです。

使い方
------

### 書式

    dynupdate -u (ユーザー名) -p (パスワード) -h (ホスト名) (start|stop|restart|status)

* [Dyn.com][dyn.com] で登録したユーザー名とパスワード、及び、IP アドレスを更新したいホスト名を指定します。
* 15 分ごとに新しい IP アドレスになっていないか確認し、もし新しい IP アドレスが得られれば、更新を行います。更新間隔は変更可能です。
* スクリプトがあるディレクトリを基準として `./logs/dynupdate.log` というファイルにログを吐きます。ファイル名及びディレクトリは変更可能です。
* デフォルトではバックグラウンドで動作しますが、`-f, --forground` オプションを付けるとフォアグラウンドで動作し、標準出力にログを吐きます。
* `-1, --once` オプションを付けると一度だけ確認 & 更新を行って終了します。__（実験的機能）__

### 例

    dynupdate -u delphinus35 -p some_pass -h test.remora.cx -i 3600 -u http://detect.example.com/ restart

* 次の設定で更新を行います。もしすでにプロセスが起動していれば再起動します。  
  - ユーザー名 : `delphinus35`
  - パスワード : `some_pass`
  - ホスト名 : `test.remora.cx`
  - 更新確認間隔 : 1 時間
  - IP アドレス確認に使う URL : `http://detect.example.com/`

オプション一覧
--------------

### 必須オプション

* `-u, --username`  
  `-p, --password`  
  `-h, --hostname`  
  [Dyn.com][dyn.com] で登録したユーザー名・パスワード・ホスト名です。

### 必須でないオプション

* `-u, --detect_uri Default : http://checkip.dyndns.org/`  
  IP アドレスの確認に使用する URL です。標準では [Dyn.com][dyn.com] が提供するサービスを使用します。

* `-i, --interval Default : 900`  
  IP アドレスの確認間隔を指定します。標準値は 15 分です。余り頻繁に確認するとサーバーに負荷がかかるため、[Dyn.com][dyn.com] の確認サービスを利用する場合はこれより低い値に設定しない方が良いようです。  
  もし、独自の確認サービスを用意する場合は、次のようなリプライを返すようにしてください。（以下、[CheckIP Tool - Dyn][checkip] より引用）

```html
HTTP/1.1 200 OK
Content-Type: text/html
<html><head><title>Current IP Check</title></head><body>Current IP Address: 123.456.78.90</body></html>
```

* `-m, --my_ip`  
  更新に使用する IP アドレスを確認サービスで得るのではなく、指定した値を使用します。

* `-l, --log_file Default : ./logs/dynupdate.log`  
  ログファイル名を指定します。

* `--pidbase Default : ./run`  
  デーモンの pid ファイルを置くディレクトリを指定します。

* `-d, --debug`  
  デバッグメッセージを出力します。

### 実験的なオプション

* `-1, --once`  
  一度だけ IP アドレスの更新処理を実行して終了します。

* `--wildcard`  
  `--mx`  
  `--backmx`  
  `--offline`  
  様々なレコードを更新できますが、[Dyn.com][dyn.com] で未実装のものも有るようで検証はできていません。

[dyn.com]: http://dyn.com/ "Managed DNS | Email Delivery | SMTP | Domain Registration"
[ddclient]: http://sourceforge.net/apps/trac/ddclient "ddclient"
[checkip]: http://dyn.com/support/developers/checkip-tool/ "CheckIP Tool - Dyn"

