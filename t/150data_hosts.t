#!/usr/bin/perl -w

use Net::DRI::Data::Hosts;

use Test::More tests => 10;

my $d=Net::DRI::Data::Hosts->new();
isa_ok($d,'Net::DRI::Data::Hosts');

$d=Net::DRI::Data::Hosts->new('ns.example.foo',['1.2.3.4','1.2.3.5']);
isa_ok($d,'Net::DRI::Data::Hosts');
is($d->count(),1,'count()');
my @c;
@c=$d->get_details(1);
is_deeply($c[1],['1.2.3.4','1.2.3.5']);

$d=Net::DRI::Data::Hosts->new('ns.example.foo',['1.2.3.4','1.2.3.4']);
isa_ok($d,'Net::DRI::Data::Hosts');
@c=$d->get_details(1);
is_deeply($c[1],['1.2.3.4'],'remove dups IP');
is(($d->get_names(1))[0],'ns.example.foo','get_names()');

$d->add('ns2.example.foo',['1.2.10.4']);
@c=$d->get_names();
is_deeply(\@c,['ns.example.foo','ns2.example.foo'],'get_names() after add');
@c=$d->get_names(2);
is_deeply(\@c,['ns.example.foo','ns2.example.foo'],'get_names(2) after add');
@c=$d->get_names(1);
is_deeply(\@c,['ns.example.foo'],'get_names(1) after add');


warn("TODO: add() with other params");
warn("TODO: new_set()");
warn("TODO: is_empty");


exit 0;
