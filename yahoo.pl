#!/usr/bin/perl

use 5.14.0;
use strict;
use warnings;
use lib "lib";
use Net::IM;

my $im = Net::IM->new (debug => 1);

my $yahoo = $im->addListener (
	network  => "YMSG",
	username => "aidenrive",
	password => "password",
	hexdump  => 1,
);

$im->addHandlers (
	connected    => \&on_connected,
	notification => \&on_notification,
	Message      => \&on_message,
	Attention    => \&on_buzzed,
	AddRequest   => \&on_added,
	Typing       => \&on_typing,
	BuddyStatus  => \&on_buddy_status,
	Disconnected => \&on_disconnected,
);
$im->login();
$im->run();

sub on_connected {
	my $self = shift;
	my $id   = $self->whoami();

	print "We're connected ($id)!\n";
}

sub on_notification {
	my ($self, $from, $to, $message) = @_;
	my $id = $self->whoami();

	print "Notification for $id: from=$from, to=$to, msg=$message\n";
}

sub on_added {
	my ($self, $from) = @_;
	my $id = $self->whoami();

	print "Add request for $id: from=$from\n";

	# Accept!
	$self->acceptAddRequest($from);
}

sub on_buzzed {
	my ($self, $from) = @_;

	print "[$from] BUZZ!\n";
	$self->sendMessage($from, "Aaah!");
}

sub on_message {
	my ($self, $from, $msg) = @_;
	my $id = $self->whoami();

	# Filter their message.
	$msg =~ s/<(.|\n)+?>//g; # Strip HTML
	$msg =~ s/\e.+?m//g;     # Strip the pseudo-ANSI color codes

	print "[$from] $msg\n";

	# Commands...
	if ($msg =~ /^!buzz/i) {
		# Buzz the user.
		$self->sendBuzz($from);
	}
	elsif ($msg =~ /^!say (.+?)$/i) {
		# Send a reply
		$self->sendMessage($from, $1);
	}
	elsif ($msg =~ /^!im (.+?):(.+?)$/i) {
		# Bother another user
		$self->sendMessage($1, $2);
	}
	elsif ($msg =~ /^!add (.+?)$/i) {
		# Add a buddy
		$self->addBuddy($1, "Buddies");
		$self->sendMessage($from, "Added $1 to my buddy list.");
	}
	elsif ($msg =~ /^!remove (.+?)$/i) {
		# Remove a buddy
		$self->removeBuddy($1, "Buddies");
		$self->sendMessage($from, "Removed $1 from my buddy list.");
	}
	else {
		$self->sendMessage($from, "You said: $msg");
	}
}

sub on_typing {
	my ($self, $from, $typing) = @_;

	print "TYPING: $from ($typing)\n";
}

sub on_buddy_status {
	my ($self, $from, $status, $custom) = @_;

	print "Buddy Status: $from ($status - $custom)\n";
}
