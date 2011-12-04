#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw!$Bin!;
use lib "$Bin/lib";
use DynUpdate::Daemon;

my $daemon = DynUpdate::Daemon->new_with_options(
	#username => 'delphinus',
	#password => 'mFjZ4V8uZvWovkjY',
	hostname => 'remora.cx',
	username => 'username',
	password => 'password',
	pidbase  => "$Bin/run",
);

$daemon->log('Info', 'START!');

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
