## Domain Registry Interface, .NO policies for Net::DRI
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
#########################################################################################

package Net::DRI::DRD::NO;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/gxm ); sprintf( "%d" . ".%02d" x $#r, @r ); };

=pod

=head1 NAME

Net::DRI::DRD::NO - .NO policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen E<lt>info@norid.noE<gt>

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

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);
    $self->{info}->{host_as_attr} = 0;    # means make host objects
    $self->{info}->{use_null_auth}= 1;    # means using domain:null for empty authinfo password

    bless( $self, $class );
    return $self;
}

sub periods {
    return map { DateTime::Duration->new( years => $_ ) } (1);
}
sub name         { return 'NORID'; }
sub tlds         { return ('NO'); }
sub object_types { return ( 'domain', 'contact', 'ns' ); }

sub transport_protocol_compatible {
    my ( $self, $to, $po ) = @_;
    my $pn = $po->name();
    my $tn = $to->name();

    return 1 if ( ( $pn eq 'EPP' ) && ( $tn eq 'socket_inet' ) );
    return;
}

sub transport_protocol_default {
    my ( $drd, $ndr, $type, $ta, $pa ) = @_;
    $type = 'epp' if ( !defined($type) || ref($type) );
    return Net::DRI::DRD::_transport_protocol_default_epp(
        'Net::DRI::Protocol::EPP::Extensions::NO',
        $ta, $pa )
        if ( $type eq 'epp' );

# suppress until whois is supported
#return ('Net::DRI::Transport::Socket',[{%Net::DRI::DRD::PROTOCOL_DEFAULT_WHOIS,remote_host=>'whois.norid.no'}],'Net::DRI::Protocol::Whois',[]) if (lc($type) eq 'whois');

    return;
}

#########################################################################
# need to accept all tlds for hosts, so subclass this method and
# remove the tld check
sub verify_name_host {
    my ( $self, $ndr, $host, $checktld ) = @_;
    $checktld ||= 0;
    ( $host, $checktld ) = ( $ndr, $host )
        unless ( defined($ndr)
        && $ndr
        && ( ref($ndr) eq 'Net::DRI::Registry' ) );

    $host = $host->get_names(1) if ( ref($host) );
    my $r = $self->check_name($host);
    return $r if ($r);
    return 0;
}

sub verify_name_domain {
    my ( $self, $ndr, $domain ) = @_;
    $domain = $ndr
        unless ( defined($ndr)
        && $ndr
        && ( ref($ndr) eq 'Net::DRI::Registry' ) );

    my $r = $self->SUPER::check_name($domain);
    return $r if ($r);
    return 10 unless $self->is_my_tld($domain);

    my @d = split( /\./mx, $domain );
    return 12 if length( $d[0] ) < 2;
    return 14 if exists($Net::DRI::Util::CCA2{uc($d[0])});

    return 0;
}

sub verify_duration_renew {
    my ( $self, $ndr, $duration, $domain, $curexp ) = @_;
    ( $duration, $domain, $curexp ) = ( $ndr, $duration, $domain )
        unless ( defined($ndr)
        && $ndr
        && ( ref($ndr) eq 'Net::DRI::Registry' ) );

    if ( defined($duration) ) {
        my ( $y, $m ) = $duration->in_units( 'years', 'months' );

        ## Only 1..12m or 1y allowed in a renew
        unless ( ( $y == 1 && $m == 0 )
            || ( $y == 0 && ( $m >= 1 && $m <= 12 ) ) )
        {
            Net::DRI::Exception::usererr_invalid_parameters(
                'Invalid duration for renew/transfer_execute, must be 1..12 months'
            );
            return 1;    # if exception is removed, return an error
        }
    }
    return 0;            ## everything ok
}

sub domain_operation_needs_is_mine {
    my ( $self, $ndr, $domain, $op ) = @_;
    ( $domain, $op ) = ( $ndr, $domain )
        unless ( defined($ndr)
        && $ndr
        && ( ref($ndr) eq 'Net::DRI::Registry' ) );

    return unless defined($op);

    return 1 if ( $op =~ m/^(?:renew|update|delete|withdraw)$/mx );
    return 0 if ( $op eq 'transfer' );
    return;
}

sub domain_withdraw {
    my ( $self, $ndr, $domain, $rd ) = @_;
    $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

    $rd = {} unless ( defined($rd) && ( ref($rd) eq 'HASH' ) );
    $rd->{transactionname} = 'withdraw';

    my $rc = $ndr->process( 'domain', 'withdraw', [ $domain, $rd ] );
    return $rc;
}

sub domain_transfer_execute
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain);

 $rd={} unless (defined($rd) && (ref($rd) eq 'HASH'));
 $rd->{transactionname} = 'transfer_execute';

 my $rc=$ndr->process('domain','transfer_execute',[$domain,$rd]);
 return $rc;
}

# need to accept also t=contact as an element-type to be updated
#
sub host_update {
    my ( $self, $ndr, $dh, $tochange, $rh ) = @_;
    my $fp = $ndr->protocol->nameversion();

    my $name
        = ( UNIVERSAL::isa( $dh, 'Net::DRI::Data::Hosts' ) )
        ? $dh->get_details(1)
        : $dh;
    $self->err_invalid_host_name($name) if $self->verify_name_host($name);
    Net::DRI::Util::check_isa( $tochange, 'Net::DRI::Data::Changes' );

    foreach my $t ( $tochange->types() ) {
        Net::DRI::Exception->die( 0, 'DRD', 6,
            "Change host_update/${t} not handled" )
            unless ( $t =~ m/^(?:ip|status|name|contact)$/mx );
        next if $ndr->protocol_capable( 'host_update', $t );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable of host_update/${t}" );
    }

    my %what = (
        'ip'     => [ $tochange->all_defined('ip') ],
        'status' => [ $tochange->all_defined('status') ],
        'name'   => [ $tochange->all_defined('name') ],
    );
    foreach ( @{ $what{ip} } ) {
        Net::DRI::Util::check_isa( $_, 'Net::DRI::Data::Hosts' );
    }
    foreach ( @{ $what{status} } ) {
        Net::DRI::Util::check_isa( $_, 'Net::DRI::Data::StatusList' );
    }
    foreach ( @{ $what{name} } ) {
        $self->err_invalid_host_name($_) if $self->verify_name_host($_);
    }

    foreach my $w ( keys(%what) ) {
        my @s = @{ $what{$w} };
        next unless @s;    ## no changes of that type

        my $add = $tochange->add($w);
        my $del = $tochange->del($w);
        my $set = $tochange->set($w);

        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to add" )
            if ( defined($add)
            && !$ndr->protocol_capable( 'host_update', $w, 'add' ) );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to del" )
            if ( defined($del)
            && !$ndr->protocol_capable( 'host_update', $w, 'del' ) );
        Net::DRI::Exception->die( 0, 'DRD', 5,
            "Protocol ${fp} is not capable for host_update/${w} to set" )
            if ( defined($set)
            && !$ndr->protocol_capable( 'host_update', $w, 'set' ) );
        Net::DRI::Exception->die( 0, 'DRD', 6,
            "Change host_update/${w} with simultaneous set and add or del not supported"
        ) if ( defined($set) && ( defined($add) || defined($del) ) );
    }

    my $rc = $ndr->process( 'host', 'update', [ $dh, $tochange, $rh ] );
    return $rc;
}

sub message_retrieve {
    my ( $self, $ndr, $id ) = @_;
    my $rc = $ndr->process( 'message', 'noretrieve', [$id] );
    return $rc;
}

sub message_delete {
    my ( $self, $ndr, $id ) = @_;
    my $rc = $ndr->process( 'message', 'nodelete', [$id] );
    return $rc;
}

sub message_waiting {
    my ( $self, $ndr ) = @_;
    my $c = $self->message_count($ndr);
    return ( defined($c) && $c ) ? 1 : 0;
}

sub message_count {
    my ( $self, $ndr ) = @_;
    my $count = $ndr->get_info( 'count', 'message', 'info' );
    return $count if defined($count);
    my $rc = $ndr->process( 'message', 'noretrieve' );
    return unless $rc->is_success();
    $count = $ndr->get_info( 'count', 'message', 'info' );
    return ( defined($count) && $count ) ? $count : 0;
}

##############################################################################
# unsupported transactions
#
# enable DRI reject on unsupported DRI operations here.
# If DRI handles them, just let the server reject them
#
sub domain_transfer_accept {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No domain transfer approve available in .NO' );
    return;
}

sub domain_transfer_refuse {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No domain transfer reject in .NO' );
    return;
}

sub contact_transfer_stop {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No contact transfer cancel available in .NO' );
    return;
}

sub contact_transfer_query {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No contact transfer query available in .NO' );
    return;
}

sub contact_transfer_accept {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No contact transfer approve available in .NO' );
    return;
}

sub contact_transfer_refuse {
    Net::DRI::Exception->die( 0, 'DRD', 4,
        'No contact transfer reject in .NO' );
    return;
}

# let contact check support be decided by the server policy
#sub contact_check { Net::DRI::Exception->die(0,'DRD',4,'No contact check in .NO'); }
1;
