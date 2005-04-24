#!/usr/bin/perl -w

use strict;

use Net::DRI::Cache;

use Test::More tests => 8;

my $c;

$c=Net::DRI::Cache->new(-1);
isa_ok($c,'Net::DRI::Cache');

$c->set('regname','type','key',{w=>'a'});
is_deeply($c->{data},{},'nothing in cache if negative TTL');

my $c2=Net::DRI::Cache->new(1);
$c=Net::DRI::Cache->new(100); ## cache of 100 seconds
isa_ok($c->set('regname','domain','example.foo',{'whatever' => 'whatever2'}),'HASH','set');
is($c->get('domain','example.foo','whatever','regname'),'whatever2','get from cache 1');
is($c->get('domain','example.foo','whatever','regname2'),undef,'get from cache 2');
isa_ok($c->set('regname','domain','example.foo',{'whatever2' => 'whatever22'},1),'HASH','set for 1 second');
sleep(1);
is($c->get('domain','example.foo','whatever2','regname'),undef,'get from cache after expiry');

$c2->delete_expired();
is_deeply($c2->{data},{},'empty cache after delete_expired');

exit 0;
