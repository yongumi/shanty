# Shanty

## What is Shanty?

> Oh the mate likes whiskey, the skipper likes rum
> The sailors like both but me can't get none

> \[a song\] originally sung by sailors while performing physical labor together.

Shanty is a simple network protocol that allows software to communicate with the least amount of effort. Shanty provides enough just enough functionality for it to be useful. It isn't as complex or as legacy bound as HTTP.

Shanty is also a collection of source code that implements the Shanty protocol. Current Shanty implementations include Objective-C for iOS and Mac OS X and Python.

Shanty also supports Bonjour DNS-SD based service discovery and publishing.

## What can I do with Shanty?

> We hove our ship to with the wind at sou'west, boys
> We hove our ship to, our soundings to see
> So we rounded and sounded; got forty-five fathoms
> We squared our main yard and up channel steered we

Whatever you want.

That said shanty isn't design to replace existing network protocols. It isn't going to the next SPDY. TODO

## How do I use Shanty?

> For then them whales destroyed our boats
> They rammed them one by one
> They stove them all with head and fluke
> And after they was done
> We few poor souls left half-alive
> Was clinging to debris

### Example 1: Creating a server

    self.server = [[STYServer alloc] init];
    self.server.delegate = self;

### Example 2: Writing a handler

    STYMessageBlock theHandler = ^(STYPeer *inPeer, STYMessage *inMessage, NSError **outError) {
        // Handle the messsage however you want
        return(YES);
        }
    [self.server.messageHandler addCommand:@"example" handler:theHandler];

### Example 3: Discovering and connect to a server

    self.discoverer = [[STYServiceDiscoverer alloc] init];
    [self.discoverer start:
        TODO
    ];

## Python Implementation

TODO

## Protocol Information

Shanty is a message framing scheme plus definition for structured messages. Each message consists of a message header, control data, metadata and raw data.

The header contains the lengths of the following data sections, the control data and the metadata sections are both JSON dictionaries (*), while the data section is raw binary data.

Both the metadata section and data section are intended for any use. These sections are intended for application use only. The control section is 

(* TODO: the metadata section could be any JSON type in theory)

    [2 octets]              control data length
    [2 octets]              metadata length
    [4 octets]              data length
    [0...65535 octets]      control data (JSON)
    [0...65535 octets]      metadata (JSON)
    [0...4294967295 octets] data

    standard control data fields:
        cmd
        msgid
        in-reply-to
        more-coming

    standard cmd types:
        hello
        hello.response
        echo
        echo.response
        ping
        ping.response
    
    client sends first 'hello'
    server sends 'hello.response'


# TODO

> We're going away to leave you now
> Hoorah, me boys, we're homeward bound
