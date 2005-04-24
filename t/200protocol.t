#!/usr/bin/perl -w

use Net::DRI::Protocol;

use Test::More tests => 6;

my $p;
$p=Net::DRI::Protocol->new();
isa_ok($p,'Net::DRI::Protocol');
is($p->message(),undef,'empty message at init');
is_deeply($p->capabilities(),{},'empty capabilities at init');

$p->name('myname');
$p->version('1.5');

is($p->name(),'myname','name()');
is($p->version(),'1.5','version()');
is($p->nameversion(),'myname/1.5','nameversion()');

warn("TODO: create_status & others");
## factories, commands



exit 0;
