#!/usr/bin/perl -w

use Net::DRI::DRD::ICANN;

use Test::More tests => 10;

is(Net::DRI::DRD::ICANN::is_reserved_name('whatever.foo'),0,'whatever.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.foo'),1,'icann.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('icann.bar.foo'),1,'icann.bar.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab--cd.foo'),1,'ab-cd.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('a.foo'),1,'a.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('ab.foo'),1,'ab.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('biz.foo'),1,'biz.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.biz'),0,'foo.biz');
is(Net::DRI::DRD::ICANN::is_reserved_name('www.foo'),1,'www.foo');
is(Net::DRI::DRD::ICANN::is_reserved_name('foo.www'),0,'foo.www');

exit 0;
