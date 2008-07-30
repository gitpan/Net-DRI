#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use DateTime;
use Test::More tests => 20;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
*{'main::is_string'}=\&main::is if $@;


our (@R1,@R2);
sub mysend { my ($transport,$count,$msg)=@_; push @R1,$msg->get_body(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string(shift(@R2)); }
sub munge { my $in=shift; $in=~s/>\s*</></sg; chomp($in); return $in; }

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->add_registry('OpenSRS');
$dri->target('OpenSRS')->new_current_profile('p1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv,client_login=>'LOGIN',client_password=>'PASSWORD',remote_url=>'http://localhost/'}],'Net::DRI::Protocol::OpenSRS::XCP',[]);

my ($r,$rc,$rd,$ns,$cs);

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="protocol">XCP</item>
            <item key="action">REPLY</item>
            <item key="object">DOMAIN</item>
            <item key="is_success">1</item>
            <item key="response_text">Command successful</item>
            <item key="response_code">200</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="page">1</item>
                  <item key="total">2</item>
                  <item key="remainder">0</item>
                  <item key="exp_domains">
                     <dt_array>
                        <item key="0">
                           <dt_assoc>
                              <item key="f_let_expire">N</item>
                              <item key="name">katarina.biz</item>
                              <item key="expiredate">2007-12-18 23:59:59</item>
                              <item key="f_auto_renew">N</item>
                           </dt_assoc>
                        </item>
                        <item key="1">
                           <dt_assoc>
                              <item key="name">kristina.cn</item>
                              <item key="expiredate">2007-12-18 23:59:59</item>
                              <item key="f_let_expire">N</item>
                              <item key="f_auto_renew">N</item>
                           </dt_assoc>
                        </item>
                     </dt_array>
                  </item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

my $yday=DateTime->from_epoch(epoch => time()-60*60*24)->strftime('%F');
$r=<<"EOF";
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="action">get_domains_by_expiredate</item>
            <item key="object">domain</item>
            <item key="protocol">XCP</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="exp_from">$yday</item>
                  <item key="exp_to">2030-01-01</item>
                  <item key="limit">1000000</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF
$rc=$dri->account_list_domains();
is_string(munge(shift(@R1)),munge($r),'account_list_domains build');
is($rc->is_success(),1,'account_list_domains is_success');
$rd=$dri->get_info('list','account','domains');
is_deeply($rd,['katarina.biz','kristina.cn'],'account_list_domains get_info(list,account,domains)');

push @R2,<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="protocol">XCP</item>
            <item key="action">REPLY</item>
            <item key="object">COOKIE</item>
            <item key="response_text">Command Successful</item>
            <item key="is_success">1</item>
            <item key="response_code">200</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="waiting_requests_no">0</item>
                  <item key="permission"/>
                  <item key="cookie">24128866:3210384</item>
                  <item key="domain_count">131</item>
                  <item key="f_owner">1</item>
                  <item key="last_access_time">1082751795</item>
                  <item key="encoding_type"/>
                  <item key="last_ip">10.0.11.215</item>
                  <item key="expiredate">2007-11-25 00:00:00</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

push @R2,<<'EOF';
<?xml version='1.0' encoding="UTF-8" standalone="no" ?>
<!DOCTYPE OPS_envelope SYSTEM "ops.dtd">
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="protocol">XCP</item>
            <item key="action">REPLY</item>
            <item key="object">DOMAIN</item>
            <item key="is_success">1</item>
            <item key="response_code">200</item>
            <item key="response_text">Query Successful</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="auto_renew">0</item>
                  <item key="registry_createdate">2006-12-12 21:27:25</item>
                  <item key="registry_expiredate">2007-12-12 21:27:25</item>
                  <item key="registry_updatedate">2006-12-12 21:27:25</item>
                  <item key="sponsoring_rsp">1</item>
                  <item key="expiredate">2007-12-12 21:27:25</item>
                  <item key="let_expire">0</item>
                  <item key="contact_set">
<dt_assoc>
  <item key="owner">
    <dt_assoc>
      <item key="first_name">Owen</item>
      <item key="last_name">Owner</item>
      <item key="phone">+1.4165550123x1902</item>
      <item key="fax">+1.4165550124</item>
      <item key="email">owner@catmas.com</item>
      <item key="org_name">Catmas Inc.</item>
      <item key="address1">32 Catmas Street</item>
      <item key="address2">Suite 500</item>
      <item key="address3">Owner</item>
      <item key="city">SomeCity</item>
      <item key="state">CA</item>
      <item key="country">US</item>
      <item key="postal_code">90210</item>
      <item key="url">http://www.catmas.com</item>
    </dt_assoc>
  </item>
  <item key="admin">
    <dt_assoc>
      <item key="first_name">Adler</item>
      <item key="last_name">Admin</item>
      <item key="phone">+1.4165550123x1812</item>
      <item key="fax">+1.4165550125</item>
      <item key="email">admin@catmas.com</item>
      <item key="org_name">Catmas Inc.</item>
      <item key="address1">32 Catmas Street</item>
      <item key="address2">Suite 100</item>
      <item key="address3">Admin</item>
      <item key="city">SomeCity</item>
      <item key="state">CA</item>
      <item key="country">US</item>
      <item key="postal_code">90210</item>
      <item key="url">http://www.catmas.com</item>
    </dt_assoc>
  </item>
  <item key="billing">
      <dt_assoc>
        <item key="first_name">Bill</item>
        <item key="last_name">Billing</item>
        <item key="phone">+1.4165550123x1248</item>
        <item key="fax">+1.4165550136</item>
        <item key="email">billing@catmas.com</item>
        <item key="org_name">Catmas Inc.</item>
        <item key="address1">32 Catmas Street</item>
        <item key="address2">Suite 200</item>
        <item key="address3">Billing</item>
        <item key="city">SomeCity</item>
        <item key="state">CA</item>
        <item key="country">US</item>
        <item key="postal_code">90210</item>
        <item key="url">http://www.catmas.com</item>
      </dt_assoc>
    </item>
    <item key="tech">
      <dt_assoc>
        <item key="first_name">Tim</item>
        <item key="last_name">Tech</item>
        <item key="phone">+1.4165550123x1243</item>
        <item key="fax">+1.4165550125</item>
        <item key="email">techie@catmas.com</item>
        <item key="org_name">Catmas Inc.</item>
        <item key="address1">32 Catmas Street</item>
        <item key="address2">Suite 100</item>
        <item key="address3">Tech</item>
        <item key="city">SomeCity</item>
        <item key="state">CA</item>
        <item key="country">US</item>
        <item key="postal_code">90210</item>
        <item key="url">http://www.catmas.com</item>
      </dt_assoc>
    </item>
  </dt_assoc>
                  </item>
                  <item key="nameserver_list">
                     <dt_array>
                        <item key="0">
                           <dt_assoc>
                              <item key="ipaddress">21.40.33.21</item>
                              <item key="sortorder">1</item>
                              <item key="name">ns1.domaindirect.com</item>
                           </dt_assoc>
                        </item>
                        <item key="1">
                           <dt_assoc>
                              <item key="ipaddress">207.136.100.142</item>
                              <item key="sortorder">2</item>
                              <item key="name">ns2.domaindirect.com</item>
                           </dt_assoc>
                        </item>
                        <item key="2">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.28</item>
                              <item key="sortorder">3</item>
                              <item key="name">patrick.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                        <item key="3">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.24</item>
                              <item key="sortorder">4</item>
                              <item key="name">qa1.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                        <item key="4">
                           <dt_assoc>
                              <item key="ipaddress">24.22.23.25</item>
                              <item key="sortorder">5</item>
                              <item key="name">qa2.mytestingprofile.com</item>
                           </dt_assoc>
                        </item>
                     </dt_array>
                  </item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

$rc=$dri->domain_info('whatever.com',{username => 'aaaa', password => 'aaaa',registrant_ip => '216.40.46.115'});
is($rc->is_success(),1,'domain_info is_success');
$r=<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="action">set</item>
            <item key="object">cookie</item>
            <item key="protocol">XCP</item>
            <item key="registrant_ip">216.40.46.115</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="domain">whatever.com</item>
                  <item key="reg_password">aaaa</item>
                  <item key="reg_username">aaaa</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF

is_string(munge(shift(@R1)),munge($r),'domain_info build 1/2');
$r=<<'EOF';
<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
<!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
<OPS_envelope>
   <header>
      <version>0.9</version>
   </header>
   <body>
      <data_block>
         <dt_assoc>
            <item key="action">get</item>
            <item key="cookie">24128866:3210384</item>
            <item key="object">domain</item>
            <item key="protocol">XCP</item>
            <item key="registrant_ip">216.40.46.115</item>
            <item key="attributes">
               <dt_assoc>
                  <item key="type">all_info</item>
               </dt_assoc>
            </item>
         </dt_assoc>
      </data_block>
   </body>
</OPS_envelope>
EOF
is_string(munge(shift(@R1)),munge($r),'domain_info build 2/2');
is($dri->get_info('value','session','cookie'),'24128866:3210384','domain_info set_cookie value');
is($dri->get_info('auto_renew'),0,'domain_info get_info(auto_renew)');
is($dri->get_info('sponsoring_rsp'),1,'domain_info get_info(sponsoring_rsp)');
is($dri->get_info('let_expire'),0,'domain_info get_info(let_expire)');
is(''.$dri->get_info('crDate'),'2006-12-12T21:27:25','domain_info get_info(crDate)');
is(''.$dri->get_info('exDate'),'2007-12-12T21:27:25','domain_info get_info(exDate)');
is(''.$dri->get_info('upDate'),'2006-12-12T21:27:25','domain_info get_info(upDate)');
is(''.$dri->get_info('exDateLocal'),'2007-12-12T21:27:25','domain_info get_info(exDateLocal)');
$ns=$dri->get_info('ns');
is($ns->count(),5,'domain_info get_info(ns) count');
is_deeply([$ns->get_names()],[qw/ns1.domaindirect.com ns2.domaindirect.com patrick.mytestingprofile.com qa1.mytestingprofile.com qa2.mytestingprofile.com/],'domain_info get_info(ns) get_names');
$cs=$dri->get_info('contact');
is($cs->get('registrant')->name(),'Owen, Owner','domain_info get_info(contact) get(registrant) name');
is($cs->get('admin')->email(),'admin@catmas.com','domain_info get_info(contact) get(admin) email');
is($cs->get('billing')->cc(),'US','domain_info get_info(contact) get(billing) cc');
is($cs->get('tech')->city(),'SomeCity','domain_info get_info(contact) get(tech) city');

exit 0;
