namespace documentmanager;

entity Folders {
    key ID        : UUID;
        name      : String(255) @mandatory;
        parentId  : String;
        cmisId    : String(255); // Document Manager CMIS object ID
        createdAt : Timestamp   @cds.on.insert: $now;
        createdBy : String      @cds.on.insert: $user;
}
