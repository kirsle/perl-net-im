package Net::IM::Client::TestClient;

use base 'Net::IM::IMBase';


# This is a test client to show how to build a new client for the module
# 

sub new {
        my $package = shift;
        my (%args) = @_;

        my $self = {
                ChatServer => delete $args{ChatServer} || 'cs101.msg.sp1.yahoo.com' || 'scs.msg.yahoo.com',
                ChatPort   => delete $args{ChatPort}   || 5050,
        };
        bless ($self,$package);
        return $self;
}

sub connect{
	my $self = shift;
}

sub dsisconnect{
	my $self = shift;
}

sub send_message{
	my $self = shift;
}

sub show_name{
	my $self = shift;
	print $self->get_name()."\n";
}

sub get_name{
	return 'matt';
}

1;