package Net::IM::YMSG::Constants 0.01;

use 5.14.0;
use strict;
use warnings;
use Net::IM::Util "const";

# "Public" constants: things we don't need internally but which will make the
# user's life easier, maybe.
const YMSG_TYPING_STARTED     => 1;
const YMSG_TYPING_STOPPED     => 0;
const YMSG_STATUS_ONLINE      => 0x00;
const YMSG_STATUS_AVAILABLE   => 0x00;
const YMSG_STATUS_NOTIFY      => 0x01;
const YMSG_STATUS_BRB         => 0x01;
const YMSG_STATUS_BUSY        => 0x02;
const YMSG_STATUS_NOTATHOME   => 0x03;
const YMSG_STATUS_NOTATDESK   => 0x04;
const YMSG_STATUS_NOTINOFFICE => 0x05;
const YMSG_STATUS_ONPHONE     => 0x06;
const YMSG_STATUS_ONVACATION  => 0x07;
const YMSG_STATUS_OUTTOLUNCH  => 0x08;
const YMSG_STATUS_STEPPEDOUT  => 0x09;
const YMSG_STATUS_INVISIBLE   => 0x0C;
const YMSG_STATUS_CUSTOM      => 0x63;
const YMSG_STATUS_IDLE        => 0x3E7;
const YMSG_STATUS_OFFLINE     => 0x5A55AA56;
const YMSG_STATUS_TYPING      => 0x16;

# Services and constants.
const YMSG_HEADER                  => "YMSG";     # Standard packet header
const YMSG_VER                     => 0x10;       # Protocol version (16)
const YMSG_SEP                     => "\xC0\x80"; # Argument separator
const YMSG_SERVICE_LOGON           => 0x01;
const YMSG_SERVICE_LOGOFF          => 0x02;
const YMSG_SERVICE_ISAWAY          => 0x03;
const YMSG_SERVICE_ISBACK          => 0x04;
const YMSG_SERVICE_IDLE            => 0x05;
const YMSG_SERVICE_MESSAGE         => 0x06;
const YMSG_SERVICE_IDACT           => 0x07;
const YMSG_SERVICE_IDDEACT         => 0x08;
const YMSG_SERVICE_MAILSTAT        => 0x09;
const YMSG_SERVICE_USERSTAT        => 0x0A;
const YMSG_SERVICE_NEWMAIL         => 0x0B;
const YMSG_SERVICE_CHATINVITE      => 0x0C;
const YMSG_SERVICE_CALENDAR        => 0x0D;
const YMSG_SERVICE_NEWPERSONALMAIL => 0x0E;
const YMSG_SERVICE_NEWCONTACT      => 0x0F;
const YMSG_SERVICE_ADDIDENT        => 0x10;
const YMSG_SERVICE_ADDIGNORE       => 0x11;
const YMSG_SERVICE_PING            => 0x12;
const YMSG_SERVICE_GROUPRENAME     => 0x13;
const YMSG_SERVICE_SYSMESSAGE      => 0x14;
const YMSG_SERVICE_PASSTHROUGH2    => 0x16;
const YMSG_SERVICE_CONFINVITE      => 0x18;
const YMSG_SERVICE_CONFLOGON       => 0x19;
const YMSG_SERVICE_CONFDECLINE     => 0x1A;
const YMSG_SERVICE_CONFLOGOFF      => 0x1B;
const YMSG_SERVICE_CONFADDINVITE   => 0x1C;
const YMSG_SERVICE_CONFMSG         => 0x1D;
const YMSG_SERVICE_CHATLOGON       => 0x1E;
const YMSG_SERVICE_CHATLOGOFF      => 0x1F;
const YMSG_SERVICE_CHATMSG         => 0x20;
const YMSG_SERVICE_GAMELOGON       => 0x28;
const YMSG_SERVICE_GAMELOGOFF      => 0x29;
const YMSG_SERVICE_GAMEMSG         => 0x2A;
const YMSG_SERVICE_FILETRANSFER    => 0x46;
const YMSG_SERVICE_VOICECHAT       => 0x4A;
const YMSG_SERVICE_NOTIFY          => 0x4B;
const YMSG_SERVICE_VERIFY          => 0x4C;
const YMSG_SERVICE_P2PFILEXFER     => 0x4D;
const YMSG_SERVICE_PEERTOPEER      => 0x4F;
const YMSG_SERVICE_AUTHRESP        => 0x54;
const YMSG_SERVICE_LIST            => 0x55; # after auth, serv sends us our first/last name
const YMSG_SERVICE_LIST_Y15        => 0xF1; # getting the buddy list
const YMSG_SERVICE_AUTH            => 0x57;
const YMSG_SERVICE_ADDBUDDY        => 0x83;
const YMSG_SERVICE_REMBUDDY        => 0x84;
const YMSG_SERVICE_IGNORECONTACT   => 0x85;
const YMSG_SERVICE_REJECTCONTACT   => 0x86;
const YMSG_SERVICE_ACCEPTCONTACT   => 0xD6;
const YMSG_SERVICE_DISCONNECT      => 0x07D1;
const YMSG_SERVICE_BUDDYSTATUS     => 0xC6;

1;
