use strict;
use warnings;

use Test::More;

use lib './lib', './extlib', './plugins/PeriodicSync/lib';

use_ok('PeriodicSync');
use_ok('PeriodicSync::CMS');

done_testing;

