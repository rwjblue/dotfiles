use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '1.00';
%IRSSI = (
    authors     => 'Robert Jackson',
    contact     => 'robert.w.jackson@me.com',
    name        => 'timezone.pl',
    description => 'This script sets the timezone to EST on startup.',
    license     => 'Public Domain'
);

exec $ENV{'TZ'}='EST';
