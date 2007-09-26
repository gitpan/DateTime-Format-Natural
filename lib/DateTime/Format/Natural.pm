package DateTime::Format::Natural;

use strict;
use warnings;
use base qw(DateTime::Format::Natural::Base);

use Carp ();
use List::MoreUtils qw(all any);

our $VERSION = '0.50';

sub new 
{
    my $class = shift;

    my $self = bless {}, ref($class) || $class;
    $self->_init(@_);

    return $self;
}

sub _init 
{
    my ($self, %opts) = @_;

    $self->{Format}        = $opts{format}        || 'd/m/y';
    $self->{Lang}          = $opts{lang}          || 'en';
    $self->{Prefer_future} = $opts{prefer_future} || 0;
    $self->{Opts}{daytime} = $opts{daytime};

    $self->_init_check;

    my $mod  = __PACKAGE__.'::Lang::'.uc($self->{Lang});
    eval "use $mod"; die $@ if $@;

    $self->{data} = $mod->__new();

    return $self;
}

sub _init_check 
{
    my $self = shift;

    my %re = (format        => qr!^(?:[dmy]{1,4}[-./]){2}[dmy]{1,4}$!i,
              lang          => qr!^(?:en|de)$!,
              prefer_future => qr!^(?:0|1)$!);

    my %msg = (format        => 'format string has no valid format',
               lang          => 'language is not supported',
               prefer_future => 'must be a boolean');

    my $error;
    foreach my $lookup (keys %re) {
        my $param = ucfirst $lookup;
        unless ($self->{$param} =~ $re{$lookup}) {
            $error = "parameter '$lookup': $msg{$lookup}";
            last;
        }
    }

    Carp::croak "new(): $error\n" if defined $error;
}

sub _init_vars 
{
    my $self = shift;

    delete $self->{modified};
    delete $self->{postprocess};
}

sub parse_datetime 
{
    my $self = shift;

    $self->_parse_init(@_);

    my $date_string = $self->{Date_string};
    $date_string =~ tr/,//d;

    my @count = $date_string =~ m![-./]!g;
    my %count; $count{$_}++ foreach @count;

    if (scalar keys %count == 1 && $count{(keys %count)[0]} == 2) {
        $self->{count}{tokens} = 1;

        my $separator = quotemeta((keys %count)[0]);
	my @chunks = split /$separator/, $date_string;

        my $i = 0;
	my %length = map { length $_ => $i++ } @chunks;

	my $format = $self->{Format};
          
	if (exists $length{4}) {
            $format = join $separator, ($length{4} == 0 ? qw(yyyy mm dd) : qw(dd mm yyyy)); 	    
        } 
	else {
            $separator = do { $_ = $format;
                              tr/a-zA-Z//d;
                              tr/a-zA-Z//cs;
                              quotemeta; };
	}

        my @separated_order = split /$separator/, $format;
        my $separated_index = 0;

        my $separated_indices = { map { substr($_, 0, 1) => $separated_index++ } @separated_order };

        my @bits = split $separator, $date_string;

        my $century = substr((localtime)[5] + 1900, 0, 2);

	my ($day, $month, $year) = map { $bits[$separated_indices->{$_}] } qw(d m y);

	if (not defined $day && defined $month && defined $year) {
	   $self->_set_error("('format' parameter invalid)");
	   return $self->_get_datetime_object;
	}

        if ($year > $century) { $century-- };
	if (length $year == 2) { $year = "$century$year" };

	if (not $self->SUPER::_valid_date(day => $day)
	     && $self->SUPER::_valid_date(month => $month)
	     && $self->SUPER::_valid_date(year => $year)) {
	    $self->_set_error("(invalid date)");
	    return $self->_get_datetime_object;
	}

        $self->{datetime}->set_year($year);
        $self->{datetime}->set_month($month);
        $self->{datetime}->set_day($day);

        $self->_set_modified(1);
    } 
    else {
        @{$self->{tokens}} = split ' ', $date_string;
        $self->{data}->__init('tokens')->($self);
        $self->{count}{tokens} = scalar @{$self->{tokens}};
        @{$self->{tokenscopy}} = @{$self->{tokens}};

        $self->_process;
    }

    return $self->_get_datetime_object;
}

sub _parse_init 
{
    my $self = shift;

    if (@_ > 1) {
        my %opts             = @_;
        $self->{Date_string} = $opts{string};
        $self->{Debug}       = $opts{debug};
    } 
    else {
        ($self->{Date_string}) = @_;
    }

    unless ($self->{nodatetimeset}) {
        $self->{datetime} = DateTime->now(time_zone => 'floating');
    }

    $self->_init_vars;

    $self->_unset_failure;
    $self->_unset_error;
    $self->_unset_trace;
    $self->_unset_modified;
}

sub parse_datetime_duration 
{
    my $self = shift;

    $self->_parse_init(@_);

    my $timespan_sep = $self->{data}->__timespan('literal');

    my @date_strings = $self->{Date_string} =~ /$timespan_sep/i
      ? split /\s+ $timespan_sep \s+/ix, $self->{Date_string}
      : ($self->{Date_string});

    my @stack;
    foreach my $date_string (@date_strings) {
        push @stack, $self->parse_datetime($date_string);
    }

    return @stack;
}

sub success 
{
    my $self = shift;

    return $self->{valid_expression} && !$self->_get_failure ? 1 : 0;
}

sub error 
{
    my $self = shift;

    return '' if $self->success;

    my $error  = "'$self->{Date_string}' does not parse ";
       $error .= $self->_get_error || '(perhaps you have some garbage?)';

    return $error;
}

sub trace 
{
    my $self = shift;

    my @modified;
    foreach my $unit (grep { $_ ne 'total' } keys %{$self->{modified}}) {
        push @modified, "$unit: $self->{modified}{$unit}";
    }

    return join "\n", @{$self->{trace}}, @modified;
}

sub _process 
{
    my $self = shift;

    $self->{index} = 0;
    $self->_debug_head;

    $self->{valid_expression} = 0;

    foreach my $keyword (keys %{$self->{data}->__grammar('')}) {
        my @grammar = @{$self->{data}->__grammar($keyword)};
        my $types = shift @grammar;

        next if @{$self->{tokens}} > @$types;
        last if $self->_get_modified >= @{$self->{tokens}};

        foreach my $expression (@grammar) {
            my $valid_expression = 1;
            my $definition = $expression->[0];
            my @positions = keys %$definition;
            my %regex_stack;
	    foreach my $pos (@positions) {
	        if ($types->[$pos] eq 'SCALAR') {
	            if (defined $definition->{$pos}) {
                        if (${$self->_token($pos)} =~ /^$definition->{$pos}$/i) {
		            next;
		        }
		        else {
		            $valid_expression = 0;
		        }
		    }
	        }
	        elsif ($types->[$pos] eq 'REGEXP') {
	            if (my (@matches) = ${$self->_token($pos)} =~ $definition->{$pos}) {
                        foreach my $match (@matches) {
                            $regex_stack{$pos} = $match if defined $match;
                        }
		        next;
		    }
		    else {
		        $valid_expression = 0;
		    }
	        }
	        else {
	            die "grammar error";
	        }
	    }
	    if ($valid_expression) {
                $self->{valid_expression} = 1;
	        my $i;
                foreach my $positions (@{$expression->[1]}) {
                    my @values;
                    foreach my $pos (@$positions) {
                        $values[$pos] = exists $regex_stack{$pos}
		          ? $regex_stack{$pos}
		          : ${$self->_token($pos)};
                    }                
                    @values = map { defined $_ ? $_ : () } @values;
                    my $meth = $expression->[-1]->[$i++];
                    $self->$meth(@values);
                }            
	    }
        }
    }
    
    $self->_post_process_options; 
}

sub _debug_head 
{
    my $self = shift;

    print ${$self->_token(0)}, "\n" if $self->{Debug};
}

sub _post_process_options 
{
    my $self = shift;

    if ($self->{Prefer_future}) {
        my %modified = map { $_ => 1 } grep { $_ ne 'total' } keys %{$self->{modified}};

        if ($self->{count}{tokens} == 1
            && (any { $self->{tokenscopy}->[0] =~ /$_/i } keys %{$self->{data}->{weekdays}})
            && scalar keys %modified == 1
            && (exists $self->{modified}{day} && $self->{modified}{day} == 1)
        ) {
            $self->{postprocess}{day} = 7;
        } 
	elsif ((any { my $month = $_; any { $_ =~ /$month/i } @{$self->{tokenscopy}} } keys %{$self->{data}->{months}})
            && (all { /^(?:day|month)$/ } keys %modified)
            && (exists $self->{modified}{month} && $self->{modified}{month} == 1)
            && (exists $self->{modified}{day}
                  ? $self->{modified}{day} == 1
                    ? 1 : 0
                  : 1)
        ) {
	    $self->{postprocess}{year} = 1;
        }
    }
}

sub _token 
{
    my ($self, $pos) = @_;

    my $str = '';
    my $token = $self->{tokens}->[$self->{index} + $pos];

    return defined $token
      ? \$token
      : \$str;
}

sub _add_trace      { push @{$_[0]->{trace}}, (caller(1))[3] }
sub _unset_trace    { @{$_[0]->{trace}} = ()                 }

sub _get_error      { $_[0]->{error}         }
sub _set_error      { $_[0]->{error} = $_[1] }
sub _unset_error    { $_[0]->{error} = ''    }

sub _get_failure    { $_[0]->{failure}     }
sub _set_failure    { $_[0]->{failure} = 1 }
sub _unset_failure  { $_[0]->{failure} = 0 }

sub _get_modified   { $_[0]->{modified}{total} || 0     }
sub _set_modified   { $_[0]->{modified}{total} += $_[1] }
sub _unset_modified { $_[0]->{modified}{total}  = 0     }

sub _get_datetime_object 
{
    my $self = shift;

    $self->{year}  = $self->{datetime}->year;
    $self->{month} = $self->{datetime}->month;
    $self->{day}   = $self->{datetime}->day_of_month;
    $self->{hour}  = $self->{datetime}->hour;
    $self->{min}   = $self->{datetime}->minute;
    $self->{sec}   = $self->{datetime}->second;

    $self->{sec}   = sprintf("%02i", $self->{sec});
    $self->{min}   = sprintf("%02i", $self->{min});
    $self->{hour}  = sprintf("%02i", $self->{hour});
    $self->{day}   = sprintf("%02i", $self->{day});
    $self->{month} = sprintf("%02i", $self->{month});

    my $dt = DateTime->new(year   => $self->{year},
                           month  => $self->{month},
                           day    => $self->{day},
                           hour   => $self->{hour},
                           minute => $self->{min},
                           second => $self->{sec});

    foreach my $unit (keys %{$self->{postprocess}}) {
        $dt->add("${unit}s" => $self->{postprocess}{$unit});
    }

    return $dt;
}

# solely for debugging purpose
sub _set_datetime 
{
    my ($self, $year, $month, $day, $hour, $min, $sec) = @_;

    $self->{datetime} = DateTime->new(time_zone => 'floating',
                                      year      => $year,
                                      month     => $month,
                                      day       => $day,
                                      hour      => $hour,
                                      minute    => $min,
                                      second    => $sec);
    $self->{nodatetimeset} = 1;
}

1;
__END__

=head1 NAME

DateTime::Format::Natural - Create machine readable date/time with natural parsing logic

=head1 SYNOPSIS

 use DateTime::Format::Natural;

 $parser = DateTime::Format::Natural->new;

 $dt = $parser->parse_datetime($date_string);
 @dt = $parser->parse_datetime_duration($date_string);

 if ($parser->success) {
     # operate on $dt/@dt, for example:
     printf("%02s.%02s.%4s %02s:%02s:%02s\n", $dt->day,
                                              $dt->month,
                                              $dt->year,
                                              $dt->hour,
                                              $dt->min,
                                              $dt->sec);
 } else {
     warn $parser->error;
 }

=head1 DESCRIPTION

C<DateTime::Format::Natural> takes a string with a human readable date/time and creates a
machine readable one by applying natural parsing logic.

=head1 METHODS

=head2 new

Creates a new C<DateTime::Format::Natural> object. Arguments to C<new()> are options and
not necessarily required.

 $parser = DateTime::Format::Natural->new(
           lang          => '[en|de]',
           format        => 'mm/dd/yy',
           prefer_future => '[0|1]'
           daytime       => { morning   => 06,
                              afternoon => 13,
                              evening   => 20,
                            },
 );

=over 4

=item * C<lang>

Contains the language selected, currently limited to C<en> (english).
Defaults to 'C<en>'.

=item * C<format>

Specifies the format of numeric dates, defaults to 'C<d/m/y>'.

=item * C<prefer_future (experimental)>

Turns ambigious weekdays/months to their futuristic relatives. Accepts a boolean,
defaults to 0.

=item * C<daytime>

A hash consisting of specific hours given for peculiar daytimes. Daytimes may be
selectively changed.

=back

=head2 parse_datetime

Creates a C<DateTime> object from a human readable date/time string.

 $dt = $parser->parse_datetime($date_string);

 $dt = $parser->parse_datetime(
       string => $date_string,
       debug  => 1,
 );

=over 4

=item * C<string>

The date string.

=item * C<debug>

Boolean value indicating debugging mode.

If debugging is enabled, each token that is analysed will be output to STDOUT
with a trailing newline appended.

=back

Returns a L<DateTime> object.

=head2 parse_datetime_duration

Creates one or more C<DateTime> object(s) from a human readable date/time string
which may contain timespans/durations. 'Same' interface & options as C<parse_datetime()>,
but must be explicitly called in list context.

 @dt = $parser->parse_datetime_duration($date_string);

 @dt = $parser->parse_datetime_duration(
       string => $date_string,
       debug  => 1,
 );

=head2 success

Returns a boolean indicating success or failure for parsing the date/time
string given.

=head2 error

Returns the error message if the parsing didn't succeed.

=head2 trace

Returns a trace of methods which we're called within the Base class and
a summary how often certain units were modified.

=head1 EXAMPLES

See the modules C<DateTime::Format::Natural::Lang::*> for a overview of valid input.

=head1 CREDITS

Thanks to Tatsuhiko Miyagawa for the initial inspiration. See Miyagawa's journal
entry L<http://use.perl.org/~miyagawa/journal/31378> for more information.

Furthermore, thanks to (in order of appearance) who have contributed
valuable suggestions & patches:

 Clayton L. Scott
 Dave Rolsky
 CPAN Author 'SEKIMURA'
 mike (pulsation)
 Mark Stosberg
 Tuomas Jormola
 Cory Watson
 Urs Stotz
 Shawn M. Moore
 Andreas J. K�nig
 Chia-liang Kao

=head1 SEE ALSO

L<DateTime>, L<Date::Calc>, L<http://datetime.perl.org>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
