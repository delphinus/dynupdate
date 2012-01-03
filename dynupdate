#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw!$Bin!;
use lib "$Bin/lib";
use DynUpdate::Daemon;

my $daemon = DynUpdate::Daemon->new_with_options(
    username => 'username',
    password => 'password',
    hostname => 'myhost',
    pidbase  => "$Bin/run",
);

my $opt_str = 'stop|start|status|restart';

my ($opt) = @{$daemon->extra_argv};
if (defined $opt and -1 < index $opt_str, $opt) {
    $daemon->$opt;
    warn $daemon->status_message . "\n";
    exit $daemon->exit_code;

} else {
    warn "usage: $0 {$opt_str}\n";
    exit -1;
}
