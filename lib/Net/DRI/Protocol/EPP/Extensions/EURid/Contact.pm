## Domain Registry Interface, EURid Contact EPP extension commands
## (based on EURid registration_guidelines_v1_0B-epp.pdf)
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Contact;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Contact - EURid EPP Contact extension commands for Net::DRI

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

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ undef, \&info_parse ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;

 my @ns=@{$mes->ns->{eurid}};
 return $mes->command_extension_register($tag,sprintf('xmlns:eurid="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1]));
}


sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## validate() has been called, we are sure that type & lang exists
 my @n;
 push @n,['eurid:type',$contact->type()];
 push @n,['eurid:vat',$contact->vat()] if $contact->vat();
 push @n,['eurid:lang',$contact->lang()];

 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:create',['eurid:contact',@n]]);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my $newc=$todo->set('info');
 return unless ($newc && (defined($newc->vat()) || defined($newc->lang())));

 my @n;
 push @n,['eurid:vat',$newc->vat()]   if defined($newc->vat());
 push @n,['eurid:lang',$newc->lang()] if defined($newc->lang());

 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:update',['eurid:contact',['eurid:chg',@n]]]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$mes->ns('eurid'),1);
 return unless $infdata;

 my $s=$rinfo->{contact}->{$oname}->{self};

 my $el=$infdata->getElementsByTagNameNS($mes->ns('eurid'),'type');
 $s->type($el->get_node(1)->getFirstChild()->getData());
 $el=$infdata->getElementsByTagNameNS($mes->ns('eurid'),'vat');
 $s->vat($el->get_node(1)->getFirstChild()->getData()) if defined($el->get_node(1));
 $el=$infdata->getElementsByTagNameNS($mes->ns('eurid'),'lang');
 $s->lang($el->get_node(1)->getFirstChild()->getData());
}

####################################################################################################
1;
