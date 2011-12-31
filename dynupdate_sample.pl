#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use URI;

# 定数
my $username = 'username';
my $password = 'password';
my $hostname = 'my.example.com';
my $myip     = 'xxx.xxx.xxx.xxx';

my $dyndns   = 'members.dyndns.org';
my $ua_str   = 'delphinus@remora.cx - dynupdate.pl - sample';

# URI オブジェクト
my $uri = URI->new;
$uri->scheme('https');
$uri->host('members.dyndns.org');
$uri->path('/nic/update');
$uri->query_form(
    hostname => $hostname,
    myip     => $myip,
);

# HTTP リクエスト
my $req = HTTP::Request->new;
$req->method('GET');
$req->uri($dyndns);
$req->protocol('HTTP/1.0');
$req->authorization_basic($username, $password);

# クエリ開始
my $ua = UserAgent->new;
$ua->env_proxy;
$ua->agent($ua_str);

# HTTP レスポンス
my $res = $ua->request($req);

# アクセス失敗
$res->is_success or die 'update failed : ' . $res->status_line;

# アクセス成功
my ($status, $ip_address) = $content =~ /(\w+)(?: (\d+\.\d+\.\d+\.\d+))?/;

# アップデート成功
if ($status eq 'good') {
    print "update successded : $ip_address\n";

# IP アドレスは変更無し
} elsif ($status eq 'nochg') {
    print "not need to be updated.\n";

# アップデート失敗
} else {
    print "update failed : $ip_address\n";
}
