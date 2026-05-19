service DocumentService {
    action uploadFunctionalDocument(fileName: String, mimeType: String, content: LargeBinary) returns String;
}
