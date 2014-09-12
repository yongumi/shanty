### shanty.sys.hello

#### Message

    cmd: shanty.sys.hello
    created: <timestamp>
    msgid: 1
    ---
    host:
    peer:
    name:
    peerAddress:
    ---
    <no data>

#### Reply

    created: <timestamp>
    msgid: 1
    in-reply-to: 1
    
    ---
    host:
    peer:
    name:
    peerAddress:
    ---
    <no data>

### shanty.sys.challenge-response

#### Message

    cmd: shanty.sys.challenge-response
    created: <timestamp>
    msgid: 2
    ---
    secret: 12345
    ---
    <no data>

#### Reply

    created: <timestamp>
    msgid: 2
    status: OK
    ---
    secret: 12345
    ---
    <no data>


shanty.error
shanty.ping

Each state has a list of allowed message types (incl. wildcard)


How to handle errors: put an isError method on STYMessage

Make all unknown messages return an error

Open questions:
* Do replies need own command type??? Should we tack on .reply or not bother?
