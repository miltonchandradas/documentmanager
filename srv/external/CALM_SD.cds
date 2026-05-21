/* checksum : f86c7eb409eb66707677a86c821fd083 */
/**
 * Allows to create, read, query and delete documents with their related entities.
 * 
 * The Documents OData API enables you to manage documents and their related entities in SAP Cloud ALM.<p> You require the following authorization scopes to access the API: <ul> <li>calm-api.documents.read: to read document entities.</li> <li>calm-api.documents.write: to write document entities.</li> <li>calm-api.documents.delete: to delete document entities.</li> </ul>
 */
@cds.external : true
@Common.Label : 'SAP Cloud ALM Documents'
@Capabilities.BatchSupported : false
@Capabilities.KeyAsSegmentSupported : true
@Authorization.SecuritySchemes : [ { $Type: 'Authorization.SecurityScheme', Authorization: 'OAuth2' } ]
@Authorization.Authorizations : [
  {
    $Type: 'Authorization.OAuth2ClientCredentials',
    Name: 'OAuth2',
    Description: 'Authentication via OAuth2 with client credentials flow',
    TokenUrl: 'https://{identityzone}.authentication.{region}.hana.ondemand.com/oauth/token',
    Scopes: [
      {
        $Type: 'Authorization.AuthorizationScope',
        Scope: 'calm-api.documents.read',
        Description: 'Read access to documents'
      },
      {
        $Type: 'Authorization.AuthorizationScope',
        Scope: 'calm-api.documents.write',
        Description: 'Write access to documents'
      },
      {
        $Type: 'Authorization.AuthorizationScope',
        Scope: 'calm-api.documents.delete',
        Description: 'Delete access to documents'
      }
    ]
  }
]
service CALM_SD {
  /**
   * Action to assign and unassign tags in a document
   * 
   * Already assigned tags remain unchanged, new tags will be assigned. Assigned tags which are not given by the action will be unassigned.
   */
  @cds.external : true
  @Common.Label : 'Document Headers'
  action updateTags(
    /** UUID of document */
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: '22222222-2222-2222-2222-222222222222'
    }
    documentUUID : LargeString not null,
    /** Array of tag labels */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Tag Label 1' }
    tags : many LargeString
  ) returns api_v1_TagsAssigned;

  /**
   * Main entity for Documents including html content
   * 
   * Main entity for Documents including html content
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Headers'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of documents with its content and other properties. You can use $expand query parameter to read child entities like url references and assigned solution processes.'
  @Capabilities.UpdateRestrictions.Updatable : true
  @Capabilities.UpdateRestrictions.LongDescription : 'Update an existing document is supported only for attribute ''fileContent'' via PUT request.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a document by its UUID. This is a cascading delete operation which will also delete all child entities like url references and assignments to solution processes or process hierarchy nodes.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new document with its content and other properties. You can also use deep create to assign url references and assignments to solution processes or process hierarchy nodes to the document in one single HTTP request.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data, e.g. missing required properties like title or projectId.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  entity Documents {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    /** ID of the document */
    @Core.Computed : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: '7-19' }
    @Common.Label : '{i18n>Documents.ID}'
    displayId : String(40);
    @Core.Immutable : true
    @Common.Label : '{i18n>Documents.Title}'
    @Common.FieldControl : #Mandatory
    title : String(255);
    /** Html rich-text content of the document */
    @Core.Immutable : true
    @Common.TextFormat : #html
    @Common.Label : '{i18n>Documents.Content}'
    content : LargeString;
    /** UUID of assigned project */
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: '11111111-1111-1111-1111-111111111111'
    }
    @Core.Immutable : true
    @Common.FieldControl : #Mandatory
    projectId : UUID;
    /** UUID of directly assigned scope */
    @Core.Immutable : true
    scopeId : UUID;
    @Core.Immutable : true
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InProgress',
        Value: 10
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InReview',
        Value: 20
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Released',
        Value: 30
      }
    ]
    statusCode : Integer default 10;
    @Core.Immutable : true
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'VeryHigh',
        Value: 10
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'High',
        Value: 20
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Medium',
        Value: 30
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Low',
        Value: 40
      }
    ]
    priorityCode : Integer default 30;
    @Core.Immutable : true
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ManuallyCreated',
        Value: 'MANUAL'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'External',
        Value: 'EXTERNAL'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'SapSolutionManager',
        Value: 'SAPSOLMAN'
      }
    ]
    sourceCode : String(10) default 'MANUAL';
    @Core.Immutable : true
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'NotAssigned',
        Value: 'NA'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ProjectDocumentation',
        Value: 'PJ'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'BusinessProcessDocument',
        Value: 'BP'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'SolutionDesignDocument',
        Value: 'SD'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'FunctionalSpecification',
        Value: 'FU'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TechnicalDesignDocument',
        Value: 'TD'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ConfigurationGuide',
        Value: 'CG'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InterfaceSpecification',
        Value: 'IS'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TestDocument',
        Value: 'TE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'EndUserDocumentation',
        Value: 'EU'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TrainingDocumentation',
        Value: 'TR'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'FactSheet',
        Value: 'FS'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Note',
        Value: 'NT'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'JobDocumentation',
        Value: 'JD'
      }
    ]
    documentTypeCode : String(40) default 'NA';
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @Core.Computed : true
    @Core.Immutable : true
    @UI.DateTimeStyle : 'short'
    @UI.ExcludeFromNavigationContext : true
    @Common.Label : '{i18n>CreatedAt}'
    createdAt : Timestamp;
    @odata.Precision : 7
    @odata.Type : 'Edm.DateTimeOffset'
    @Core.Computed : true
    @UI.DateTimeStyle : 'short'
    @UI.ExcludeFromNavigationContext : true
    @Common.Label : '{i18n>ChangedAt}'
    modifiedAt : Timestamp;
    @Core.Computed : true
    tags : many LargeString;
    @Common.FilterDefaultValue : false
    @Common.Label : '{i18n>Documents.IsTemplate}'
    isTemplate : Boolean default false;
    /**
     * Document owner identifier
     * 
     * Unique identifier of the user who owns the document
     */
    @PersonalData.FieldSemantics : 'DataSubjectID'
    @PersonalData.IsPotentiallyPersonal : true
    @Core.Immutable : true
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: '5a56d1e9-35a7-4b59-85b4-1f7f7dcb1d71'
    }
    @Common.Label : '{i18n>Documents.Owner}'
    ownerId : String(255);
    /**
     * Document responsible person identifier
     * 
     * Unique identifier of the user who is responsible for the document
     */
    @Core.Immutable : true
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: '1271804d-ec16-4a05-affe-e18d12a86038'
    }
    @PersonalData.FieldSemantics : 'DataSubjectID'
    @PersonalData.IsPotentiallyPersonal : true
    @Common.Label : '{i18n>Documents.Responsible}'
    responsibleId : String(255);
    /**
     * Document state code
     * 
     * Code representing the current state of the document
     */
    @Core.Immutable : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'ACT' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACT'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'MarkedForDeletion',
        Value: 'MDL'
      }
    ]
    stateCode : String(10) default 'ACT';
    /**
     * Document approval code
     * 
     * Code representing the current approval status of the document
     */
    @Core.Immutable : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'NO_APPR_REQ' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'NoApprovalRequired',
        Value: 'NO_APPR_REQ'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ApprovalRequired',
        Value: 'APPR_REQUIRED'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ApprovalPending',
        Value: 'APPR_PENDING'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Approved',
        Value: 'APPROVED'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Rejected',
        Value: 'REJECTED'
      }
    ]
    approvalCode : String(20) default 'NO_APPR_REQ';
    /** Binary content of the external document file for upload, download and replace operations */
    @Core.MediaType : fileType
    @odata.Type : 'Edm.Stream'
    @Core.ContentDisposition : {
      $Type: 'Core.ContentDispositionType',
      Type: 'attachment',
      Filename: fileName
    }
    @Core.Computed : true
    fileContent : LargeBinary;
    toStatus : Association to one DocumentStatus {  };
    toPriority : Association to one DocumentPriorities {  };
    toSource : Association to one DocumentSources {  };
    toDocumentType : Association to one DocumentTypes {  };
    @Common.Label : '{i18n>Documents.References}'
    toURLReferences : Composition of many URLReferences {  };
    toSolutionProcessAssignments : Composition of many SolutionProcessAssignments {  };
    toProcessHierarchyAssignments : Composition of many ProcessHierarchyAssignments {  };
    toTaskAssignments : Composition of many TaskAssignments {  };
    toLibraryAssignments : Composition of many LibraryAssignments {  };
    toTestCaseAssignments : Composition of many TestCaseAssignments {  };
    toExternalFiles : Composition of many ExternalFiles {  };
    toExternalReferences : Composition of many ExternalReferences {  };
    toState : Association to one DocumentStates {  };
    toApproval : Association to one DocumentApprovalStates {  };
    /** Document version number starting with 1. Is incremented with every new version. */
    @Core.Computed : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 1 }
    @Common.Label : '{i18n>Documents.Version}'
    version : Integer default 1;
    /** Indicates if the document is the latest version. Only the latest version can be modified. */
    @Core.Computed : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: true }
    @Common.FilterDefaultValue : true
    @Common.Label : '{i18n>Documents.LatestVersion}'
    isLatest : Boolean default true;
  };

  /**
   * Document references (links) with URL and display name
   * 
   * Document references (links) with URL and display name
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'URL References'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all URL references assigned to one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete an URL reference by its UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new URL reference with a target URL and display name for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity URLReferences {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** Display name of the reference */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'SAP' }
    @Common.Label : '{i18n>References.Name}'
    @Common.FieldControl : #Mandatory
    name : String(255) not null;
    /** Target URL of the reference starting with http:// or https:// */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'https://www.sap.com' }
    @Common.Label : '{i18n>References.Url}'
    @Common.FieldControl : #Mandatory
    url : String(1000) not null;
  };

  /**
   * Solution processes assigned to documents
   * 
   * Solution processes assigned to documents
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Solution Process Assignments'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all assigned assigned solution processes of one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a solution process assignment by its assignment UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new solution process assignment for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity SolutionProcessAssignments {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'SP_BKP_1' }
    @Common.Label : '{i18n>CrossDomainAssignments.Title}'
    @Common.FieldControl : #Mandatory
    solutionProcessId : LargeString;
    /** UUID of scope */
    @Common.Label : '{i18n>CrossDomainAssignments.Scope}'
    @Common.FieldControl : #Mandatory
    scopeId : UUID;
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'EARL_SolS-013' }
    @Common.FieldControl : #Mandatory
    solutionScenarioId : LargeString;
  };

  /**
   * Process hierarchy nodes assigned to documents
   * 
   * Process hierarchy nodes assigned to documents
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Process Hierarchy Node Assignments'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all assigned process hierarchy nodes of one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a process hierarchy node assignment by its assignment UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new process hierarchy node assignment for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity ProcessHierarchyAssignments {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** ID of the process hierarchy node */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: '14-2' }
    @Common.Label : '{i18n>CrossDomainAssignments.DisplayId}'
    @Common.FieldControl : #Mandatory
    displayId : LargeString;
  };

  /**
   * Tasks assigned to documents
   * 
   * Tasks assigned to documents, including requirements, defects, tasks and quality gates.
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Task Assignments'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all assigned tasks of one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a task assignment by its assignment UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new task assignment for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity TaskAssignments {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** Task identifier (uuid) */
    @Common.Label : '{i18n>CrossDomainAssignments.Title}'
    @Common.FieldControl : #Mandatory
    id : LargeString;
    /** Task type, i.e. CALMTASK (Task), CALMUS (User Story), CALMTMPL (Roadmap Task), CALMQGATE (Qaulity Gate), CALMREQU (Requirement), CALMDEF (Defect) */
    @Core.Computed : true
    type : LargeString;
  };

  /**
   * Library elements assigned to documents
   * 
   * Library elements assigned to documents, including Application, Configuration, Development and Interface
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Library Assignments'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all assigned library elements of one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a library element assignment by its assignment UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new library element assignment for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity LibraryAssignments {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** Library element identifier (uuid) */
    @Common.Label : '{i18n>CrossDomainAssignments.Title}'
    @Common.FieldControl : #Mandatory
    libraryUuid : UUID;
    /** Library type, i.e. Application, Configuration, Interface, Development */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Application' }
    @Core.Computed : true
    libraryType : LargeString;
  };

  /**
   * Test cases assigned to documents
   * 
   * Test cases assigned to documents
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Test Case Assignments'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all assigned test cases of one document.'
  @Capabilities.DeleteRestrictions.LongDescription : 'Delete a test case assignment by its assignment UUID.'
  @Capabilities.InsertRestrictions.LongDescription : 'Create a new test case assignment for one document.'
  @Capabilities.InsertRestrictions.ErrorResponses : [
    {
      StatusCode: '4XX',
      Description: 'Bad Request - Invalid input data or document does not allow changes in its current state.'
    }
  ]
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.UpdateRestrictions.Updatable : false
  entity TestCaseAssignments {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** Test case identifier (uuid) */
    @Common.Label : '{i18n>CrossDomainAssignments.Title}'
    @Common.FieldControl : #Mandatory
    testCaseUuid : UUID;
    /** Test case type, i.e. Manual or Automated */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'ManualTestCaseDef' }
    @Core.Computed : true
    testCaseType : LargeString;
  };

  /**
   * Document status values
   * 
   * Document status values
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Status'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.ReadByKeyRestrictions.Readable : false
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all defined document status values'
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity DocumentStatus {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 10 }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InProgress',
        Value: 10
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InReview',
        Value: 20
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Released',
        Value: 30
      }
    ]
    key code : Integer not null default 10;
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'In Progress' }
    @Common.Label : '{i18n>Documents.Status}'
    name : String(255);
  };

  /**
   * Document priority values
   * 
   * Document priority values
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Priorities'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.ReadByKeyRestrictions.Readable : false
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all defined document priority values'
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity DocumentPriorities {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 30 }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'VeryHigh',
        Value: 10
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'High',
        Value: 20
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Medium',
        Value: 30
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Low',
        Value: 40
      }
    ]
    key code : Integer not null default 30;
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Medium' }
    @Common.Label : '{i18n>Documents.Priority}'
    name : String(255);
  };

  /**
   * Document type values
   * 
   * Document type values
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Types'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.ReadByKeyRestrictions.Readable : false
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all defined documents types'
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity DocumentTypes {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'SD' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'NotAssigned',
        Value: 'NA'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ProjectDocumentation',
        Value: 'PJ'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'BusinessProcessDocument',
        Value: 'BP'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'SolutionDesignDocument',
        Value: 'SD'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'FunctionalSpecification',
        Value: 'FU'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TechnicalDesignDocument',
        Value: 'TD'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ConfigurationGuide',
        Value: 'CG'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'InterfaceSpecification',
        Value: 'IS'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TestDocument',
        Value: 'TE'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'EndUserDocumentation',
        Value: 'EU'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'TrainingDocumentation',
        Value: 'TR'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'FactSheet',
        Value: 'FS'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Note',
        Value: 'NT'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'JobDocumentation',
        Value: 'JD'
      }
    ]
    key code : String(40) not null default 'NA';
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: 'Solution Design Document'
    }
    @Common.Label : '{i18n>Documents.DocumentType}'
    name : String(255);
  };

  /**
   * Document source values
   * 
   * Document source values
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Sources'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.ReadByKeyRestrictions.Readable : false
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all defined documents sources'
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity DocumentSources {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'MANUAL' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ManuallyCreated',
        Value: 'MANUAL'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'External',
        Value: 'EXTERNAL'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'SapSolutionManager',
        Value: 'SAPSOLMAN'
      }
    ]
    key code : String(10) not null default 'MANUAL';
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Manually Created' }
    @Common.Label : '{i18n>Documents.Source}'
    name : String(255);
  };

  /**
   * External files linked to documents
   * 
   * External files linked to documents
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document External Files'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all external files linked to one document.'
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: createdAt, AllowedExpressions: 'SingleRange' },
    { Property: modifiedAt, AllowedExpressions: 'SingleRange' }
  ]
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity ExternalFiles {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** File name of the external document file */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Document.pdf' }
    fileName : LargeString;
    /** MIME type of the external document file */
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'application/pdf' }
    @Core.IsMediaType : true
    fileType : LargeString;
    /** Size of the external document file in bytes */
    @Core.Computed : true
    fileSize : Integer;
    /** Version of the external document file in SAP BTP DMS with major and minor numbers. Each file replacement will increase the major version number by 1. */
    @Core.Computed : true
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: '1.0' }
    @Common.Label : '{i18n>ExternalFile.Version}'
    fileVersion : LargeString;
  };

  /**
   * SAP BTP DMS configuration
   * 
   * SAP BTP DMS configuration
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'SAP BTP DMS Configuration'
  @odata.singleton : true
  @Capabilities.ReadRestrictions.Description : 'Retrieves the SAP BTP DMS configuration'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve the SAP BTP DMS configuration including destination availability and repository ID.'
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  entity DmsConfig {
    /** Indicates whether the BTP destination to SAP BTP DMS is available and properly configured */
    destinationAvailable : Boolean default false;
    /** SAP BTP DMS repository ID where the external files are stored */
    @Core.Example : {
      $Type: 'Core.PrimitiveExampleValue',
      Value: '01234567-89ab-cdef-0123-456789abcdef'
    }
    repositoryId : LargeString;
  };

  /**
   * External reference identifiers for documents
   * 
   * External reference identifiers for documents
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'External References'
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all external reference identifiers for one document.'
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  entity ExternalReferences {
    @Core.Computed : true
    @Core.ComputedDefaultValue : true
    key uuid : UUID not null;
    parent : Association to one Documents {  };
    parent_uuid : UUID;
    /** External reference identifier, e.g. UUID from external system */
    @Common.Label : '{i18n>UI.LineItem.ExternalReferenceId}'
    externalReferenceId : String(255) not null;
    /** Name of the external reference, e.g. &quot;SAP Solution Manager&quot; for selective data transfer use-case */
    @Common.Label : '{i18n>UI.LineItem.ExternalReferenceName}'
    name : String(255) not null;
    /** URL of the external reference pointing to the external system */
    @Common.Label : '{i18n>UI.LineItem.ExternalReferenceUrl}'
    url : String(1000);
  };

  /**
   * Document approval states
   * 
   * Document approval states
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document Approval States'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all document approval states.'
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  entity DocumentApprovalStates {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'NO_APPR_REQ' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'NoApprovalRequired',
        Value: 'NO_APPR_REQ'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ApprovalRequired',
        Value: 'APPR_REQUIRED'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'ApprovalPending',
        Value: 'APPR_PENDING'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Approved',
        Value: 'APPROVED'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Rejected',
        Value: 'REJECTED'
      }
    ]
    key code : String(20) not null default 'NO_APPR_REQ';
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'No Approval required' }
    @Common.Label : '{i18n>Documents.Approval}'
    name : String(255);
  };

  /**
   * Document states
   * 
   * Document states
   */
  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Document States'
  @UI.Identification : [ { $Type: 'UI.DataField', Value: name } ]
  @Capabilities.ReadRestrictions.LongDescription : 'Retrieve a list of all document states.'
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  entity DocumentStates {
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'ACT' }
    @Validation.AllowedValues : [
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'Active',
        Value: 'ACT'
      },
      {
        $Type: 'Validation.AllowedValue',
        @Core.SymbolicName: 'MarkedForDeletion',
        Value: 'MDL'
      }
    ]
    key code : String(10) not null default 'ACT';
    @Core.Example : { $Type: 'Core.PrimitiveExampleValue', Value: 'Active' }
    @Common.Label : '{i18n>Documents.State}'
    name : String(255);
  };

  @cds.external : true
  type api_v1_TagsAssigned {
    tags : many LargeString;
  };
};

