package DateTime::Format::Natural::Lang::DE;

use strict;
no strict 'refs';
use warnings;

our $VERSION = '0.3';

our ($AUTOLOAD, %data_weekdays, %data_months);

sub __new {
    my $class = shift;

    my $obj = {};
    $obj->{weekdays} = \%data_weekdays;
    $obj->{months}   = \%data_months;

    return bless $obj, $class || ref($class);
}

AUTOLOAD {
    my ($self, $exp) = @_;

    my $sub = $AUTOLOAD;
    $sub =~ s/.*::(.*)/$1/;

    if (substr($sub, 0, 2) eq '__') {
       $sub =~ s/^__(.*)$/$1/;
       return ${$sub}{$exp};
    }
}

{
    my $i = 1;

    %data_weekdays = map {  $_ => $i++ } qw(Montag Dienstag Mittwoch Donnerstag
                                            Freitag Samstag Sonntag);
    $i = 1;

    %data_months = map { $_ => $i++ } qw(Januar Februar M�rz April
                                         Mai Juni Juli August September
                                         Oktober November Dezember);
}

our %main = ('second'         => qr/^sekunde$/i,
             'ago'            => qr/^her$/i,
             'now'            => qr/^jetzt$/i,
             'daytime'        => [qr/^(?:nachmittag|abend)$/i, qr/^Morgen$/],
             'months'         => [qw(in diesem)],
             'at_intro'       => qr/^(\d{1,2})(\:\d{2})?(am|pm)?|(mittag|mitternacht)$/i,
             'at_matches'     => [qw(tag in monat)],
             'number_intro'   => qr/^(\d{1,2})$/i,
             'number_matches' => [qw(tag tage woche wochen monat monate Morgen abend jahr in)],
             'weekdays'       => qr/^(?:diesen|n�chsten|letzten)$/i,
             'this_in'        => qr/^(?:diese(?:r|s|n)|in)$/i,
             'next'           => qr/^n�chste(?:r|s|n)$/i,
             'last'           => qr/^letzte(?:r|s|n)?$/i,
             );

our %ago = ('hour'  => qr/^stunde(?:n)?$/i,
            'day'   => qr/^tag(?:e)?$/i,
            'week'  => qr/^woche(?:n)?$/i,
            'month' => qr/^monat(?:e)?$/i,
            'year'  => qr/^jahr(?:e)?$/i,
            );

our %now = ('day'    => qr/^tag(?:e)?$/i,
            'week'   => qr/^woche(?:n)?$/i,
            'month'  => qr/^monat(?:e)?$/i,
            'year'   => qr/^jahr(?:e)?$/i,
            'before' => qr/^vor$/i,
            'from'   => qr/^nach$/i,
            );

our %daytime = ('tokens'     => [ qr/\d/, qr/^am$/i ],
                'morning'    => qr/^Morgen$/,
                'afternoon'  => qr/^nachmittag$/i,
                'ago'        => qr/^her$/i,
                );

our %months = ('number' => qr/^(\d{1,2})$/i,
               'hour'   => qr/stunde(?:n)/i,
               'before' => qr/vor/i,
               'after'  => qr/nach/i,
               );

our %at = ('noon'     => qr/mittag/i,
           'midnight' => qr/mitternacht/i,
           );

our %this_in = ('hour'   => qr/stunde(?:n)/i,
                'week'   => qr/^woche(?:n)$/i,
                'number' => qr/^(\d{1,2})/i,
                );

our %next = ('week'   => qr/^woche(?:n)?$/i,
             'day'    => qr/^tag(?:e)?$/i,
             'month'  => qr/^monat(?:e)?$/i,
             'year'   => qr/^jahr(?:e)?$/i,
             'number' => qr/^(\d{1,2})$/,
             );

our %last = ('week'   => qr/^woche(?:n)?$/i,
             'day'    => qr/^tag(?:e)?$/i,
             'month'  => qr/^monat(?:e)?$/i,
             'year'   => qr/^jahr(?:e)?$/i,
             'number' => qr/^(\d{1,2})$/,
             );

our %day = ('init'           => qr/^(?:heute|gestern|morgen)$/i,
            'morning_prefix' => qr/^(?:diese|n�chste|letze)(?:r|s|n)$/i,
            'yesterday'      => qr/gestern/i,
            'tomorrow'       => qr/morgen/,
            'noonmidnight'   => qr/^mittag|mitternacht$/i,
            'at'             => qr/^am$/i,
            'when'           => qr/^diesen|heute|gestern$/i,
            );

our %setyearday = ('day' => qr/^tag$/i,
                   'ext' => qr/^(\d{1,3})$/,
                  );

1;
__END__

=head1 NAME

DateTime::Format::Natural::Lang::DE - German specific regular expressions and variables

=head1 DESCRIPTION

C<DateTime::Format::Natural::Lang::DE> provides the german specific regular expressions
and variables. This class is loaded if the user specifies the german language.

=head1 EXAMPLES

Below are some examples of human readable date/time input in german:

=head2 Simple

 Donnerstag
 November
 Freitag 13:00
 Mon 2:35
 4pm
 6 am morgen
 Samstag 7 am Abend
 Gestern
 Heute
 Morgen
 diesen Dienstag
 n�chster Monat
 diesen Morgen
 diese Sekunde
 Gestern um 4:00
 Letzten Freitag um 20:00
 Donnerstag letzte Woche
 Morgen um 6:45
 Gestern nachmittag

=head2 Complex

 3 Jahre her
 5 Monate vor jetzt
 7 Stunden her
 7 Tage nach jetzt
 in 3 Stunden
 1 Jahr her morgen
 3 Monate her Samstag um 5:00pm
 4 Tag letzte Woche
 3 Monat n�chstes Jahr

=head2 Specific Dates

 Januar 5
 dez 25
 mai 27
 Oktober 2006
 februar 14, 2004
 Freitag
 jan 3 2010
 3 jan 2000
 27/5/1979
 4:00
 17:00

=head1 SEE ALSO

L<DateTime::Format::Natural>, L<DateTime>, L<Date::Calc>, L<http://datetime.perl.org/>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
