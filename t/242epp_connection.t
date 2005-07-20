#!/usr/bin/perl -w

use Net::DRI::Protocol::EPP::Connection;

use Test::More tests => 2;

can_ok('Net::DRI::Protocol::EPP::Connection',qw(login logout keepalive is_greeting_successful is_login_successful is_server_close get_data));

TODO: {
        local $TODO="tests on login() logout() keepalive() is_greeting_successful() is_login_successful() is_server_close() get_data() find_code()";
        ok(0);
}


exit 0;
