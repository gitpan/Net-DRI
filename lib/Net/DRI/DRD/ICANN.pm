## Domain Registry Interface, ICANN policy on reserved names
##
## Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::ICANN;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::ICANN - ICANN policies for Net::DRI

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

Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

## See http://www.icann.org/registries/rsep/submitted_app.html for changes
our %ALLOW1=(); ## Pending ICANN Approval: .MOBI .COOP
our %ALLOW2=(name => 1, jobs => 1); ## Pending ICANN Approval: .COOP

## See http://www.icann.org/tlds/agreements/verisign/registry-agmt-appk-net-org-16apr01.htm & same
## Updated to http://www.icann.org/tlds/agreements/tel/appendix-6-07apr06.htm
sub is_reserved_name
{
 my ($domain,$op)=@_;
 my @d=split(/\./,lc($domain));

 ## Tests at all levels
 foreach my $d (@d)
 {
  ## §A (ICANN+IANA reserved)
  return 1 if ($d=~m/^(?:aso|dnso|gnso|icann|internic|ccnso|pso|afrinic|apnic|arin|example|gtld-servers|iab|iana|iana-servers|iesg|ietf|irtf|istf|lacnic|latnic|rfc-editor|ripe|root-servers)$/o);

  ## §C (tagged domain names)
  return 1 if (length($d)>3 && (substr($d,2,2) eq '--') && ($d!~/^xn--/));
 }

 if ($op eq 'create')
 {
  ## §B.1 (additional second level)
  return 1 if (length($d[-2])==1 && ! exists($ALLOW1{$d[-2]}));
  ## §B.2
  return 1 if (length($d[-2])==2 && ! exists($ALLOW2{$d[-2]}));
 }
 ## §B.3
 ## Restriction lifted in newer gTLD
 unless ($d[0]=~m/^(?:travel|mobi|cat|tel)$/o)
 {
  return 1 if ($d[-2]=~m/^(?:aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro)$/o);
 }
 ## §D (reserved for Registry operations)
 return 1 if ($d[-2]=~m/^(?:nic|whois|www)$/o);

 return 0;
}

#################################################################################################################
1;
