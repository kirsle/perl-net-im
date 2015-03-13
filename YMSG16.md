

This will be used to document the YMSG16 protocol
# The Yahoo Packet #

## Header ##

Header size is 20 bytes and include the following:
  * Service name “YMSG” (4 bytes)
  * The protocol version (2 bytes])
  * VendorId flag (2 bytes)
  * Length of the content of the message (2 bytes)
  * Yahoo [service code](YMSG16#ServiceCodes.md) (2 bytes)
  * [Status Code](YMSG16#Status_Codes.md) (4 bytes)
  * Session Id (4 bytes)

```
Y  M  S  G       16     100      16     138             0     65159168
59 4d 53 47 | 00 10 | 00 64 | 00 10 | 00 8a | 00 00 00 00 |00 40 e2 03
```

In our example the service name is of-course YMSG, the protocol version is 16, the VendorId flag is always set to 0 for windows client(and libpurple) and 100 for mac client, and the length of our packet is 138 bytes.

The service code in this example is 0x8a or 138 which is the YAHOO\_SERVICE\_KEEPALIVE of a simple ping.

The status code is basic status of the message.

### Status\_Codes ###

| **Status** | **Code** | **Hex** |
|:-----------|:---------|:--------|
| Client Request | 0 | 0x00000000 |
| Server Response | 1 | 0x00000001 |
| Available | 0 | 0x00000000 |
| Be Right Back | 1 | 0x00000001 |
| Unknown | 1515563605 | 0x5a55aa55 |
| Offline | 1515563606 | 0x5a55aa56 |

Client Request

# Data #

For the remainder of this document, packets will be written in the following format:

```
  YMSG_SERVICE_AUTH, YMSG_STATUS_AVAILABLE
  1: YahooID
```

Where YMSG\_SERVICE\_AUTH is the service code and YMSG\_STATUS\_AVAILABLE is the status sent in the header. The numbers following this are the key/value pairs sent in the body of the message. Refer to the table in [ServiceCodes](YMSG16#ServiceCodes.md) below for the meaning and values of the YMSG**_constants._

In all places where a Yahoo ID is mentioned, this ID should be all lowercase.**

## ServiceCodes ##

<table width='400' border='1'>
<blockquote><thead>
<blockquote><tr>
<blockquote><th>Service</th>
<th>Service Code</th>
</blockquote></tr>
</blockquote></thead>
<tfoot>
</tfoot>
<tbody>
<blockquote><tr>
<blockquote><td><a href='YMSG16#YMSG_STATUS_AVAILABLE.md'>YMSG_STATUS_AVAILABLE</a></td>
<td>
<a href='YMSG16#YMSG_STATUS_AVAILABLE.md'>0x00</a></td>
</blockquote></tr>
<tr>
<blockquote><td><a href='YMSG16#Authentication.md'>YMSG_SERVICE_AUTH</a></td>
<td>0x57</td>
</blockquote></tr>
<tr>
<blockquote><td>YMSG_SERVICE_AUTHRESP</td>
<td>0x54</td>
</blockquote></tr>
<tr>
<blockquote><td>YMSG_SERVICE_NOTIFY</td>
<td>0x4B</td>
</blockquote></tr>
<tr>
<blockquote><td>YMSG_SERVICE_MESSAGE</td>
<td>0x09</td>
</blockquote></tr>
<tr>
<blockquote><td>YMSG_SERVICE_LOGON</td>
<td>0x01</td>
</blockquote></tr>
</blockquote></tbody>
</table></blockquote>

# Authentication #

To begin the auth process, the client connects to the YMSG server at cs101.msg.sp1.yahoo.com or other auth server, and sends the YMSG\_SERVICE\_AUTH packet.

```
  YMSG_SERVICE_AUTH, YMSG_STATUS_AVAILABLE
  1: YahooID
```

The YahooID is the primary ID that the client is attempting to sign on with. It probably should be all lowercase.

If successful, the server will respond with an auth challenge. This packet from the server will look like this:

```
  YMSG_SERVICE_AUTH, YMSG_STATUS_AVAILABLE
  1: YahooID
  13: 2
  94: challenge string
```

1 is your primary YahooID, 13 is usually 2 (???), and 94 is the challenge string. The challenge string is the most important field here.

With the challenge string the client needs to make an HTTPS POST request to the following URL with the following parameters:

```
  POST https://login.yahoo.com/config/pwtoken_get
  src=ymsgr
  ts=
  login=YahooID
  passwd=password
  chal=challenge
```

YahooID is the primary ID, password is their cleartext password, and challenge is the auth challenge received from the server.

If successful, the reply from this page will look like this:

```
  0
  ymsgr=AEejLkUy6t02kuZ_UXdifPhDOaZ1pXGWBIiGuw55QUksy0U-
  partnerid=pXGWBIiGuw55QUksy0U-
```

If the first line is the number 0, it was successful. Other numbers mean different things.

The ymsgr= value is the most important part here; it's an auth token. With the token, we make another HTTPS request:

```
  POST https://login.yahoo.com/config/pwtoken_get
  src=ymsgr
  ts=
  token=AEejLkUy6t02kuZ_UXdifPhDOaZ1pXGWBIiGuw55QUksy0U-
```

Pass the token as a param here. If successful, you'll get a reply back like this:

```
  0
  crumb=XLs.4fhxC8O
  Y=v=1&n=1juip...; path=/; domain=.yahoo.com
  T=z=mI8tKBmOR...; path=/; domain=.yahoo.com
  cookievalidfor=86400
```

There are three important fields in here: crumb, Y, and T. Y and T are cookies; you'll need these to complete the auth. The following regular expressions in Perl extract the right data from these cookies:

```
  $Yv = ($ycookie =~ /^Y=(.+?)$/);
  $Tz = ($tcookie =~ /^T=(.+?)$/);
```

At this point we have: the original auth challenge, the token, the crumb, and the Yv and Tz cookies. To complete the authentication we need to simply make an MD5 hash of the crumb and challenge, encode it with Y64 (Yahoo's version of Base64), and send the AUTHRESP packet.

Here is some Perl code for the MD5 hashing and Y64 encoding:

```
  sub auth16 {
    my ($crumb,$challenge) = @_;

    # Concat the crumb in front of the challenge
    my $crypt = $crumb . $challenge;

    # Make an MD5 hash of it
    my $md5_ctx = Digest::MD5->new();
    $md5_ctx->add ($crypt);
    my $md5_digest = $md5_ctx->digest();

    # Encode in Y64
    my $base64_str = _to_y64($md5_digest);

    return $base64_str;
  }

  # Y64 encoding function, adapted from PHP
  sub _to_y64 {
    my $source_str = shift;
    my @source = split(//, $source_str);
    my @yahoo64 = split(//, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._");
    my $limit = length($source_str) - (length($source_str) % 3);
    my $dest = "";
    my $i;
    for ($i = 0; $i < $limit; $i += 3) {
        $dest .= $yahoo64[ ord($source[$i]) >> 2];
        $dest .= $yahoo64[ ((ord($source[$i]) << 4) & 0x30) | (ord($source[$i + 1]) >> 4) ];
        $dest .= $yahoo64[ ((ord($source[$i + 1]) << 2) & 0x3C) | (ord($source[$i + 2]) >> 6)];
        $dest .= $yahoo64[ ord($source[$i + 2]) & 0x3F ];
    }

    my $switch = length($source_str) - $limit;
    if ($switch == 1) {
        $dest .= $yahoo64[ ord($source[$i]) >> 2];
        $dest .= $yahoo64[ (ord($source[$i]) << 4) & 0x30 ];
        $dest .= '--';
    }
    elsif ($switch == 2) {
        $dest .= $yahoo64[ ord($source[$i]) >> 2];
        $dest .= $yahoo64[ ((ord($source[$i]) << 4) & 0x30) | (ord($source[$i + 1]) >> 4)];
        $dest .= $yahoo64[ ((ord($source[$i + 1]) << 2) & 0x3C) ];
        $dest .= '-';
    }

    return $dest;
  }
```

The result of the hashing and encoding we'll call the Auth16 hash. Complete the authentication with the following packet:

```
  YMSG_SERVICE_AUTHRESP, YMSG_STATUS_AVAILABLE
  1: YahooID
  0: YahooID
  277: Yv Cookie
  278: Tz Cookie
  307: Auth16 hash
  244: 4194239
  2: YahooID
  2: 1
  98: us
  135: 9.0.0.2162
```

Fields 0, 1, and 2 contain the primary Yahoo ID. 277 and 278 are the Y=v and T=z cookies you got earlier in the auth process. 307 is the Y64-encoded auth hash. 244 is the internal build number and will be exactly the number given there. There is an additional "2" key with the value of 1. 98 is the country code ("us" here), and 135 is the YMSG version number (taken from the "About Yahoo Messenger" dialog in the official client).

If successful, the server sends you your buddy list and some other packets.

# Examples #

## Sending and receiving messages ##

Sending:

```
  YMSG_SERVICE_MESSAGE, YMSG_STATUS_AVAILABLE
  0: YahooID
  1: ActiveID
  5: TargetID
  14: Message
```

YahooID is our ID to send the message from. ActiveID is the primary Yahoo ID currently logged in (usually this will be the same as YahooID, unless you have multiple IDs). TargetID is the user you're sending the message to, and Message is the message.

Receiving:

```
  YMSG_SERVICE_MESSAGE, YMSG_STATUS_AVAILABLE
  5: our YahooID
  4: their YahooID
  14: their message
```

5 is our ID, 4 is the ID of the sender, and 14 is the message.

### Buzzing a User ###

To "buzz" a user, simply send a message where the Message is `<ding>`.

## Sending/Receiving Typing Notifications ##

Sending:

```
  YMSG_SERVICE_NOTIFY, YMSG_STATUS_AVAILABLE
  4: our YahooID
  5: target's YahooID
  13: typing status (0 or 1)
  14: space character ' '
  49: literal text "TYPING"
```

Typing status is 1 for typing started and 0 for typing stopped. 14 is literally a space, and 49 is literally the text "TYPING" (with no quotes).

Receiving:

```
  YMSG_SERVICE_NOTIFY, YMSG_STATUS_AVAILABLE
  4: their YahooID
  5: our YahooID
  49: literal text "TYPING"
  13: typing status (0 or 1)
  14: space character ' '
```

Most of these fields are similar to sending typing notification. Note that 4 and 5 are swapped, though. Here 5 is our ID and 4 is the ID of the other person.

## YMSG\_STATUS\_AVAILABLE ##
```
  YMSG_SERVICE_STATUS?, YMSG_STATUS_AVAILABLE
  59 4d 53 47 00 10 00 64    00 18 00 c7 00 00 00 00    YMSG...d........
  00 56 ba 91 33 c0 80 6d    61 74 74 2e 61 75 73 74    .V..3..matt.aust
  69 6e c0 80 32 31 33 c0    80 32 c0 80                in..213..2..  
```