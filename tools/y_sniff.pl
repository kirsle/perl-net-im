#!/usr/bin/perl

use Term::ANSIColor;
use Socket;
use Data::Dumper;

use strict;

$|++;
$/ = '#';

#dimg1.msg.vip.mud.yahoo.com
my $VERSION = "1.0";

print colored("\n\tYahoo Packet Sniffer v$VERSION\n-----------------------------------------\n\n", "cyan");
print "Usage: sudo perl y_sniff.pl <interface || eth0>\n";
my $if = shift(@ARGV) || "eth0";

my $services = {
	YMSG_SERVICE_USER_LOGIN => 1,
	YMSG_SERVICE_USER_LOGOFF => 2,
	YMSG_SERVICE_USER_AWAY => 3,
	YMSG_SERVICE_USER_BACK => 4,
	YMSG_SERVICE_USER_GET_MSGS => 5,
	YMSG_SERVICE_USER_HAS_MSG => 6,
	YMSG_SERVICE_ACTIVATE_ID => 7,
	YMSG_SERVICE_DEACTIVATE_ID => 8,
	YMSG_SERVICE_GET_USER_STATUS => 10,
	YMSG_SERVICE_USER_HAS_MAIL => 11,
	YMSG_SERVICE_START_CONFERENCE => 12,
	YMSG_SERVICE_CALENDAR_ALERT => 13,
	YMSG_SERVICE_USER_PERSONAL_MESSAGE => 14,
	YMSG_SERVICE_UPDATE_BUDDY_LIST => 15,
	YMSG_SERVICE_UPDATE_ID_LIST => 16,
	YMSG_SERVICE_UPDATE_IGNORE_LIST => 17,
	YMSG_SERVICE_PING => 18,
	YMSG_SERVICE_UPDATE_GROUP => 19,
	YMSG_SERVICE_SYSTEM_MESSAGE => 20,
	YMSG_SERVICE_CLIENT_STATS => 21,
	YMSG_SERVICE_CLIENT_ALERT_STATS => 22,
	YMSG_SERVICE_GROUP_MESSAGE => 23,
	YMSG_SERVICE_HOST_CONFERENCE => 24,
	YMSG_SERVICE_JOIN_CONFERENCE => 25,
	YMSG_SERVICE_DECLINE_CONFERENCE => 26,
	YMSG_SERVICE_LEAVE_CONFERENCE => 27,
	YMSG_SERVICE_LEAVE_CONFERENCE => 27,
	YMSG_SERVICE_INVITE_CONFERENCE => 28,
	YMSG_SERVICE_SAY_CONFERENCE => 29,
	YMSG_SERVICE_CHAT_LOGIN => 30,
	YMSG_SERVICE_CHAT_LOGOFF => 31,
	YMSG_SERVICE_CHAT_MSG => 32,
	YMSG_SERVICE_GAMES_USER_LOGIN => 40,
	YMSG_SERVICE_GAMES_USER_LOGOFF => 41,
	YMSG_SERVICE_GAMES_USER_HAS_MSG => 42,
	YMSG_SERVICE_NET2PHONE_STATS => 44,
	YMSG_SERVICE_ADDRESSBOOK_ALERT => 51,
	YMSG_SERVICE_AUCTION_ALERT => 60,
	YMSG_SERVICE_USER_FT => 70,
	YMSG_SERVICE_USER_FT_REPL => 71,
	YMSG_SERVICE_USER_CONVERSE => 72,
	YMSG_SERVICE_USER_WEBTOUR => 73,
	YMSG_SERVICE_IM_ENABLE_VOICE => 74,
	YMSG_SERVICE_SEND_PORT_CHECK => 76,
	YMSG_SERVICE_USER_SEND_MESG => 75,
	YMSG_SERVICE_SEND_DATA_THRU => 77,
	YMSG_SERVICE_P2P_START => 79,
	YMSG_SERVICE_MSGR_WEBCAM_TOKEN => 80,
	YMSG_SERVICE_STATS => 81,
	YMSG_SERVICE_USER_LOGIN_2 => 84,
	YMSG_SERVICE_PRELOGIN_DATA => 85,
	YMSG_SERVICE_GET_COOKIE_DATA => 86,
	YMSG_SERVICE_HELO => 87,
	YMSG_SERVICE_FEATURE_NOT_SUPPORTED => 88,
	YMSG_SERVICE_NEWS_ALERTS => 300,
	YMSG_SERVICE_SYMANTEC_MSGS => 500,
	YMSG_SERVICE_MOBILE_SEND_SMS_MESSAGE => 746,
	YMSG_SERVICE_MOBILE_SMS_LOGIN => 748,
	YMSG_SERVICE_MOBILE_SMS_NUMBER => 749,
	YMSG_SERVICE_ANON_LOGOFF => 802,
	YMSG_SERVICE_ANON_HAS_MSG => 806,
	YMSG_SERVICE_ADD_BUDDY => 131,
	YMSG_SERVICE_REMOVE_BUDDY => 132,
	YMSG_SERVICE_MODIFY_IGNORE_LIST => 133,
	YMSG_SERVICE_DENY_BUDDY_ADD => 134,
	YMSG_SERVICE_RENAME_GROUP => 137,
	YMSG_SERVICE_KEEP_ALIVE => 138,
	YMSG_SERVICE_YPC_ADD_FRIEND_APPROVAL => 139,
	YMSG_SERVICE_CHALLENGE => 140,
	YMSG_SERVICE_ADD_BUDDY_INSTANT_APPROVAL => 141,
	YMSG_SERVICE_CHAT_MSGR_USER_LOGIN => 150,
	YMSG_SERVICE_CHAT_GOTO_USER => 151,
	YMSG_SERVICE_CHAT_ROOM_JOIN => 152,
	YMSG_SERVICE_CHAT_ROOM_PART => 155,
	YMSG_SERVICE_CHAT_ROOM_INVITE => 157,
	YMSG_SERVICE_CHAT_MSGR_USER_LOGOFF => 160,
	YMSG_SERVICE_CHAT_PING => 161,
	YMSG_SERVICE_CHAT_WEBCAM_TOKEN => 167,
	YMSG_SERVICE_CHAT_PUBLIC_MSG => 168,
	YMSG_SERVICE_CHAT_ROOM_CREATE => 169,
	YMSG_SERVICE_GAMES_INVITE => 183,
	YMSG_SERVICE_GAMES_SEND_DATA => 184,
	YMSG_SERVICE_EDIT_INVISIBLE_TO_LIST => 185,
	YMSG_SERVICE_EDIT_VISIBLE_TO_LIST => 186,
	YMSG_SERVICE_ANTIBOT => 187,
	YMSG_SERVICE_AVATAR_CHANGED => 188,
	YMSG_SERVICE_FRIEND_ICON => 189,
	YMSG_SERVICE_FRIEND_ICON_DOWNLOAD => 190,
	YMSG_SERVICE_AVATAR_GET_FILE => 191,
	YMSG_SERVICE_AVATAR_GET_HASH => 192,
	YMSG_SERVICE_DISPLAY_TYPE_CHANGED => 193,
	YMSG_SERVICE_FRIEND_ICON_FT => 194,
	YMSG_SERVICE_GET_COOKIE => 195,
	YMSG_SERVICE_ADDRESS_BOOK_CHANGED => 196,
	YMSG_SERVICE_SET_VISIBILITY => 197,
	YMSG_SERVICE_SET_AWAY_STATUS => 198,
	YMSG_SERVICE_AVATAR_PREFS => 199,
	YMSG_SERVICE_VERIFY_USER => 200,
	YMSG_SERVICE_AUDIBLE => 208,
	YMSG_SERVICE_IM_PANEL_FEATURE => 210,
	YMSG_SERVICE_SHARE_CONTACTS => 211,
	YMSG_SERVICE_IM_SESSION => 212,
	YMSG_SERVICE_SUBSCRIPTION => 213,
	YMSG_SERVICE_ADD_BUDDY_AUTHORIZE => 214,
	YMSG_SERVICE_PHOTO_ADD => 215,
	YMSG_SERVICE_PHOTO_SELECT => 216,
	YMSG_SERVICE_PHOTO_DELETE => 217,
	YMSG_SERVICE_PHOTO_FILE_REQUEST => 218,
	YMSG_SERVICE_PHOTO_POINTER => 219,
	YMSG_SERVICE_FXFER_INVITE => 220,
	YMSG_SERVICE_FXFER_SEND => 221,
	YMSG_SERVICE_FXFER_RECEIVE => 222,
	YMSG_SERVICE_UPDATE_CAPABILITY => 223,
	YMSG_SERVICE_REPORT_SPIM => 224,
	YMSG_SERVICE_MINGLE_DATA => 225,
	YMSG_SERVICE_ALERT => 226,
	YMSG_SERVICE_APP_REGISTRY => 227,
	YMSG_SERVICE_NEW_USER => 228,
	YMSG_SERVICE_ACCEPT_MSGR_INVITE => 229,
	YMSG_SERVICE_MSGR_USAGE => 230,
	YMSG_SERVICE_BUDDY_MOVE => 231,
	YMSG_SERVICE_GET_VOICE_CRUMB => 232,
	YMSG_SERVICE_BUDDY_INFO => 240,
	YMSG_SERVICE_BUDDY_LIST => 241,
	YMSG_SERVICE_CLIENT_NETSTAT => 1000,
	YMSG_SERVICE_P2P_USER => 1001,
	YMSG_SERVICE_P2P_STATE => 1002,
	YMSG_SERVICE_LWM_LOGIN => 1100,
	YMSG_SERVICE_LWM_LOGOFF => 1101,
	YMSG_SERVICE_OPI_LOGIN => 1102,
	YMSG_SERVICE_OPI_LOGOFF => 1103,
	YMSG_SERVICE_OPI_IM => 1104,
	YMSG_SERVICE_USER_HAS_OPI_MESSAGE => 1105,
	YMSG_SERVICE_LWMOPI_CHECKLOGIN => 1106,
	YMSG_SERVICE_LWMOPI_STARTOPI => 1107,
	YMSG_SERVICE_LWMOPI_STOPOPI => 1108,
	YMSG_SERVICE_STATUS_ERR => -1,
	YMSG_SERVICE_STATUS_DUPLICATE => -3,
	YMSG_SERVICE_STATUS_OK => 0,
	YMSG_SERVICE_STATUS_NOTIFY => 1,
	YMSG_SERVICE_STATUS_NOT_AVAILABLE => 2,
	YMSG_SERVICE_STATUS_NEW_BUDDYOF => 3,
	YMSG_SERVICE_STATUS_PARTIAL_LIST => 5,
	YMSG_SERVICE_STATUS_SAVED_MESG => 6,
	YMSG_SERVICE_STATUS_BUDDYOF_DENIED => 7,
	YMSG_SERVICE_STATUS_INVALID_USER => 8,
	YMSG_SERVICE_STATUS_CHUNKING => 9,
	YMSG_SERVICE_STATUS_INVITED => 11,
	YMSG_SERVICE_STATUS_DONT_DISTURB => 12,
	YMSG_SERVICE_STATUS_DISTURB_ME => 13,
	YMSG_SERVICE_STATUS_NEW_BUDDYOF_AUTH => 15,
	YMSG_SERVICE_STATUS_WEB_MESG => 16,
	YMSG_SERVICE_STATUS_REQUEST => 17,
	YMSG_SERVICE_STATUS_ACK => 18,
	YMSG_SERVICE_STATUS_RELOGIN => 19,
	YMSG_SERVICE_STATUS_SPECIFIC_SNDR => 22,
	YMSG_SERVICE_STATUS_SMS_CARRIER => 29,
	YMSG_SERVICE_STATUS_ISGROUP_IM => 33,
	YMSG_SERVICE_STATUS_INCOMP_VERSION => 24,
	YMSG_SERVICE_STATUS_CMD_SENT_ACK => 1000,
	YMSG_SERVICE_STATUS_FT_REPLY => 0,
	YMSG_SERVICE_STATUS_FT_ERROR => -1,
	YMSG_SERVICE_STATUS_FT_NOTIFY => 1,
	YMSG_SERVICE_STATUS_FT_NOTIFY_SAVED => 2,
	YMSG_SERVICE_STATUS_WEBTOUR_OK => 1,
	YMSG_SERVICE_STATUS_CONVERSE_OK => 1,
	YMSG_SERVICE_STATUS_UNKNOWN_USER => 1515563605,
	YMSG_SERVICE_STATUS_KNOWN_USER => 1515563606,
	YMSG_SERVICE_CORP_USER_LOGIN => 450,
	YMSG_SERVICE_EE_LOGIN => 450,
	YMSG_SERVICE_MSGREE_LOGIN => 451,
	YMSG_SERVICE_CORP_ID_COPRP2PINIT => 452,
	YMSG_SERVICE_CORP_CHAT_MSG => 453,
	YMSG_SERVICE_CORP_GAMES_USER_HAS_MSG => 454,
	YMSG_SERVICE_SECURE_USER_LOGIN => 460,
	YMSG_SERVICE_SECURE_IM_MSG => 461,
	YMSG_SERVICE_SECURE_CHAT_SAY_MESG => 463,
	YMSG_SERVICE_SECURE_GAMES_USER_HAS_MSG => 464,
};
my $fields = {
	YMSG_FLD_INVALID => -1,
	YMSG_FLD_USER_NAME => 0,
	YMSG_FLD_CURRENT_ID => 1,
	YMSG_FLD_ACTIVE_ID => 2,
	YMSG_FLD_USER_ID => 3,
	YMSG_FLD_SENDER => 4,
	YMSG_FLD_TARGET_USER => 5,
	YMSG_FLD_PASSWORD => 6,
	YMSG_FLD_BUDDY => 7,
	YMSG_FLD_NUM_BUDDIES => 8,
	YMSG_FLD_NUM_EMAILS => 9,
	YMSG_FLD_AWAY_STATUS => 10,
	YMSG_FLD_SESSION_ID => 11,
	YMSG_FLD_IP_ADDRESS => 12,
	YMSG_FLD_FLAG => 13,
	YMSG_FLD_MSG => 14,
	YMSG_FLD_TIME => 15,
	YMSG_FLD_ERR_MSG => 16,
	YMSG_FLD_PORT => 17,
	YMSG_FLD_MAIL_SUBJECT => 18,
	YMSG_FLD_AWAY_MSG => 19,
	YMSG_FLD_URL => 20,
	YMSG_FLD_ALERT_TIME => 21,
	YMSG_FLD_NEWS => 22,
	YMSG_FLD_DEV_SPEED => 23,
	YMSG_FLD_WEB_ID => 24,
	YMSG_FLD_USER_ALERT_STATS => 25,
	YMSG_FLD_STATS_DATA => 26,
	YMSG_FLD_FILE_NAME => 27,
	YMSG_FLD_FILE_SIZE => 28,
	YMSG_FLD_FILE_DATA => 29,
	YMSG_FLD_SYMANTEC_IPADDR => 30,
	YMSG_FLD_COMMAND => 31,
	YMSG_FLD_STATUS => 32,
	YMSG_FLD_NUM_NEWS => 33,
	YMSG_FLD_NUM_MSGS => 34,
	YMSG_FLD_ITEM => 35,
	YMSG_FLD_OLD_GRP_NAME => 36,
	YMSG_FLD_NEW_GRP_NAME => 37,
	YMSG_FLD_EXPIRATION_TIME => 38,
	YMSG_FLD_NUM_PERSONAL_MSGS => 39,
	YMSG_FLD_SYS_MSG_CODE => 40,
	YMSG_FLD_MSG_NUM_DUMMY => 41,
	YMSG_FLD_FROM_EMAIL => 42,
	YMSG_FLD_FROM_NAME => 43,
	YMSG_FLD_ADD_ID => 44,
	YMSG_FLD_DELETE_ID => 45,
	YMSG_FLD_DEBUG_INFO => 46,
	YMSG_FLD_CUSTOM_DND_STATUS => 47,
	YMSG_FLD_CONTAINS_TAGS => 48,
	YMSG_FLD_APPNAME => 49,
	YMSG_FLD_NET2PHONE_CALL_LEN => 50,
	YMSG_FLD_AD_SPACE_ID => 51,
	YMSG_FLD_USES_IMIP_CLIENT => 52,
	YMSG_FLD_SHORTCUT => 53,
	YMSG_FLD_FEED_VER => 54,
	YMSG_FLD_INVITOR_NAME => 50,
	YMSG_FLD_INVITEE_NAME => 51,
	YMSG_FLD_INVITED_USER => 52,
	YMSG_FLD_JOINED_USER => 53,
	YMSG_FLD_DECLINED_USER => 54,
	YMSG_FLD_UNAVAILABLE_USER => 55,
	YMSG_FLD_LEFT_USER => 56,
	YMSG_FLD_ROOM_NAME => 57,
	YMSG_FLD_CONF_TOPIC => 58,
	YMSG_FLD_COOKIE => 59,
	YMSG_FLD_DEVICE_TYPE => 60,
	YMSG_FLD_USER_TYPE => 60,
	YMSG_FLD_WEBCAM_TOKEN => 61,
	YMSG_FLD_WEBCAM_STATUS => 62,
	YMSG_FLD_TIMED_P2P_CONN_FLG => 61,
	YMSG_FLD_IMV_ID => 63,
	YMSG_FLD_IMV_FLAG => 64,
	YMSG_FLD_BUDDY_GRP_NAME => 65,
	YMSG_FLD_ERROR_CODE => 66,
	YMSG_FLD_NEWBUDDYGRP_NAME => 67,
	YMSG_FLD_PHONE_CARRIER_CODE => 68,
	YMSG_FLD_SCREEN_NAME => 69,
	YMSG_FLD_CONVERSE_COMMAND => 70,
	YMSG_FLD_CONVERSE_IDENTITY => 71,
	YMSG_FLD_CONVERSE_OTHERGUY => 72,
	YMSG_FLD_CONVERSE_TOPIC => 73,
	YMSG_FLD_CONVERSE_COMMENT => 74,
	YMSG_FLAG_CONVERSE_MAX => 75,
	YMSG_FLAG_CONVERSE_URL => 76,
	YMSG_FLAG_CONVERSE_YOURCOMMENT => 77,
	YMSG_FLD_STAT_TYPE => 78,
	YMSG_FLD_IMIP_SERVICE => 79,
	YMSG_FLD_IMIP_LOGIN => 80,
	YMSG_FLD_ALERT_TYPEID => 81,
	YMSG_FLD_ALERT_SUBTYPEID => 82,
	YMSG_FLD_ALERT_DOC_TITLE => 83,
	YMSG_FLD_ALERT_PRIO_LEVEL => 84,
	YMSG_FLD_ALERT_TYPE => 85,
	YMSG_FLD_ALERT_COUNTRY => 86,
	YMSG_FLD_BUDDY_LIST => 87,
	YMSG_FLD_IGNORE_LIST => 88,
	YMSG_FLD_IDENTITY_LIST => 89,
	YMSG_FLD_HAS_MAIL => 90,
	YMSG_FLD_CONVERSE_CMD_DECTEXT => 90,
	YMSG_FLD_SMS_PHONE => 70,
	YMSG_FLD_ANON_NAME => 91,
	YMSG_FLD_ANON_ID => 92,
	YMSG_T_COOKIE_EXPIRE => 93,
	YMSG_FLD_CHALLENGE => 94,
	YMSG_FLD_OLD_PASSWORD => 96,
	YMSG_FLD_UTF8_FLAG => 97,
	YMSG_FLD_COUNTRY_CODE => 98,
	YMSG_FLD_COBRAND_CODE => 99,
	YMSG_FLD_DATE => 100,
	YMSG_FLD_IMV_DATA => 101,
	YMSG_FLD_WEBCAM_FARM => 102,
	YMSG_FLD_NETSTAT_MSG => 1000,
	YMSG_FLD_SERVER_TYPE => 1001,
	YMSG_FLD_TRY_P2P => 1002,
	YMSG_FLD_P2P_CONN_STATE => 1003,
	YMSG_FLD_INTERNET_CONN_TYPE => 1004,
	YMSG_NEED_CMD_RETURN => 1005,
	YMSG_FLD_CHAT_IGNORE_USER => 103,
	YMSG_FLD_CHAT_ROOM_NAME => 104,
	YMSG_FLD_CHAT_ROOM_TOPIC => 105,
	YMSG_FLD_CHAT_ROOM_URL => 106,
	YMSG_FLD_CHAT_ROOM_PARAMETER => 107,
	YMSG_FLD_CHAT_NUM_USERS => 108,
	YMSG_FLD_CHAT_ROOM_USER_NAME => 109,
	YMSG_FLD_CHAT_ROOM_USER_AGE => 110,
	YMSG_FLD_CHAT_ROOM_USER_GENDER => 111,
	YMSG_FLD_CHAT_ROOM_USER_TIMESTAMP => 112,
	YMSG_FLD_CHAT_ROOM_USER_FLAG => 113,
	YMSG_FLD_CHAT_ERR_NO => 114,
	YMSG_FLD_CHAT_SIMILAR_ROOM => 115,
	YMSG_FLD_CHAT_EMOT_MSG => 116,
	YMSG_FLD_CHAT_MSG => 117,
	YMSG_FLD_CHAT_INVITED_USER => 118,
	YMSG_FLD_CHAT_INVITER => 119,
	YMSG_FLD_CHAT_EXTENDED_DATA_ID => 120,
	YMSG_FLD_CHAT_EXTENDED_DATA => 121,
	YMSG_FLD_CHAT_USER_SETTINGS => 122,
	YMSG_FLD_CHAT_LOGOFF_MSG => 123,
	YMSG_FLD_CHAT_MSG_TYPE => 124,
	YMSG_FLD_CHAT_FRAME_NAME => 125,
	YMSG_FLD_CHAT_FLG => 126,
	YMSG_FLD_CHAT_ROOM_TYPE => 127,
	YMSG_FLD_CHAT_ROOM_CATEGORY => 128,
	YMSG_FLD_CHAT_ROOM_SPACEID => 129,
	YMSG_FLD_CHAT_VOICE_AUTH => 130,
	YMSG_FLD_ALERT_BUTTONLABEL => 131,
	YMSG_FLD_ALERT_BUTTONLINK => 132,
	YMSG_FLD_ALERT_MIN_DIMENSION => 133,
	YMSG_FLD_BIZ_MAIL_TEXT => 134,
	YMSG_FLD_VERSION => 135,
	YMSG_FLD_COBRAND_ROOM_INFO => 136,
	YMSG_FLD_IDLE_TIME => 137,
	YMSG_FLD_NO_IDLE_TIME => 138,
	YMSG_FLD_CHAT_USER_NICKNAME => 141,
	YMSG_FLD_CHAT_USER_LOCATION => 142,
	YMSG_FLD_PING_INTERVAL => 143,
	YMSG_FLD_KEEP_ALIVE_INTERVAL => 144,
	YMSG_FLD_CPU_TYPE => 145,
	YMSG_FLD_OS_VERSION => 146,
	YMSG_FLD_TIME_ZONE => 147,
	YMSG_FLD_TIME_BIAS => 148,
	YMSG_FLD_BLINDED_USERID => 149,
	YMSG_FLD_CACHE_CRYPTO_KEY => 150,
	YMSG_FLD_LOCAL_CRYPTO_KEY => 151,
	YMSG_FLD_YPC_PREFS => 153,
	YMSG_FLD_PARENT_ID => 154,
	YMSG_FLD_MSG_NUM => 159,
	YMSG_FLD_GAME_ID => 180,
	YMSG_FLD_GAME_NAME => 181,
	YMSG_FLD_GAME_DATA => 182,
	YMSG_FLD_GAME_URL => 183,
	YMSG_FLD_STATUS_DATA => 184,
	YMSG_FLD_INVISIBLE_TO => 185,
	YMSG_FLD_VISIBLE_TO => 186,
	YMSG_FLD_STATUS_LINK_TYPE => 187,
	YMSG_FLD_AVATAR_FLAG => 190,
	YMSG_FLD_AVATAR_MOOD_ID => 191,
	YMSG_FLD_ICON_CHECKSUM => 192,
	YMSG_FLD_ICON_DATA => 193,
	YMSG_FLD_SEQUENCE_NO => 194,
	YMSG_FLD_MAX_SEQUENCE_NO => 195,
	YMSG_FLD_ANTIBOT_TEXT => 196,
	YMSG_FLD_AVATAR_HASH => 197,
	YMSG_FLD_AVATAR_USER => 198,
	YMSG_FLD_WIDTH => 199,
	YMSG_FLD_HEIGHT => 200,
	YMSG_FLD_ALERT_DATA => 203,
	YMSG_FLD_AVATAR_DEFMOOD => 204,
	YMSG_FLD_AVATAR_ZOOM => 205,
	YMSG_FLD_DISPLAY_TYPE => 206,
	YMSG_FLD_BTUSER_ID => 207,
	YMSG_FLD_T_COOKIE => 208,
	YMSG_FLD_STATS_BUFFER => 211,
	YMSG_FLD_APPLY_TO_ALL => 212,
	YMSG_FLD_SHOW_MY_AVATAR_IN_FRIEND_TREE => 213,
	YMSG_FLD_GAME_PROWLER_PREF => 214,
	YMSG_FLD_VAS_USER => 215,
	YMSG_FLD_NICKNAME => 216,
	YMSG_FLD_YPM_KEY => 217,
	YMSG_FLD_AVATAR_COUNT => 218,
	YMSG_FLD_ANTIBOT_URL => 225,
	YMSG_FLD_ANTIBOT_SECRET => 226,
	YMSG_FLD_ANTIBOT_RESPONSE => 227,
	YMSG_FLD_AUDIBLE_ID => 230,
	YMSG_FLD_AUDIBLE_TEXT => 231,
	YMSG_FLD_AUDIBLE_HASH => 232,
	YMSG_FLD_EE_CONFIRM_DELIVERY => 160,
	YMSG_FLD_EE_SENDER => 161,
	YMSG_FLD_EE_NONCE => 162,
	YMSG_FLD_FEATURE_ID => 221,
	YMSG_FLD_ACTION_TYPE => 222,
	YMSG_FLD_UNAUTH => 223,
	YMSG_FLD_GROUP => 224,
	YMSG_FLD_IGNORED_USER => 236,
	YMSG_FLD_PROFILE_ID => 237,
	YMSG_FLD_INVISIBLE_TO_FRIEND => 238,
	YMSG_FLD_VISIBLE_TO_FRIEND => 239,
	YMSG_FLD_CONTACT_INFO => 240,
	YMSG_FLD_CLOUD_ID => 241,
	YMSG_FLD_BRANDING_ID => 242,
	YMSG_FLD_NUM_ATTRIBUTED_BUDDIES => 243,
	YMSG_FLD_CAPABILITY_MATRIX => 244,
	YMSG_FLD_OBJECT_ID => 245,
	YMSG_FLD_OBJECT_NAME => 246,
	YMSG_FLD_META_DATA => 247,
	YMSG_FLD_OBJECT_SIZE => 248,
	YMSG_FLD_TRANSFER_TYPE => 249,
	YMSG_FLD_TRANSFER_TAG => 250,
	YMSG_FLD_TOKEN => 251,
	YMSG_FLD_HASH => 252,
	YMSG_FLD_CHECKSUM => 253,
	YMSG_FLD_LASTNAME => 254,
	YMSG_FLD_DATA => 257,
	YMSG_FLD_APP_ID => 258,
	YMSG_FLD_INSTANCE_ID => 259,
	YMSG_FLD_ALERT_ID => 260,
	YMSG_FLD_OPI_STATUS => 261,
	YMSG_FLD_APP_REGISTER => 262,
	YMSG_FLD_CHECKLOGIN_STATUS => 263,
	YMSG_FLD_TARGET_GROUP => 264,
	YMSG_FLD_FT_SESSION_ID => 265,
	YMSG_FLD_TOTAL_FILE_COUNT => 266,
	YMSG_FLD_THUMBNAIL => 267,
	YMSG_FLD_FILE_INFO => 268,
	YMSG_FLD_SPAMMER_ID => 269,
	YMSG_FLD_INITIATOR => 270,
	YMSG_FLD_FT_ONE_FILE_DONE => 271,
	YMSG_FLD_XPOS => 272,
	YMSG_FLD_YPOS => 273,
	YMSG_FLD_MSG_RECORD => 274,
	YMSG_FLD_FLAG_MINGLE_USER => 275,
	YMSG_FLD_ABUSE_SIGNATURE => 276,
	YMSG_FLD_LOGIN_Y_COOKIE => 277,
	YMSG_FLD_LOGIN_T_COOKIE => 278,
	YMSG_FLD_LOGIN_CRUMB => 279,
	YMSG_FLD_BUDDY_DETAIL => 280,
	YMSG_FLD_VALID_CLIENT_COOKIES => 281,
	YMSG_FLD_NUM_LCS_BUDDIES => 282,
	YMSG_FLD_IS_RELOGIN => 283,
	YMSG_FLD_START_OF_RECORD => 300,
	YMSG_FLD_END_OF_RECORD => 301,
	YMSG_FLD_START_OF_LIST => 302,
	YMSG_FLD_END_OF_LIST => 303,
	YMSG_FLD_CRUMB_HASH => 307,
	YMSG_FLD_PLUGIN_INFO => 316,
	YMSG_FLD_VISIBILITY_FLAG => 317,
	YMSG_FLD_GROUPS_RECORD_LIST => 318,
	YMSG_FLD_BUDDIES_RECORD_LIST => 319,
	YMSG_FLD_IGNORED_BUDDIES_RECORD_LIST => 320,
	YMSG_FLD_YMAIL_FARM => 10001,
	YMSG_FLD_PERSONALS_USER => 10002,
	YMSG_FLD_END => -1,
};

my $status = {
	YMSG_SERVICE_STATUS_ERR => -1,
	YMSG_SERVICE_STATUS_DUPLICATE => -3,
	YMSG_SERVICE_STATUS_OK => 0,
	YMSG_SERVICE_STATUS_NOTIFY => 1,
	YMSG_SERVICE_STATUS_NOT_AVAILABLE => 2,
	YMSG_SERVICE_STATUS_NEW_BUDDYOF => 3,
	YMSG_SERVICE_STATUS_PARTIAL_LIST => 5,
	YMSG_SERVICE_STATUS_SAVED_MESG => 6,
	YMSG_SERVICE_STATUS_BUDDYOF_DENIED => 7,
	YMSG_SERVICE_STATUS_INVALID_USER => 8,
	YMSG_SERVICE_STATUS_CHUNKING => 9,
	YMSG_SERVICE_STATUS_INVITED => 11,
	YMSG_SERVICE_STATUS_DONT_DISTURB => 12,
	YMSG_SERVICE_STATUS_DISTURB_ME => 13,
	YMSG_SERVICE_STATUS_NEW_BUDDYOF_AUTH => 15,
	YMSG_SERVICE_STATUS_WEB_MESG => 16,
	YMSG_SERVICE_STATUS_REQUEST => 17,
	YMSG_SERVICE_STATUS_ACK => 18,
	YMSG_SERVICE_STATUS_RELOGIN => 19,
	YMSG_SERVICE_STATUS_SPECIFIC_SNDR => 22,
	YMSG_SERVICE_STATUS_SMS_CARRIER => 29,
	YMSG_SERVICE_STATUS_ISGROUP_IM => 33,
	YMSG_SERVICE_STATUS_INCOMP_VERSION => 24,
	YMSG_SERVICE_STATUS_CMD_SENT_ACK => 1000,
#	YMSG_SERVICE_STATUS_FT_REPLY => 0,
#	YMSG_SERVICE_STATUS_FT_ERROR => -1,
#	YMSG_SERVICE_STATUS_FT_NOTIFY => 1,
#	YMSG_SERVICE_STATUS_FT_NOTIFY_SAVED => 2,
#	YMSG_SERVICE_STATUS_WEBTOUR_OK => 1,
#	YMSG_SERVICE_STATUS_CONVERSE_OK => 1,
	YMSG_SERVICE_STATUS_UNKNOWN_USER => 1515563605,
	YMSG_SERVICE_STATUS_KNOWN_USER => 1515563606,
};

my $sep = "\xC0\x80";
sub getNameByValue{
        my $hash = shift;
		my $value = shift;
        foreach my $name (keys(%$hash)){
                return $name if $hash->{$name} == $value;
        }
		return $value;
}

print "Listening to network on $if\n\n";
open(NG,"ngrep -x -ltd $if YMSG |");
#open(NG,"ngrep -x -ltd en0 ^YMSG |");

while(<NG>) {
    s/#$//;
    my $packet = $_;

    my $data = '';

    if($packet =~  m/\nT/){
        my ($cap_header, $body) = $packet =~ m/\nT\s+(.*?)\n(.*?$)/gsi;
        $cap_header =~ s/\s->//;
        # CAP HEADER: 2009/09/15 11:45:53.495064 10.10.50.97:61763 -> 68.180.217.10:5050 [AP] 
        my ($date, $time, $from, $to, undef)  = split(' ', $cap_header);
        my $color = ($to =~ m/\:(5050)|(80)/)?'green':'red';
        
        print colored("FROM $from TO: $to \n\n$body\n\n", $color);
        my @rows = split("\n", $body);
        my $data = '';
        foreach my $row (@rows){
            my ($chunk) = $row =~ /(.{52})/;
            $chunk =~ s/\s//gs;
            $data .= $chunk;
            #$data .= pack("c*", split(' ', $chunk));
        }
        $data =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg;
        my $sep = "\xC0\x80";
        
        my $pack = {};
        my $body = '';
        (
			$pack->{'Service'}, 
			$pack->{'Version'}, 
			$pack->{'VendorId'}, 
			$pack->{'BodyLength'}, 
			$pack->{'ServiceCode'}, 
			$pack->{'ServiceStatus'},
			$pack->{'SessionId'}, $body) = unpack("a4n4NVa*", $data); 	 
			$pack->{'ServiceStatusName'} = getNameByValue($status, $pack->{'ServiceStatus'});
			$pack->{'ServiceName'} = getNameByValue($services, $pack->{'ServiceCode'});
			
        print colored(Dumper($pack), $color)."\n";
        my @bits = split(/\Q$sep\E/, $body);        
        # The eventual hashref.
        my $map = {};
        for (my $i = 0; $i < scalar(@bits); $i += 2) {
			my ($field, $value) = ($bits[$i], $bits[ $i + 1 ]);
			$field = getNameByValue($fields, $field);
			print colored("$field => $value", $color)."\n";
        }
		print  "\n" . "-" x 100 ."\n\n";
    }
}
