use strict;
use Test::More;

use_ok $_ for qw(
    DataGen::FromDDL
    DataGen::FromDDL::Director
    DataGen::FromDDL::RecordSet
    DataGen::FromDDL::Util
    DataGen::FromDDL::Builder
    DataGen::FromDDL::Builder::SerialOrder
);

done_testing;
