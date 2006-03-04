#!/usr/bin/perl -w

use Net::DRI::Protocol::EPP::Message;
use Net::DRI::Data::Raw;

use Encode;

use Test::More tests=> 30;

my $msg;
my $s;

###################################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$s=Net::DRI::Data::Raw->new_from_string(<<EOF);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54321-XYZ</svTRID>
    </trID>
  </response>
</epp>
EOF

$msg->parse($s);
is($msg->errcode(),1000,'parse (result,trid) errcode');
is($msg->errmsg(),'Command completed successfully','parse (result,trid) errmsg');
is($msg->errlang(),'en','parse (result,trid) errlang');
is($msg->cltrid(),'ABC-12345','parse (result,trid) cltrid');
is($msg->svtrid(),'54321-XYZ','parse (result,trid) svtrid');

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$s=Net::DRI::Data::Raw->new_from_string(<<EOF);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <response>
    <result code="2004">
      <msg>Parameter value range error</msg>
      <value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem1>2525</obj:elem1></value>
    </result>
    <result code="2005">
      <msg>Parameter value syntax error</msg>
      <value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem2>ex(ample</obj:elem2></value>
      <extValue><value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem3>abc.ex(ample</obj:elem3></value><reason>Invalid character found.</reason></extValue>
    </result>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54321-XYZ</svTRID>
    </trID>
  </response>
</epp>
EOF

$msg->parse($s);
is($msg->errcode(),2005,'parse (result,2 errors) errcode');
my $ri=$msg->result_extra_info();
is_deeply($ri,['<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem1>2525</obj:elem1></value>','<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem2>ex(ample</obj:elem2></value>','<value xmlns:obj="urn:ietf:params:xml:ns:obj"><obj:elem3>abc.ex(ample</obj:elem3></value><reason>Invalid character found.</reason>'],'parse (result,2 errors) result_extra_info');


#################################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });

$msg->command(['check','host:check','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);

$msg->command_body([['host:name','ns1.example.com'],['host:name','ns2.example.com'],['host:name','ns3.example.com']]);
$msg->cltrid('ABC-12345');

$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <check>
      <host:check
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
        <host:name>ns2.example.com</host:name>
        <host:name>ns3.example.com</host:name>
      </host:check>
    </check>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

is($msg->as_string(),_n($s),'build host check [RFC 3732 �3.1.1]');

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$s=Net::DRI::Data::Raw->new_from_string(<<EOF);
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <resData>
      <host:chkData
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:cd>
          <host:name avail="1">ns1.example.com</host:name>
        </host:cd>
        <host:cd>
          <host:name avail="0">ns2.example2.com</host:name>
          <host:reason>In use</host:reason>
        </host:cd>
        <host:cd>
          <host:name avail="1">ns3.example3.com</host:name>
        </host:cd>
      </host:chkData>
    </resData>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54322-XYZ</svTRID>
    </trID>
  </response>
</epp>
EOF

$msg->parse($s);
my $nn=$msg->get_content('chkData','urn:ietf:params:xml:ns:host-1.0');
my $o=$nn->firstChild();
$o=$o->getNextSibling();
is($o->nodeName(),'host:cd','parse host:chkData  1');
is($o->firstChild->getNextSibling->nodeName(),'host:name','parse host:chkData  2');
is($o->firstChild->getNextSibling->getAttribute('avail'),1,'parse host:chkData  3');
is($o->firstChild->getNextSibling->getFirstChild->getData(),'ns1.example.com','parse host:chkData  4');
$o=$o->getNextSibling()->getNextSibling();
is($o->nodeName(),'host:cd','parse host:chkData  5');
is($o->firstChild->getNextSibling->nodeName(),'host:name','parse host:chkData  6');
is($o->firstChild->getNextSibling->getAttribute('avail'),0,'parse host:chkData  7');
is($o->firstChild->getNextSibling->getFirstChild->getData(),'ns2.example2.com','parse host:chkData  8');
is($o->firstChild->getNextSibling->getNextSibling->getNextSibling->nodeName(),'host:reason','parse host:chkData  9');
is($o->firstChild->getNextSibling->getNextSibling->getNextSibling->getFirstChild->getData(),'In use','parse host:chkData 10');
$o=$o->getNextSibling()->getNextSibling();
is($o->nodeName(),'host:cd','parse host:chkData 11');
is($o->firstChild->getNextSibling->nodeName(),'host:name','parse host:chkData 12');
is($o->firstChild->getNextSibling->getAttribute('avail'),1,'parse host:chkData 13');
is($o->firstChild->getNextSibling->getFirstChild->getData(),'ns3.example3.com','parse host:chkData 14');
$o=$o->getNextSibling()->getNextSibling();
is($o,undef,'parse host:chkData 15');



##############################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$msg->command(['info','host:info','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);
$msg->command_body([['host:name','ns1.example.com']]);
$msg->cltrid('ABC-12345');


$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <info>
      <host:info
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
      </host:info>
    </info>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

is($msg->as_string(),_n($s),'build host info [RFC 3732 �3.1.2]');

##############################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$msg->command(['create','host:create','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);
$msg->command_body([['host:name','ns1.example.com'],['host:addr','192.0.2.2',{ip=>'v4'}],['host:addr','192.0.2.29',{ip=>'v4'}],['host:addr','1080:0:0:0:8:800:200C:417A',{ip=>'v6'}]]);
$msg->cltrid('ABC-12345');


$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <create>
      <host:create
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
        <host:addr ip="v4">192.0.2.2</host:addr>
        <host:addr ip="v4">192.0.2.29</host:addr>
        <host:addr ip="v6">1080:0:0:0:8:800:200C:417A</host:addr>
      </host:create>
    </create>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

is($msg->as_string(),_n($s),'build host create [RFC 3732 �3.2.1]');

##############################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$msg->command(['delete','host:delete','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);
$msg->command_body([['host:name','ns1.example.com']]);
$msg->cltrid('ABC-12345');


$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <delete>
      <host:delete
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
      </host:delete>
    </delete>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

is($msg->as_string(),_n($s),'build host delete [RFC 3732 �3.2.2]');

##############################################################################

$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$msg->command(['update','host:update','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);
$msg->command_body([['host:name','ns1.example.com'],['host:add',['host:addr','192.0.2.22',{ip=>'v4'}],['host:status',undef,{s=>'clientUpdateProhibited'}]],['host:rem',['host:addr','1080:0:0:0:8:800:200C:417A',{ip=>'v6'}]],['host:chg',['host:name','ns2.example.com']]]);
$msg->cltrid('ABC-12345');


$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <update>
      <host:update
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
        <host:add>
          <host:addr ip="v4">192.0.2.22</host:addr>
          <host:status s="clientUpdateProhibited"/>
        </host:add>
        <host:rem>
          <host:addr ip="v6">1080:0:0:0:8:800:200C:417A</host:addr>
        </host:rem>
        <host:chg>
          <host:name>ns2.example.com</host:name>
        </host:chg>
      </host:update>
    </update>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

is($msg->as_string(),_n($s),'build host update [RFC 3732 �3.2.5]');



$msg=Net::DRI::Protocol::EPP::Message->new();
$msg->ns({ _main => ['urn:ietf:params:xml:ns:epp-1.0','epp-1.0.xsd'] });
$msg->command(['check','host:check','xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"']);

$msg->command_body([['host:name','ns1.example.com'],['host:name','ns2.example.com'],['host:name','ns3.example.com']]);
$msg->cltrid('ABC-12345');

$s=<<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
     epp-1.0.xsd">
  <command>
    <check>
      <host:check
       xmlns:host="urn:ietf:params:xml:ns:host-1.0"
       xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
       host-1.0.xsd">
        <host:name>ns1.example.com</host:name>
        <host:name>ns2.example.com</host:name>
        <host:name>ns3.example.com</host:name>
      </host:check>
    </check>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
EOF

my $m=$msg->as_string('tcp');
ok(!Encode::is_utf8($m),'Unicode : XML string sent on network is bytes not characters');
my $l=unpack('N',substr($m,0,4));
$m=substr($m,4);
is($l,4+length(_n($s)),'Unicode : XML string length');
is($m,_n($s),'Unicode : string is ok after removing length');

exit 0;

sub _n
{
 my $in=shift;
 $in=~s/^\s+//gm;
 $in=~s/\n/ /g;
 $in=~s/>\s+</></g;
 $in=~s/\s+$//gm;
 return $in;
}
