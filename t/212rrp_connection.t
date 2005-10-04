#!/usr/bin/perl -w

use Net::DRI::Protocol::RRP::Connection;

use Test::More tests => 2;

can_ok('Net::DRI::Protocol::RRP::Connection',qw(login logout keepalive parse_greeting parse_login parse_logout get_data));

TODO: {
        local $TODO="tests on login() logout() keepalive() parse_greeting() parse_login() parse_logout() get_data() find_code()";
        ok(0);
}


exit 0;
