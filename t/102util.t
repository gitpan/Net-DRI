#!/usr/bin/perl -w

use Test::More tests => 240;

use Net::DRI::Util;

is(Net::DRI::Util::all_valid(undef,1,'A'),0,'all_valid() with one undef');
is(Net::DRI::Util::all_valid('B',undef,2,undef),0,'all_valid() with two undef');
is(Net::DRI::Util::all_valid(),1,'all_valid() empty');
is(Net::DRI::Util::all_valid(67,'AB'),1,'all_valid() not empty');

is(Net::DRI::Util::isint(-6),0,'isint(-6)');
is(Net::DRI::Util::isint(6),1,'isint(6)');
is(Net::DRI::Util::isint(67886),1,'isint(67886)');
is(Net::DRI::Util::isint('A'),0,'isint(A)');

is(Net::DRI::Util::check_equal(),undef,'check_equal()');
is(Net::DRI::Util::check_equal('A','A'),'A','check_equal(A,A)');
is(Net::DRI::Util::check_equal('A',['A']),'A','check_equal(A,[A])');
is(Net::DRI::Util::check_equal('A',['B','A']),'A','check_equal(A,[B,A])');
is(Net::DRI::Util::check_equal('A','C','def'),'def','check_equal(A,C,def)');
is(Net::DRI::Util::check_equal('A','C'),undef,'check_equal(A,C)');

eval { Net::DRI::Util::check_isa(bless({},'FooBar'),'FooBuz'); };
isa_ok($@,'Net::DRI::Exception','check_isa(FooBar,FooBuz)');
is(Net::DRI::Util::check_isa(bless({},'FooBar'),'FooBar'),1,'check_isa(FooBar,FooBuz)');

like(Net::DRI::Util::microtime(),qr/^\d{16}$/,'microtime()');
like(Net::DRI::Util::create_trid_1('name'),qr/^NAME-\d+-\d{16}$/,'create_trid_1(name)');


is(Net::DRI::Util::is_hostname(),0,'is_hostname()');
is(Net::DRI::Util::is_hostname('.'),0,'is_hostname(.)');
is(Net::DRI::Util::is_hostname('a.'),0,'is_hostname(a.)');
is(Net::DRI::Util::is_hostname('.a'),0,'is_hostname(.a)');
is(Net::DRI::Util::is_hostname('a..b'),0,'is_hostname(a..b)');
is(Net::DRI::Util::is_hostname('a.foo'),1,'is_hostname(a.foo)');
is(Net::DRI::Util::is_hostname('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.foo'),1,'is_hostname(abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyabcdefghijk.foo)');
is(Net::DRI::Util::is_hostname('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.foo'),0,'is_hostname(abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyabcdefghijkl.foo)');
is(Net::DRI::Util::is_hostname('-a.foo'),0,'is_hostname(-a.foo)');
is(Net::DRI::Util::is_hostname('a-.foo'),0,'is_hostname(a-.foo)');
is(Net::DRI::Util::is_hostname('a-b.foo'),1,'is_hostname(a-b.foo)');
is(Net::DRI::Util::is_hostname('a_b.foo'),0,'is_hostname(a_b.foo)');
is(Net::DRI::Util::is_hostname('a b.foo'),0,'is_hostname(a b.foo)');
foreach (0..255)
{
 next if ($_==45) || ($_==46) || (($_>=48) && ($_<=57)) || (($_>=65) && ($_<=90)) || (($_>=97) && ($_<=122));
 my $d='a'.chr($_).'b.foo';
 is(Net::DRI::Util::is_hostname($d),0,"is_hostname($d)");
}

is(Net::DRI::Util::is_ipv4(),0,'is_ipv4()');
is(Net::DRI::Util::is_ipv4('ab'),0,'is_ipv4(ab)');
is(Net::DRI::Util::is_ipv4('256.1.2.3'),0,'is_ipv4(256.1.2.3)');
is(Net::DRI::Util::is_ipv4('1.2.3'),0,'is_ipv4(1.2.3)');
is(Net::DRI::Util::is_ipv4('1.2.3.7.8'),0,'is_ipv4(1.2.3.7.8)');
is(Net::DRI::Util::is_ipv4('1.ab.6.7'),0,'is_ipv4(1.ab.6.7)');
is(Net::DRI::Util::is_ipv4('1.2.3.4'),1,'is_ipv4(1.2.3.4)');
is(Net::DRI::Util::is_ipv4('1.2.3.4',1),1,'is_ipv4(1.2.3.4,1)');
is(Net::DRI::Util::is_ipv4('0.1.2.3',1),0,'is_ipv4(0.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('10.1.2.3',1),0,'is_ipv4(10.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('127.1.2.3',1),0,'is_ipv4(127.1.2.3,1)');
is(Net::DRI::Util::is_ipv4('169.254.6.7',1),0,'is_ipv4(169.254.6.7,1)');
is(Net::DRI::Util::is_ipv4('172.16.1.2',1),0,'is_ipv4(172.16.1.2,1)');
is(Net::DRI::Util::is_ipv4('172.33.1.2',1),1,'is_ipv4(172.33.1.2,1)');
is(Net::DRI::Util::is_ipv4('192.0.2.6',1),0,'is_ipv4(192.0.2.6,1)');
is(Net::DRI::Util::is_ipv4('192.168.1.3',1),0,'is_ipv4(192.168.1.3)');
is(Net::DRI::Util::is_ipv4('230.0.0.0',1),0,'is_ipv4(230.0.0.0,1)');


warn("TODO: tests on is_ipv6");
warn("TODO: tests on compare_duration");

exit 0;
