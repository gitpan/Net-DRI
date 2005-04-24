#!/usr/bin/perl -w

use Net::DRI::Protocol::ResultStatus;

use Test::More tests => 16;

my $n;
$n=Net::DRI::Protocol::ResultStatus->new('epp',1000,{},1,'Command completed successfully');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->is_success(),1,'epp is_success');
is($n->native_code(),1000,'epp native_code');
is($n->code(),1000,'epp code');
is($n->message(),'Command completed successfully','epp message');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',200,{'rrp'=>{200=>1000}},1,'Command completed successfully');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->is_success(),1,'rrp is_success');
is($n->native_code(),200,'rrp native_code');
is($n->code(),1000,'rrp code');
is($n->message(),'Command completed successfully','rrp message');

$n=Net::DRI::Protocol::ResultStatus->new('foobar');
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),2900,'foobar code');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',0,{'rrp'=>{}},0);
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),2900,'rrp undef not success code');

$n=Net::DRI::Protocol::ResultStatus->new('rrp',1,{'rrp'=>{}},1);
isa_ok($n,'Net::DRI::Protocol::ResultStatus');
is($n->code(),1900,'rrp undef success code');

exit 0;
