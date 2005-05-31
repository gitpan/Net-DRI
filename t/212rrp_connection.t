#!/usr/bin/perl -w

use Net::DRI::Protocol::RRP::Connection;

use Test::More tests => 2;

can_ok('Net::DRI::Protocol::RRP::Connection',qw(login logout keepalive is_login_successfull is_end_command is_server_close)); ## we do not test find_code, it is only an internal function

TODO: {
        local $TODO="tests on login() logout() keepalive() is_login_successfull() is_end_command() is_server_close() find_code()";
        ok(0);
}


exit 0;
