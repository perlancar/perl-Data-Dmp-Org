package Data::Dmp::Org;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number blessed reftype);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dd dmp);

# for when dealing with circular refs
our %_seen_refaddrs;

*_double_quote = \&Data::Dmp::_double_quote;

sub _dump {
    my ($val, $level) = @_;

    my $ref = ref($val);
    if ($ref eq '') {
        if (!defined($val)) {
            return "undef";
        } elsif (looks_like_number($val)) {
            return $val;
        } else {
            return _double_quote($val);
        }
    }
    my $refaddr = "$val";
    if ($_seen_refaddrs{$refaddr}++) {
        return "[[$refaddr]]";
    }

    my $class;
    if (blessed $val) {
        $ref = reftype($val);
    }

    my $prefix = ("*" x ($level+1)) . " ";

    my $res;
    if ($ref eq 'ARRAY') {
        $res = "$refaddr";
        for (@$val) {
            $res .= "\n$prefix" . _dump($_, $level+1);
        }
    } elsif ($ref eq 'HASH') {
        $res = "$refaddr";
        for (sort keys %$val) {
            my $k = /\W/ ? _double_quote($_) : $_;
            my $v = _dump($val->{$_}, $level+1);
            $res .= "\n${prefix}$k :: $v";
        }
    } elsif ($ref eq 'SCALAR') {
        $res = "\\"._dump($$val, $level);
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $level);
    } else {
        die "Sorry, I can't dump $val (ref=$ref) yet";
    }
    $res;
}

our $_is_dd;
sub _dd_or_dmp {
    local %_seen_refaddrs;
    local @_fixups;

    my $res;
    if (@_ > 1) {
        $res = join("", map {"* " . _dump($_, 1) . "\n"} @_);
    } else {
        $res = "* " . _dump($_[0], 1) . "\n";
    }

    if ($_is_dd) {
        say $res;
        return @_;
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dmp(@_) }
sub dmp { goto &_dd_or_dmp }

1;
# ABSTRACT: Dump Perl data structures as Org document

=head1 SYNOPSIS

 use Data::Dmp::Org; # exports dd() and dmp()
 dd [1, 2, 3];


=head1 DESCRIPTION

This is an experiment module to generate Org document that represents Perl data
structure. The goal is to view it in Emacs or equivalent Org editor/viewer.


=head1 FUNCTIONS

=head2 dd($data, ...) => $data ...

Dump data as Org to STDOUT. Return original data.

=head2 dmp($data, ...) => $str

Return dump result as string.


=head1 SEE ALSO

L<Data::Dmp>

=cut
