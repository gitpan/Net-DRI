#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::StatusList;

use Test::More tests => 13;


my $s=Net::DRI::Data::StatusList->new();
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),1,'is_empty() 1');

$s=Net::DRI::Data::StatusList->new('p','1.0');
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),1,'is_empty() 2');

$s=Net::DRI::Data::StatusList->new('p','1.0','ACTIVE');
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),0,'is_empty() 0');
is_deeply([$s->list_status()],['ACTIVE'],'list_status()');

$s=Net::DRI::Data::StatusList->new('p','1.0',{name => 'ACTIVE', lang=>'en', msg => 'Test' });
isa_ok($s,'Net::DRI::Data::StatusList');
is($s->is_empty(),0,'is_empty() 0');
is_deeply([$s->list_status()],['ACTIVE'],'list_status()');

$s->add('WHATEVER');
is($s->has_any('WHATEVER'),1,'has_any()');
is($s->has_not('ACTIVE'),0,'has_not()');

can_ok('Net::DRI::Data::StatusList','is_active','is_published','is_pending','is_linked','can_update','can_transfer','can_delete','can_renew');

exit 0;
