## Domain Registry Interface, nic.at domain transactions extension
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Core::Domain;

our $VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/g ); sprintf( "%d" . ".%02d" x $#r, @r ); };
our $NS = 'http://www.nic.at/xsd/at-ext-domain-1.0';
our $ExtNS = 'http://www.nic.at/xsd/at-ext-epp-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Domain - NIC.AT EPP Domain extension

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>.
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
               nocommand        => [ \&extonly,          undef ],
               delete           => [ \&delete,           undef ],
               transfer_request => [ \&transfer_request, undef ],

       );

       return { 'domain' => \%tmp };
}

####################################################################################################

sub extonly {
       my ( $epp, $domain, $rd ) = @_;

       my $transaction = $rd->{transactionname} if $rd->{transactionname};

       return unless ($transaction);

       my $mes = $epp->message();

       my @d =
         Net::DRI::Protocol::EPP::Core::Domain::build_command( $mes, 'nocommand',
               $domain );
       $mes->command_body( \@d );

       my $eid = $mes->command_extension_register( 'command',
                   'xmlns="' . $ExtNS
                 . '" xsi:schemaLocation="'
                 . $ExtNS
                 . ' at-ext-epp-1.0.xsd"' );


       # we have to create the cltrid

       my $cltrid=Net::DRI::Util::create_trid_1('NICAT');

       if ( $transaction eq 'withdraw' ) {

               my %domns;
               $domns{'xmlns:domain'}       = $NS;
               $domns{'xsi:schemaLocation'} = $NS . ' at-ext-domain-1.0.xsd';

			 	my %zdhash;
				$zdhash{'value'} = $rd->{zd} ? $rd->{zd} : 0;
				
	           $mes->command_extension(
               $eid,

                       [
                               ['withdraw',
                               [ 'domain:withdraw',  ['domain:name', $domain], \%domns ,
                               						  ['domain:zd', \%zdhash], \%domns  ]],
                               ['clTRID', $cltrid ]

                       ]
               );


       }
       elsif ( $transaction eq 'transfer_execute' ) {


               my $token = $rd->{token} if $rd->{token};

       return unless ( defined($token) );

               my %domns;
               $domns{'xmlns:domain'}       = 'urn:ietf:params:xml:ns:domain-1.0';
               $domns{'xsi:schemaLocation'} = 'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd';

               my %domns2;
               $domns2{'xmlns:at-ext-domain'}       = $NS;
               $domns2{'xsi:schemaLocation'} = $NS . ' at-ext-domain-1.0.xsd';



               $mes->command_extension(
               $eid,
                       [
                               ['transfer',

                                       { 'op' => 'execute' },
                                       [ 'domain:transfer', \%domns, [ 'domain:name', $domain ]
                                       ]
                               ],
                               ['extension',
                                  ['at-ext-domain:transfer' , \%domns2, ['at-ext-domain:token',$token]
                                  ]
                               ],
                               ['clTRID', $cltrid]
                       ]
               );

       }
}

sub delete {

       my ( $epp, $domain, $rd ) = @_;
       my $mes = $epp->message();

       my $scheduledate = $rd->{scheduledate} if $rd->{scheduledate};

       return unless ( defined($scheduledate) );

       my $eid = $mes->command_extension_register( 'at-ext-domain:delete',
                   'xmlns:at-ext-domain="' . $NS
                 . '" xsi:schemaLocation="'
                 . $NS
                 . ' at-ext-domain-1.0.xsd"' );

       $mes->command_extension( $eid,
               [ 'at-ext-domain:scheduledate', $scheduledate ] );
}

sub transfer_request {
       my ( $epp, $domain, $rd ) = @_;
       my $mes = $epp->message();

       my $registrarinfo = $rd->{registrarinfo} if $rd->{registrarinfo};

       return unless ( defined($registrarinfo) );

       my $eid = $mes->command_extension_register( 'at-ext-domain:clientdata',
                   'xmlns:at-ext-domain="' . $NS
                 . '" xsi:schemaLocation="'
                 . $NS
                 . ' at-ext-domain-1.0.xsd"' );

       my %entryname;
       $entryname{name} = "Registrarinfo";
       $mes->command_extension( $eid,
               [ 'at-ext-domain:entry', \%entryname, $registrarinfo ] );

}

####################################################################################################
1;
