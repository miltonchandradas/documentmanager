using {documentmanager as dm} from '../db/schema';

service DocumentService {
    entity Folders as projection on dm.Folders;

    action uploadFunctionalDocument(fileName: String, mimeType: String, content: LargeBinary) returns String;
    action onboardRepository(repoName: String, repoDescription: String)                       returns String;
    action createFolder(folderName: String)                                                   returns Folders;
    action deleteFolder(cmisId: String)                                                       returns String;
}
