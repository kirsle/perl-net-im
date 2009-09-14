package Constants;

#this was ripped form the yahoo constants now used for tools..should use lib constatnts when thats no

use Data::Dumper;

use vars qw( $CONSTANTS );

$CONSTANTS ={
	YMSG_STATUS_AVAILABLE        => 0x00,
	YMSG_SERVICE_LOGON           => 0x01,
	YMSG_SERVICE_LOGOFF          => 0x02,
	YMSG_SERVICE_ISAWAY          => 0x03,
	YMSG_SERVICE_ISBACK          => 0x04,
	YMSG_SERVICE_IDLE            => 0x05,
	YMSG_SERVICE_MESSAGE         => 0x06,
	YMSG_SERVICE_IDACT           => 0x07,
	YMSG_SERVICE_IDDEACT         => 0x08,
	YMSG_SERVICE_MAILSTAT        => 0x09,
	YMSG_SERVICE_USERSTAT        => 0x0A,
	YMSG_SERVICE_NEWMAIL         => 0x0B,
	YMSG_SERVICE_CHATINVITE      => 0x0C,
	YMSG_SERVICE_CALENDAR        => 0x0D,
	YMSG_SERVICE_NEWPERSONALMAIL => 0x0E,
	YMSG_SERVICE_NEWCONTACT      => 0x0F,
	YMSG_SERVICE_ADDIDENT        => 0x10,
	YMSG_SERVICE_ADDIGNORE       => 0x11,
	YAHOO_SERVICE_KEEPALIVE      => 0x8a,
	YMSG_SERVICE_GROUPRENAME     => 0x13,
	YMSG_SERVICE_SYSMESSAGE      => 0x14,
	YMSG_SERVICE_PASSTHROUGH2    => 0x16,
	YMSG_SERVICE_CONFINVITE      => 0x18,
	YMSG_SERVICE_CONFLOGON       => 0x19,
	YMSG_SERVICE_CONFDECLINE     => 0x1A,
	YMSG_SERVICE_CONFLOGOFF      => 0x1B,
	YMSG_SERVICE_CONFADDINVITE   => 0x1C,
	YMSG_SERVICE_CONFMSG         => 0x1D,
	YMSG_SERVICE_CHATLOGON       => 0x1E,
	YMSG_SERVICE_CHATLOGOFF      => 0x1F,
	YMSG_SERVICE_CHATMSG         => 0x20,
	YMSG_SERVICE_GAMELOGON       => 0x28,
	YMSG_SERVICE_GAMELOGOFF      => 0x29,
	YMSG_SERVICE_GAMEMSG         => 0x2A,
	YMSG_SERVICE_FILETRANSFER    => 0x46,
	YMSG_SERVICE_VOICECHAT       => 0x4A,
	YMSG_SERVICE_NOTIFY          => 0x4B,
	YMSG_SERVICE_VERIFY          => 0x4C,
	YMSG_SERVICE_P2PFILEXFER     => 0x4D,
	YMSG_SERVICE_PEERTOPEER      => 0x4F,
	YMSG_SERVICE_AUTHRESP        => 0x54,
	YMSG_SERVICE_LIST            => 0x55, # after auth, serv sends us our first/last name
	YMSG_SERVICE_LIST_Y15        => 0xF1, # getting the buddy list
	YMSG_SERVICE_AUTH            => 0x57,
	YMSG_SERVICE_ADDBUDDY        => 0x83,
	YMSG_SERVICE_REMBUDDY        => 0x84,
	YMSG_SERVICE_IGNORECONTACT   => 0x85,
	YMSG_SERVICE_REJECTCONTACT   => 0x86,
	YMSG_SERVICE_ACCEPTCONTACT   => 0xD6, # accept contact???
	YMSG_SERVICE_DISCONNECT      => 0x07D1,
	YMSG_SERVICE_BUDDYSTATUS     => 0xC6, # status updates in YMSG 16??	
};

# TODO: handle tags

sub getNameByValue{
	my $value = shift;
	foreach my $name (keys(%$CONSTANTS)){
		return $name if $CONSTANTS->{$name} == $value;
	}
}

sub import {
    my $class = shift;

    my @to_export;
    my @args = @_;

	no strict 'refs'; ## no critic
    my $pkg = caller;
	
	# handle :all tag	
	@args = keys(%$CONSTANTS) if(defined($args[0]) && $args[0] eq ':all');	
	
	# auto export all?
	#@args = keys(%$CONSTANTS) if(!defined($args[0]) || $args[0] eq ':all');
	
	for my $con (@args) {
    	# explort to the calling class 
		*{"${pkg}::$con"} = sub () { $CONSTANTS->{$con} }
	}
}


1; 
