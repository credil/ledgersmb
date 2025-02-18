=head1 NAME

LedgerSMB::Request - Basic request handling routines for LedgerSMB

=head1 SYNPOSIS

   $request->requires('myattribute1', 'myattribute2');

Error:  Attribute 'myattribute2' is not provided.

   $request->requires_series(1, 12, 'myattribute1', 'myattribute2');

Error:  Attribute 'myattribute2_10' is not provided.

   $request->numbers('debits', 'credits');
   $request->numbers_series(1, 10, 'amount');
   $request->dates('date_from', 'date_to');
   $request->dates_series(1, $end, 'shipdate');

=cut

package LedgerSMB::Request;
use LedgerSMB::App_State;
use LedgerSMB::PGNumber;
use LedgerSMB::PGDate;
use Carp;

=head1 DESCRIPTION

This package provides methods (as an interface package, as of 1.4) for both new
and old code to use for declarative handling of required inputs, dates, and 
amounts.

In future versions, this may take on more of the role found in LedgerSMB.pm 
today, but hopefully with a lot less cruft.  It isn't clear we will use
CGI::Simple or rely on a specific interface and so some portability in request
handling will be required.  That's where this module comes in.

=head1 METHODS

=head2 requires(@attribute_names)

Raises an exception if any member of the argument list corresponds to a non-key
in the current hash or an empty string.  '0' does pass however.

=cut

sub requires {
    my $self = shift @_;
    for (@_){
        Carp::croak(LedgerSMB::App_State->Locale->text("Required attribute not provided: [_1]", $_))
              unless $self->{$_} or $self->{$_} eq '0';
    }
}

=head2 requries_series($start, $stop, @attnames)

Generates and checks a series of attributes in the form of ${attname}_$count
from $start to $stop, for each in @attnames

=cut

sub requires_series {
    my $self = shift @_;
    my $start = shift @_;
    my $end  = shift @_;
    for my $att (@_){
        $self->requires("${att}_$_") for ($start .. $stop);
    }
}

=head2 requires_from($moose_class_name)

Assumes one is goin to instantiate a Moose class with the object and checks for
required attributes on the Moose class.

=cut

sub requires_from {
    no strict 'refs';
    my ($self, $class) = @_;
    my $meta;
    eval { $meta = $class->meta } 
         or Carp::croak 
            "Could not get meta object.  Is $class a valid Moose class?";
    for my $att($meta->get_attibute_list){
        $self->require($att) if $meta->get_attribute($_)->is_required;
    }
}

=head2 numbers(@attnames)

Transforms every $self->{$attname} into a LedgerSMB::PGNumber instance based on
from_input.  This is mostly of interest for old pre-1.3 code in place of
parse_amount, or for add-ons written with Moo instead of Moose.

=cut

sub numbers {
    my $self = shift @_;
    $self->{$_} = LedgerSMB::PGNumber->from_input($self->{$_}) for @_;
}

=head2 numbers_series($start, $stop, @attnames)

Like numbers() above, except uses start and stop to generate attribute lists.
This can be useful for larger series of numbers where line items are not 
directly handled by Moose (yet) or where old code is concerned.

=cut

sub numbers_series {
    my $self = shift @_;
    my $start = shift @_;
    my $end  = shift @_;
    for my $att (@_){
        $self->numbers("${att}_$_") for ($start .. $stop);
    }
}

=head2 dates (@attnames)

Like numbers() above, but converts to LedgerSMB::PGDate objects instead,.

=cut


sub dates {
    my $self = shift @_;
    $self->{$_} = LedgerSMB::PGDate->from_input($self->{$_}) for @_;
}

=head2 dates_series ($start, $stop, @attnames)

Like numbers_series above but with PGDate objects instead.

=cut

sub dates_series {
    my $self = shift @_;
    my $start = shift @_;
    my $end  = shift @_;
    for my $att (@_){
        $self->dates("${att}_$_") for ($start .. $stop);
    }
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the LICENSE.txt for
details.

=cut

1;
