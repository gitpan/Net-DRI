## Domain Registry Interface, EPP NSgroup extension commands
## (based on .BE Registration_guidelines_v4_7_1)
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

package Net::DRI::Protocol::EPP::Extensions::NSgroup;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='http://www.dns.be/xml/epp/nsgroup-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NSgroup - EPP NSgroup extension commands for Net::DRI

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


##########################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp1=( create => [ \&create ],
            check  => [ \&check, \&check_parse ],
            info   => [ \&info, \&info_parse ],
            delete => [ \&delete ],
	    update => [ \&update ],
          );

 $tmp1{check_multi}=$tmp1{check};
 
 return { 'nsgroup' => \%tmp1 };
}

sub capabilities_add
{
 return { 'nsgroup_update' => { 'ns' => ['set'] } };
}

sub build_command
{
 my ($msg,$command,$hosts)=@_;

 my @gn;
 foreach my $h ( grep { defined } (ref($hosts) eq 'ARRAY')? @$hosts : ($hosts))
 {
  my $gn=UNIVERSAL::isa($h,'Net::DRI::Data::Hosts')? $h->name() : $h;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid NSgroup name: '.$gn) unless ($gn && Net::DRI::Util::xml_is_normalizedstring($gn,1,100));
  push @gn,$gn;
 }

 Net::DRI::Exception->die(1,'protocol/EPP',2,'NSgroup name needed') unless @gn;

 $msg->command([$command,'nsgroup:'.$command,'xmlns:nsgroup="http://www.dns.be/xml/epp/nsgroup-1.0" xsi:schemaLocation="http://www.dns.be/xml/epp/nsgroup-1.0 nsgroup-1.0.xsd"']);

 return map { ['nsgroup:name',$_] } @gn;
}

sub add_nsname
{
 my ($ns)=@_;
 return () unless (defined($ns));
 my @a;
 if (! ref($ns))
 {
  @a=($ns);
 } elsif (ref($ns) eq 'ARRAY')
 {
  @a=@$ns;
 } elsif (UNIVERSAL::isa($ns,'Net::DRI::Data::Hosts'))
 {
  @a=$ns->get_names();
 }

 foreach my $n (@a) 
 {
  next if Net::DRI::Util::is_hostname($n);
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid host name: '.$n);
 }

 return map { ['nsgroup:ns',$_] } @a;
}


##################################################################################################
########### Query commands

sub check
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$hosts);
 $mes->command_body(\@d);
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_content('chkData',$NS);
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($NS,'cd'))
 {
  my $c=$cd->firstChild;
  my $nsgroup;
  while($c)
  {
   my $n=$c->nodeName();
   if ($n eq 'nsgroup:name')
   {
    $nsgroup=$c->firstChild->getData();
    $rinfo->{nsgroup}->{$nsgroup}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   $c=$c->getNextSibling();
  }
 }
}

sub info
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'info',$hosts);
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$NS);
 return unless $infdata;

 my $ns=Net::DRI::Data::Hosts->new();

 my $c=$infdata->firstChild();
 while ($c)
 {
  my $name=$c->nodeName();
  next unless $name;
  if ($name eq 'nsgroup:name')
  {
   my $nsgroup=$c->firstChild->getData();
   $ns->name($nsgroup);
   $rinfo->{nsgroup}->{$nsgroup}->{exist}=1; ## $oname='session' here, will be fixed later (in fact not, because of change in Message, but this is temporary)
  } elsif ($name eq 'nsgroup:ns')
  {
   $ns->add($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }

 $rinfo->{nsgroup}->{$oname}->{self}=$ns;
}

############ Transform commands

sub create
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$hosts);
 push @d,add_nsname($hosts);
 $mes->command_body(\@d);
}

sub delete
{
 my ($epp,$hosts)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$hosts);
 $mes->command_body(\@d);
}

sub update
{
 my ($epp,$hosts,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo." must be a Net::DRI::Data::Changes object") unless ($todo && UNIVERSAL::isa($todo,'Net::DRI::Data::Changes'));

 if ((grep { ! /^(?:ns)$/ } $todo->types()) || (grep { ! /^(?:set)$/ } $todo->types('ns') ))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only ns set available for nsgroup');
 }

 my $ns=$todo->set('ns');
 
 my @d=build_command($mes,'update',$hosts);
 push @d,add_nsname($ns);
 $mes->command_body(\@d);
}

####################################################################################################
1;
