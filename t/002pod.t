#!/usr/bin/perl -w

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @poddirs = qw( ../blib blib ../lib lib );
all_pod_files_ok(all_pod_files(@poddirs));
