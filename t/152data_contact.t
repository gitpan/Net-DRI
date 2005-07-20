#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::Contact;

use Test::More tests => 3;

can_ok('Net::DRI::Data::Contact',qw/new id validate name org street city sp pc cc email voice fax loid roid srid auth disclose/);

my $s=Net::DRI::Data::Contact->new();
isa_ok($s,'Net::DRI::Data::Contact');

TODO: {
        local $TODO="tests on validate()";
        ok(0);
}

exit 0;
