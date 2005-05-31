#!/usr/bin/perl -w

use Net::DRI::Protocol::Gandi::Web::Message;

use Test::More tests=>8;


can_ok('Net::DRI::Protocol::Gandi::Web::Message','version','method','params','oname','otype','command','result','errcode','errmsg','pagecontent');

my $m=Net::DRI::Protocol::Gandi::Web::Message->new();

isa_ok($m,'Net::DRI::Protocol::Gandi::Web::Message');
is_deeply($m->params,[],'default params');
is($m->errcode(),undef,'default errcode');
is($m->errmsg(),'','default errmsg');
is($m->is_success(),0,'default is_success');

$m->errcode(1000);
is($m->is_success(),1,'is_success for errcode=1000');

TODO: {
	local $TODO="tests on result_status() get_name_from_message()";
	ok(0);
}

exit 0;
