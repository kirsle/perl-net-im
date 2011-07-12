package Net::IM::YMSG 0.01;

use 5.14.0;
use strict;
use warnings;
use Carp;
use IO::Socket;
use IO::Select;
use Data::Dumper;

no strict "subs";

use base "Net::IM::Network";
use Net::IM::Util qw(:all);
use Net::IM::YMSG::Constants;
use Net::IM::YMSG::Auth;

=head1 NAME

Net::IM::YMSG - Yahoo Instant Messenger.

=head1 SYNOPSIS

  use Net::IM::YMSG;

  my $ymsg = Net::IM::YMSG->new (
    yahoo_id => "my_yahoo_id",
    password => "my_password",
  );

  $ymsg->addHandler (Message => \&on_message);

  $ymsg->login() or die "Can't login to Yahoo!";
  $ymsg->run();

=head1 DESCRIPTION

This is a L<Net::IM> network class for connecting to Yahoo Messenger. It can be
used stand-alone or as part of a C<Net::IM> object.

This class extends L<Net::IM::Network>, so see there for additional methods.

=head1 METHODS

=head2 new (hash options)

Create a new YMSG object. Options include:

  string username:    The Yahoo ID to sign in with (alias: yahoo_id)
  string password:    The password for the Yahoo ID.
  string chatserver:  The IM server to use (default cs101.msg.sp1.yahoo.com)
  int    chatport:    The port number to use (default 5050)
  string authserver:  The authentication server (default https://login.yahoo.com/config/pwtoken_get)
  string loginserver: The login server (default https://login.yahoo.com/config/pwtoken_login)
  bool   debug:       Enable debugging.
  bool   hexdump:     Extra debugging (hexdump packets)

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %opts  = @_;

	# Common initialization.
	my $self = $class->SUPER::new(
		username   => delete $opts{yahoo_id} || delete $opts{username} || undef,
		password   => delete $opts{password} || undef,
		chatserver => delete $opts{chatserver} || "scs.msg.yahoo.com",
		chatport   => delete $opts{chatport}   || 5050,
		authserver => delete $opts{authserver} || "https://login.yahoo.com/config/pwtoken_get",
		loginserver => delete $opts{loginserver} || "https://login.yahoo.com/config/pwtoken_login",
		hexdump    => delete $opts{hexdump}    || 0,

		# Private data.
		socket     => undef, # Chat server socket
		select     => undef, # IO::Select object
		yv         => undef, # Yv cookie
		tz         => undef, # Tz cookie
		sessid     => 0,     # Session ID
		pinged     => 0,     # Last pinged time
		%opts,
	);
	$self->debug("YMSG initialized.");

	# Normalize the username.
	if (defined $self->{username}) {
		$self->{username} = normalize($self->{username});
	}

	return $self;
}

=head2 login ([string username, [string password]])

Connect and log in to Yahoo Messenger. The C<username> and C<password> are
optional (they can also be defined in the constructor or via the C<username()>
and C<password()> methods).

=cut

sub login {
	my $self = shift;
	$self->SUPER::login(@_);

	# Connect to the server.
	$self->debug("Attempting to connect to $self->{chatserver}:$self->{chatport}");
	$self->{socket} = IO::Socket::INET->new (
		PeerAddr => $self->{chatserver},
		PeerPort => $self->{chatport},
		Proto    => "tcp",
	) or die "Can't establish a connection to $self->{chatserver}: $@";
	$self->{select} = IO::Select->new($self->{socket});

	# Connected!
	$self->debug("Connection to $self->{chatserver} established!");
	$self->{connected} = 1;
	$self->{pinged}    = time();

	# Send the auth packet.
	$self->send (YMSG_SERVICE_AUTH, YMSG_STATUS_AVAILABLE, 1 => $self->{username});

	# Wait for the server's reply.
	return 1;
}

=head2 void logout ()

Log out and disconnect from Yahoo Messenger.

=cut

sub logout {
	my $self = shift;

	# Log out?
	if ($self->{loggedin}) {
		$self->send(YMSG_SERVICE_LOGOFF, YMSG_STATUS_AVAILABLE);
		$self->{loggedin} = 0;
	}

	# Disconnect?
	if ($self->{connected}) {
		$self->{select}->remove($self->{socket});
		$self->{socket}->close();
	}
}

=head2 void do_one_loop ()

Perform a single loop on the server.

=cut

sub do_one_loop {
	my $self = shift;

	# Be sure to ping the server every 60 seconds.
	if (time() >= ($self->{pinged} + 60)) {
		$self->debug("Pinging the server");
		$self->{pinged} = time();
		$self->send(YMSG_SERVICE_PING, YMSG_STATUS_AVAILABLE);
	}

	# See if the socket is ready.
	my @ready = $self->{select}->can_read(0.1);
	my $buf;

	# Read.
	foreach my $fh (@ready) {
		# Read the 20-byte header into the buffer first.
		sysread($fh, $buf, 20, length($buf || ''));
		if ($buf) {
			# Parse the header.
			my $header = $buf;
			my (
				$signature,
				$version,
				$length,
				$service,
				$status,
				$sessid
			) = unpack("a4Cx3nnNN", $header);

			# Read the length of the body.
			$buf = '';
			sysread($fh, $buf, $length, length($buf || ''));
			my $data = $buf;

			# Debug what we just got.
			$self->hexdump("Incoming", $header.$data);

			# Save the sessid given!
			$self->{sessid} = $sessid;

			# Parse the parameters.
			my $param = $self->parseParams($data);

			# Handle the events.
			$self->processPacket($service, $status, $param);
		}
	}

	return 1;
}

=head2 void sendMessage (string to, string message)

Send an IM to a Yahoo user.

=cut

sub sendMessage {
	my ($self,$to,$msg) = @_;

	# Should be logged in.
	unless ($self->{loggedin}) {
		carp "Can't send a message because you're not logged in!";
		return;
	}

	# Send a message.
	$to = normalize($to);
	$self->send(YMSG_SERVICE_MESSAGE, YMSG_STATUS_AVAILABLE,
		0  => $self->{username}, # Our ID
		1  => $self->{username}, # Active ID
		5  => $to,
		14 => $msg,
	);
}

=head2 void sendTyping (string to, bool status)

Send a typing notification to C<to>. C<status> can be one of:

  YMSG_TYPING_STARTED  1
  YMSG_TYPING_STOPPED  0

=cut

sub sendTyping {
	my ($self,$to,$status) = @_;
	$to = normalize($to);

	# Should be logged in.
	unless ($self->{loggedin}) {
		carp "Can't send typing because you're not logged in!";
		return;
	}

	# Send the status!
	$self->send(YMSG_SERVICE_NOTIFY, YMSG_STATUS_AVAILABLE,
		4  => $self->{username}, # Our ID
		5  => $to,               # Their ID
		13 => $status,           # Typing status
		14 => ' ',               # Space?
		49 => 'TYPING',          # Literal word
	);
}

=head2 void sendBuzz (string to)

Send a "buzz!" to a user. The generic alias C<sendAttention()> may also be used.

=cut

sub sendBuzz {
	my ($self,$to) = @_;

	# Should be logged in.
	unless ($self->{loggedin}) {
		carp "Can't send a buzz because you're not logged in!";
		return;
	}

	# A buzz is just a message that says "<ding>".
	$self->sendMessage($to, "<ding>");
}

sub sendAttention {
	return shift->sendBuzz(@_);
}

=head2 void addBuddy (string YahooID, string group)

Add a buddy to a group on your buddy list. Both fields are required.

=cut

sub addBuddy {
	my ($self,$buddy,$group) = @_;
	$buddy = normalize($buddy);

	# Should be logged in.
	unless ($self->{loggedin}) {
		carp "Can't add a buddy because you're not logged in!";
		return;
	}

	# Both fields are required.
	if (!defined $buddy || !length $buddy || !defined $group) {
		carp "Must give a buddy name AND a group name to add a buddy!";
		return;
	}

	# Add them.
	$self->send(YMSG_SERVICE_ADDBUDDY, YMSG_STATUS_NOTIFY,
		1  => $self->{username}, # Us
		7  => $buddy,            # Them
		65 => $group,            # Group
	);
}

=head2 void removeBuddy (string YahooID, string group)

Remove a buddy from your buddy list. Both fields are required.

=cut

sub removeBuddy {
	my ($self,$buddy,$group) = @_;
	$buddy = normalize($buddy);

	# Should be logged in.
	unless ($self->{loggedin}) {
		carp "Can't add a buddy because you're not logged in!";
		return;
	}

	# Both fields are required.
	if (!defined $buddy || !length $buddy || !defined $group) {
		carp "Must give a buddy name AND a group name to add a buddy!";
		return;
	}

	# Add them.
	$self->send(YMSG_SERVICE_REMBUDDY, YMSG_STATUS_NOTIFY,
		1  => $self->{username}, # Us
		7  => $buddy,            # Them
		65 => $group,            # Group
	);
}

=head2 void acceptAddRequest (string YahooID)

When a user adds you to their contact list and C<AddRequest> is called, use this
method to accept the add.

=cut

sub acceptAddRequest {
	my ($self,$buddy) = @_;
	$buddy = normalize($buddy);

	$self->send(YMSG_SERVICE_ACCEPTCONTACT, YMSG_STATUS_AVAILABLE,
		1  => $self->{username}, # Us
		5  => $buddy,            # Them
		13 => 1,
	);
}

=head2 void rejectAddRequest (string YahooID[, string reason])

Reject an add request. C<reason> will default to "No reason given." if you don't
provide one.

=cut

sub rejectAddRequest {
	my ($self,$buddy,$reason) = @_;
	$reason //= "No reason given."; #//

	$self->send(YMSG_SERVICE_REJECTCONTACT, YMSG_STATUS_AVAILABLE,
		1  => $self->{username}, # Us
		7  => $buddy,            # Them
		14 => $reason,           # Reason
	);
}

=head2 private void processPacket (int service, int status, href body)

Handle incoming packets from the Yahoo server.

=cut

sub processPacket {
	my ($self,$service,$status,$body) = @_;

	# Handle supported event codes.
	if ($service == YMSG_SERVICE_AUTH) {
		# The server is sending the authentication challenge.
		# 94: challenge string

		# Outsource the auth stuff.
		my $authstr = Net::IM::YMSG::Auth::authenticate($self, $body);

		# Send our auth info back so we can get logged in!
		$self->send(YMSG_SERVICE_AUTHRESP, YMSG_STATUS_AVAILABLE,
			1   => $self->{username},
			0   => $self->{username},
			277 => $self->{yv}, # Auth cookie
			278 => $self->{tz}, # Auth cookie
			307 => $authstr,    # Auth string
			244 => 4194239,     # Internal build number?
			2   => $self->{username},
			2   => 1,
			98  => "us",        # Country
			135 => "9.0.0.2162", # YMSG client version number
		);
	}
	elsif ($service == YMSG_SERVICE_PING) {
		# The server pinged us. Ping back.
		$self->send(YMSG_SERVICE_PING, YMSG_STATUS_AVAILABLE);
	}
	elsif ($service == YMSG_SERVICE_LIST) {
		# The server sends this after a successful auth.
		# We can use this event to call the connected handler. For some weird
		# reason, this event is called "LIST", but it's not our buddy list;
		# "LIST_Y15" is. See: http://www.adrensoftware.com/tools/yahoo_v16_protocol.php

		# Call the connected handler.
		$self->{loggedin} = 1;
		$self->event("Connected");
	}
	elsif ($service == YMSG_SERVICE_SYSMESSAGE) {
		# We got a system message (probably nagging us to upgrade our client!)
		my $from    = $body->{4};
		my $to      = $body->{5};
		my $message = $body->{14};
		$self->event("Notification", $from, $to, $message);
	}
	elsif ($service == YMSG_SERVICE_NEWCONTACT || $service == 214) { # TODO
		# A new buddy request!
		# 4: Their YahooID
		# 5: Our YahooID
		$self->event("AddRequest", $body->{4});
	}
	elsif ($service == YMSG_SERVICE_MESSAGE) {
		# Receiving an IM!
		# 5: Our YahooID
		# 4: Their YahooID
		# 14: Their message

		# Message or buzz?
		if ($body->{14} eq "<ding>") {
			$self->event("Attention", $body->{4});
		}
		else {
			$self->event("Message", $body->{4}, $body->{14});
		}
	}
	elsif ($service == YMSG_SERVICE_NOTIFY) {
		# Receiving a notification! Might be a typing notification.
		# 4: Their YahooID
		# 5: Our YahooID
		# 49: Event type e.g. "TYPING"
		# 13: "1"? If 49=TYPING, 13=1 if they're typing or 0 if they stopped.
		# 14: " "?
		if ($body->{49} eq "TYPING") {
			my $typing = $body->{13} ? 1 : 0;
			$self->event("Typing", $body->{4}, $typing);
		}
	}
	elsif ($service == YMSG_SERVICE_BUDDYSTATUS) {
		# Buddy status update
		# 7:  Their YahooID
		# 19: Their custom away message
		# 10: Their status (one of YMSG_STATUS_*)
		$self->event("BuddyStatus", $body->{7}, $body->{10}, $body->{19});
	}
	elsif ($service == YMSG_SERVICE_REMBUDDY) {
		# Buddy removed successfully.
		# 1:  Our ID
		# 36: Group name
		# 7:  Their ID
		$self->event("BuddyRemoved", $body->{7}, $body->{36});
	}
	elsif ($service == YMSG_SERVICE_DISCONNECT) {
		# We've been disconnected!
		$self->event("Disconnected");
	}
	else {
		my $hex = sprintf("%02X", $service);
		$self->debug("Unsupported service number: $hex ($service, status=$status)\n"
			. Dumper($body));
	}
}

=head2 private void send (int service, int status, hash body)

Refrain from calling this yourself. This method constructs a YMSG packet and
sends it. C<service> and C<status> are YMSG constants. The C<body> is a
hash-like structure containing the key/value pairs for the message.

=cut

sub send {
	my ($self,$service,$status,@fields) = @_;

	# $service will be one of the YMSG_SERVICE_* constants.
	# @fields is the key/value fields for the packet.
	my @pairs = ();
	for (my $i = 0; $i < scalar(@fields); $i += 2) {
		my $key = $fields[$i];
		my $value = $fields[$i+1];
		push (@pairs, join(YMSG_SEP, $key, $value));
	}
	my $body = join(YMSG_SEP, @pairs);
	$body .= YMSG_SEP if length $body > 0;

	# Length of the body as unsigned short (16-bit) integer.
	my $len = length $body;

	# Prepare the packet.
	my $header = pack('a4Cx3nnNN',
		YMSG_HEADER,
		YMSG_VER,
		$len,
		$service,
		$status,
		$self->{sessid});
	$header =~ s/^YMSG\x10\x00/YMSG\x00\x10/; # TODO: fix the version number
	my $packet = $header . $body;

	# Hexdump this packet.
	$self->hexdump("Outgoing", $packet);
	$self->{socket}->send($packet) or die "Can't send packet: $@";
	return 1;
}

=head2 private hash parseParams (bin data)

Parse the binary key/value pairs from a Yahoo packet.

=cut

sub parseParams {
	my ($self,$bin) = @_;

	# Split the keys and values up.
	my $sep = YMSG_SEP;
	my @bits = split(/\Q$sep\E/, $bin);

	# Dissect the data.
	my $map = {};
	for (my $i = 0; $i < scalar(@bits); $i += 2) {
		if (exists $map->{ $bits[$i] }) {
			# More than one field with the same number!
			if (ref $map->{ $bits[$i] } ne "ARRAY") {
				$map->{ $bits[$i] } = [ $map->{ $bits[$i] } ];
			}
			push(@{$map->{ $bits[$i] }}, $bits[$i + 1]);
		}
		else {
			$map->{ $bits[$i] } = $bits[$i + 1];
		}
	}

	return $map;
}

=head1 EVENT HANDLERS

This section describes all the YMSG events that your code can handle. In most of
these events that pass a C<from> and C<to> field, the C<to> will be your local
Yahoo ID.

=head2 void Connected ()

Called when you're connected to YMSG and logged in successfully.

=head2 void Notification (string from, string to, string message)

This handles system messages (like to upgrade your client).

=head2 void AddRequest (string from, string to)

Called when a user wants to add you to their buddy list.

=head2 void Attention (string from)

A user has "buzz!"ed you.

=head2 void Message (string from, string to, string message)

A user has sent you an Instant Message.

=head2 void Typing (string from, bool typing)

A user is typing a message (or not). C<typing> is 1 for typing or 0 for not
typing.

=head2 void BuddyStatus (string from, int status, string custom_status)

A buddy has changed their status. C<custom_status> is their custom (away)
message. C<status> is one of the C<YMSG_STATUS_*> constants. You can import the
constants by using this code:

  use Net::IM::YMSG::Constants;

List of status constants:

  YMSG_STATUS_AVAILABLE      YMSG_STATUS_ONPHONE
  YMSG_STATUS_BRB            YMSG_STATUS_ONVACATION
  YMSG_STATUS_BUSY           YMSG_STATUS_OUTTOLUNCH
  YMSG_STATUS_NOTATHOME      YMSG_STATUS_STEPPEDOUT
  YMSG_STATUS_NOTATDESK      YMSG_STATUS_INVISIBLE
  YMSG_STATUS_NOTINOFFICE    YMSG_STATUS_CUSTOM
  YMSG_STATUS_IDLE           YMSG_STATUS_OFFLINE

=head2 void BuddyRemoved (string YahooID, string group)

Notification that a buddy has been removed from your buddy list (such as right
after you call C<removeBuddy()>).

=head2 void Disconnected ()

The server has disconnected you.

=head1 SEE ALSO

L<Net::IM>, which lets you manage multiple connections to multiple networks in
one object.

L<Net::IM::Network>, the base class that this module inherits methods from.

=head1 COPYRIGHT

Copyright 2011 Noah Petherbridge

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
