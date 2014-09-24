# Shanty

## What is Shanty?

> Oh the mate likes whiskey, the skipper likes rum
> The sailors like both but me can't get none

> \[a song\] originally sung by sailors while performing physical labor together.

Shanty is a simple network protocol that allows software to communicate with the least amount of effort. Shanty provides just enough functionality for it to be useful out of the box. You should be able to write server and client code with very few lines of code.

Shanty is also a collection of source code that implements the Shanty protocol. Current Shanty implementations include Objective-C (for iOS and Mac OS X) and Python.

Shanty also supports Bonjour DNS-SD based service discovery and publishing. Because Shanty infers sensible defaults for Bonjour it is able to advertise and discover other Shanty services without any configuration.

## What Shanty isn't.

Shanty isn't designed for performance. It probably wouldn't be suitable for video games or for applications that require streaming data.

Shanty isn't designed for robust prioritisation of messages. Messages are transmitted over the network in the order they are sent. There is no concept of important messages taking priority over other messages. Similarly messages are transmitted as whole units, larger messages will "block" smaller messages.

## How do I use Shanty?

> For then them whales destroyed our boats
> They rammed them one by one
> They stove them all with head and fluke
> And after they was done
> We few poor souls left half-alive
> Was clinging to debris

## Protocol Information

> We hove our ship to with the wind at sou'west, boys
> We hove our ship to, our soundings to see
> So we rounded and sounded; got forty-five fathoms
> We squared our main yard and up channel steered we

Shanty is a message framing scheme plus definition for structured messages. Each message consists of a message header, control data, metadata and raw data. 

    [2 octets]              control data length (network endianess)
    [2 octets]              metadata length (network endianess)
    [4 octets]              data length (network endianess)
    [0...65535 octets]      control data (JSON)
    [0...65535 octets]      metadata (JSON)
    [0...4294967295 octets] data (binary)

### Control Data Section

TODO

    standard control data fields:
        cmd
        msgid
        in-reply-to
        more-coming

### Metadata Section

TODO

### Data Section

TODO

### Message Ids

TODO

### Message Flow

TODO
    
    client sends first 'hello'
    server sends 'hello.response'

### Standard Messages

TODO

    standard cmd types:
        hello
        hello.response
        echo
        echo.response
        ping
        ping.response

## Shanty Design Decisions

TODO No versioning
TODO No compression.
TODO No security.

## What about security?

TODO

## So why not use \[other technology here\]?

### HTTP

TODO

### SPDY

TODO

### WebSockets

TODO

### BEEP

TODO

## What's with the name?

## TODO

> We're going away to leave you now
> Hoorah, me boys, we're homeward bound
