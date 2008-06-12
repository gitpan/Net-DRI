## Domain Registry Interface, .NO Host extensions
##
## Copyright (c) 2008 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
##                    All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::NO::Host;

use strict;
use Net::DRI::Util;

our $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/gmx ); sprintf( "%d" . ".%02d" x $#r, @r ); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Host - .NO Host Extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
    my ( $class, $version ) = @_;
    my %tmp = (
        create => [ \&create, undef ],
        update => [ \&update, undef ],
        info   => [ \&info,   \&parse_info ],
    );

    return { 'host' => \%tmp };
}

####################################################################################################

sub capabilities_add {
    return { 'host_update' => { 'contact' => ['set'] } };
}

sub parse_info {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my @ns = @{ $mes->ns->{no_host} };
    my $NS = $ns[0];

    my $condata = $mes->get_content( 'infData', $NS, 1 );
    return unless $condata;

    my @e = $condata->getElementsByTagNameNS( $NS, 'contact' );
    return unless @e;

    # Contact is a single scalar
    my $t = $e[0];
    if ( my $ct = $t->getFirstChild()->getData() ) {
        $rinfo->{host}->{$oname}->{contact} = $ct;
    }
    return;
}

sub build_command_extension {
    my ( $mes, $epp, $tag ) = @_;

    my @ns = @{ $mes->ns->{no_host} };
    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-host="%s" xsi:schemaLocation="%s %s"',
            $ns[0], $ns[0], $ns[1]
        )
    );
}

sub info {
    my ( $epp, $ho, $rd ) = @_;
    my $mes = $epp->message();

    return unless ( exists( $rd->{ownerid} ) );

    my $eid = build_command_extension( $mes, $epp, 'no-ext-host:info' );

    my @e;

    # Contact shall be a single scalar!
    push @e, [ 'no-ext-host:ownerID', $rd->{ownerid} ];

    return $mes->command_extension( $eid, \@e );
}

sub create {
    my ( $epp, $ho, $rd ) = @_;
    my $mes = $epp->message();

    return unless ( exists( $rd->{contact} ) && $rd->{contact} );

    my $eid = build_command_extension( $mes, $epp, 'no-ext-host:create' );

    my @e;

    my $c = $rd->{contact};
    my $srid;

    # $c may be a contact object or a direct scalar
   if (   Net::DRI::Util::has_contact( $rd ) )
    {
        my @o = $c->get('contact');
        $srid = $o[0]->srid() if (@o);
    } else {

        # Contact shall be a single scalar!
        $srid = $c;
    }
    push @e, [ 'no-ext-host:contact', $srid ];
    return $mes->command_extension( $eid, \@e );

}

sub build_contact_noregistrant {
    my ( $epp, $cs ) = @_;
    my @d;

    # All nonstandard contacts go into the extension section
    my %r = map { $_ => 1 } $epp->core_contact_types();
    foreach my $t ( sort( grep { exists( $r{$_} ) } $cs->types() ) ) {
        my @o = $cs->get($t);
        push @d,
            map { [ 'domain:contact', $_->srid(), { 'type' => $t } ] } @o;
    }
    return @d;
}

sub update {
    my ( $epp, $ho, $todo ) = @_;
    my $mes = $epp->message();

    my $ca = $todo->add('contact');
    my $cd = $todo->del('contact');

    return unless ( $ca || $cd );    # No updates asked

    my $eid = build_command_extension( $mes, $epp, 'no-ext-host:update' );

    my ( @n, @s );

    if ( defined($ca) && $ca ) {
        push @s, [ 'no-ext-host:contact', $ca ];
        push @n, [ 'no-ext-host:add', @s ] if ( @s > 0 );
    }
    @s = undef;
    if ( defined($cd) && $cd ) {
        push @s, [ 'no-ext-host:contact', $cd ];
        push @n, [ 'no-ext-host:rem', @s ] if ( @s > 0 );
    }
    return $mes->command_extension( $eid, \@n );
}

####################################################################################################
1;
