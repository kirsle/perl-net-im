package Net::IM::IMBase;

use 5.008008;
use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.01';

# All subclasses must implmemnt the folowing classes
my @implements = qw{
	connect 
	disconnect
	send_message
};

sub import {
  	my $caller = caller;
  	my $package = shift;
	
	# get an array of all the functions from the caller
	no strict 'refs';
	my $caller_functions = \%{$package.'::'};	
	use strict 'refs';
	
	foreach my $i (grep { !defined($caller_functions->{$_}) } @implements) {
		die __PACKAGE__ . " is listed as a base type in $package, but the $i method is not implemented!"
	}

}

=head2 void setHandlers, setHandler (Event => CODE, ...)

Define an event handler. C<setHandlers> is a grammatical alias for C<setHandler>.

=cut

sub setHandler {
        my ($self,%events) = @_;

        foreach my $event (keys %events) {
                $self->{Events}->{$event} = $events{$event};
        }

        return 1;
}

sub setHandlers {
        return shift->setHandler(@_);
}

# Invoke a handler.
sub _event {
        my ($self,$event,@args) = @_;

        if (exists $self->{Events}->{$event}) {
                $self->{Events}->{$event}->($self,@args);
        }
}


1;