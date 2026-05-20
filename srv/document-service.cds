using {documentmanager as dm} from '../db/schema';

service DocumentService {
    entity Folders as projection on dm.Folders;

    action uploadFunctionalDocument(fileName: String, mimeType: String, content: LargeBinary) returns String;
    action onboardRepository(repoName: String, repoDescription: String)                       returns String;
    action listRepositories()                                                                 returns String;
    action deleteRepository(repositoryId: String)                                             returns String;
    action createFolder(repositoryId: String, folderName: String)                             returns Folders;
    action listFolders(repositoryId: String)                                                  returns String;
    action deleteFolder(cmisId: String)                                                       returns String;
}
