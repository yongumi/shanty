Shanty V0.1

entire message is COBs encoding
all integers are variable length quantities

message
    header (8+ bytes):
        total length -- no - can infer this
        header length
        metadata length
        data length
        stream index
        message index
        part index
        part count
        flags (more coming)
        PRIORITY (probably)
    metadata:
    data:

################################################################################

Shanty V0.0


message
    header (8 bytes)
        control data size (2 bytes)
        metadata size (2 bytes)
        data size (4 bytes)
    control data
    metadata
    data
        
