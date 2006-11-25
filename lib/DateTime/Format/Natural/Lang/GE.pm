package DateTime::Format::Natural::Lang::GE;

use strict;
use warnings;

use base qw(Exporter);

our (@EXPORT, %data_weekdays, %data_months, %main, %second, %ago,
     %now, %daytime, %months, %number, %at, %this_in, %next, %last,
     %day, %setyearday);

@EXPORT = qw(%data_weekdays %data_months %main %second %ago %now %daytime
             %months %number %at %this_in %next %last %day %setyearday);

{
    my $i = 1;

    %data_weekdays = map {  $_ => $i++ } qw(Montag Dienstag Mittwoch Donnerstag
                                            Freitag Samstag Sonntag);
    $i = 1;

    %data_months = map { $_ => $i++ } qw(Januar Februar März April
                                         Mai Juni Juli August September
                                         Oktober November Dezember);
}

%main = ('second'         => qr/^sekunde$/i,
         'ago'            => qr/^her$/i,
         'now'            => qr/^jetzt$/i,
         'daytime'        => qr/^(?:morgen|nachmittag|abend)$/i,
         'months'         => [qw(in diesem)],
         'at_intro'       => qr/^(\d{1,2})(\:\d{2})?(am|pm)?|(mittag|mitternacht)$/i,
         'at_matches'     => [qw(tag in monat)],
         'number_intro'   => qr/^(\d{1,2})$/i,
         'number_matches' => [qw(tag tage woche wochen monat monate morgen abend jahr in)],
         'weekdays'       => qr/^(?:diesen|nächsten|letzten)$/i,
         'this_in'        => qr/^(?:diese(?:r|s|n)|in)$/i,
         'next'           => qr/^nächste(?:r|s|n)$/i,
         'last'           => qr/^letzte(?:r|s|n)?$/i,
         );

%ago = ('hour'  => qr/^stunde(?:n)?$/i,
        'day'   => qr/^tag(?:e)?$/i,
        'week'  => qr/^woche(?:n)?$/i,
        'month' => qr/^monat(?:e)?$/i,
        'year'  => qr/^jahr(?:e)?$/i,
       );

%now = ('day'    => qr/^tag(?:e)?$/i,
        'week'   => qr/^woche(?:n)?$/i,
        'month'  => qr/^monat(?:e)?$/i,
        'year'   => qr/^jahr(?:e)?$/i,
        'before' => qr/^vor$/i,
        'from'   => qr/^nach$/i,
       );

%daytime = ('tokens'     => [ qr/\d/, qr/^am$/i ],
            'morning'    => qr/^morgen$/i,
            'afternoon'  => qr/^nachmittag$/i,
           );

%months = ('number' => qr/^(\d{1,2})$/i);

%number = ('month'  => qr/monat(?:e)/i,
           'hour'   => qr/stunde(?:n)/i,
           'before' => qr/vor/i,
           'after'  => qr/nach/i,
           );

%at = ('noon'     => qr/mittag/i,
       'midnight' => qr/mitternacht/i,
      );

%this_in = ('hour'   => qr/stunde(?:n)/i,
            'week'   => qr/^woche(?:n)$/i,
            'number' => qr/^(\d{1,2})/i,
            );

%next = ('week'   => qr/^woche(?:n)?$/i,
         'day'    => qr/^tag(?:e)?$/i,
         'month'  => qr/^monat(?:e)?$/i,
         'year'   => qr/^jahr(?:e)?$/i,
         'number' => qr/^(\d{1,2})$/,
         );

%last = ('week'   => qr/^woche(?:n)?$/i,
         'day'    => qr/^tag(?:e)?$/i,
         'month'  => qr/^monat(?:e)?$/i,
         'year'   => qr/^jahr(?:e)?$/i,
         'number' => qr/^(\d{1,2})$/,
         );

%day = ('init'         => qr/^(?:heute|gestern|morgen)$/i,
        'yesterday'    => qr/gestern/i,
        'tomorrow'     => qr/morgen/i,
        'noonmidnight' => qr/^mittag|mitternacht$/i,
        );

%setyearday = ('day' => qr/^tag$/i,
               'ext' => qr/^(\d{1,3})$/,
              );
1;
__END__

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
 nächster Monat
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
 3 Monat nächstes Jahr

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

L<DateTime>, L<Date::Calc>, L<http://datetime.perl.org/>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
