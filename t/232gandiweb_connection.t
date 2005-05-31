#!/usr/bin/perl -w

use Net::DRI::Protocol::Gandi::Web::Connection;

use Test::More tests => 2;

can_ok('Net::DRI::Protocol::Gandi::Web::Connection',qw(sleep login logout));

TODO: {
        local $TODO="tests on login() logout()";
        ok(0);
}


exit 0;
