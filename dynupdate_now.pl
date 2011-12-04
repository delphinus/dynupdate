#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use DynUpdate;

DynUpdate->new(
	username => 'delphinus',
	password => 'mFjZ4V8uZvWovkjY',
	#hostname => 'remora.cx',
	hostname => 'aaa.remora.cx',
)->run;
