## Domain Registry Interface, .LU Contact EPP extension commands
##
## Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::LU::Contact;

use strict;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::LU::Contact - .LU EPP Contact extension commands for Net::DRI

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

Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>.
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
          info   => [ undef, \&info_parse ],
          create => [ \&create, undef     ],
          update => [ \&update, undef     ],
         );

 return { 'contact' => \%tmp };
}

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;

 my @ns=@{$mes->ns->{dnslu}};
 return $mes->command_extension_register($tag,sprintf('xmlns:dnslu="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1]));
}

####################################################################################################

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$mes->ns('dnslu'),1);
 return unless $infdata;

 my @c=$infdata->getElementsByTagNameNS($mes->ns('dnslu'),'contact');
 return unless @c;
 
 my $co=$rinfo->{contact}->{$oname}->{self};

 my $t=($c[0]->getElementsByTagNameNS($mes->ns('dnslu'),'type'))[0];
 $co->type($t->getFirstChild()->getData()) if $t;

 my $c=($infdata->getElementsByTagNameNS($mes->ns('dnslu'),'disclose'))[0];
 if ($c)
 {
  $c=$c->getFirstChild();
  $co->disclose({}) unless defined($co->disclose()); 
  while($c)
  {
   my $name=$c->localname() || $c->nodeName();
   next unless $name;
 
   $co->disclose()->{$name.'_loc'}=$c->getAttribute('flag');
   $c=$c->getNextSibling();
  }
 }
}

sub build_disclose
{
 my ($rd,$type)=@_;
 return () unless (defined($rd) && (ref($rd) eq 'HASH') && %$rd);
 my @d=();
 push @d,['dnslu:name',{flag=>$rd->{name_loc}}] if (exists($rd->{name_loc}) && Net::DRI::Util::xml_is_boolean($rd->{name_loc}));
 push @d,['dnslu:addr',{flag=>$rd->{addr_loc}}] if (exists($rd->{addr_loc}) && Net::DRI::Util::xml_is_boolean($rd->{addr_loc}));
 if ($type eq 'contact')
 {
  push @d,['dnslu:org',{flag=>$rd->{org_loc}}] if (exists($rd->{org_loc}) && Net::DRI::Util::xml_is_boolean($rd->{org_loc}));
  push @d,['dnslu:voice',{flag=>$rd->{voice}}] if (exists($rd->{voice}) && Net::DRI::Util::xml_is_boolean($rd->{voice}));
  push @d,['dnslu:fax',{flag=>$rd->{fax}}] if (exists($rd->{fax}) && Net::DRI::Util::xml_is_boolean($rd->{fax}));
  push @d,['dnslu:email',{flag=>$rd->{email}}] if (exists($rd->{email}) && Net::DRI::Util::xml_is_boolean($rd->{email}));
 }
 return \@d;
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 ## validate() has been called, we are sure that type exists
 my @n;
 push @n,['dnslu:type',$contact->type()];
 my $rd=build_disclose($contact->disclose(),$contact->type());
 push @n,['dnslu:disclose',@$rd] if $rd;

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:create',['dnslu:contact',@n]]);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 my @n;
 push @n,['dnslu:add',['dnslu:disclose',@{build_disclose($todo->add('disclose'),'contact')}]] if $todo->add('disclose');
 push @n,['dnslu:rem',['dnslu:disclose',@{build_disclose($todo->del('disclose'),'contact')}]] if $todo->del('disclose');
 return unless @n;

 my $eid=build_command_extension($mes,$epp,'dnslu:ext');
 $mes->command_extension($eid,['dnslu:update',['dnslu:contact',@n]]);
}

####################################################################################################
1;
