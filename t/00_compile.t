use strict;
use Test::More;

use_ok $_ for qw(
    Data::Generator::FromDDL
    Data::Generator::FromDDL::Director
    Data::Generator::FromDDL::RecordSet
    Data::Generator::FromDDL::Util
    Data::Generator::FromDDL::Builder
    Data::Generator::FromDDL::Builder::SerialOrder
);

done_testing;
