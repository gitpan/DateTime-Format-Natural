#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use Test::More tests => 3;

my ($min, $hour, $day, $month, $year) = (13, 01, 24, 11, 2006);

my %specific = ('27/5/1979'  => [ '27.05.1979 01:13', 'dd/m/yyyy'  ],
                '05/27/79'   => [ '27.05.1979 01:13', 'mm/dd/yy'   ],
                '1979-05-27' => [ '27.05.1979 01:13', 'yyyy-mm-dd' ]);

compare(\%specific);

sub compare {
    my $href = shift;
    foreach my $key (sort keys %$href) {
        compare_strings($key, $href->{$key}->[0], $href->{$key}->[1]);
    }
}

sub compare_strings {
    my ($string, $result, $format) = @_;

    my $parse = DateTime::Format::Natural->new(format => $format);
    $parse->_set_datetime($year, $month, $day, $hour, $min);

    my @dt = $parse->parse_datetime(string => $string);

    foreach my $dt (@dt) {
        my $res_string = sprintf("%02s.%02s.%4s %02s:%02s", $dt->day, $dt->month, $dt->year, $dt->hour, $dt->min);
        is($res_string, $result, $string);
    }
}
