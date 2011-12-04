#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use DynUpdate;

DynUpdate->new(
	username => 'username',
	password => 'password',
	hostname => 'myhost',
)->run;
