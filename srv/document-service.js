const cds = require('@sap/cds');

function getSDMCredentials() {
    const vcap = JSON.parse(process.env.VCAP_SERVICES || '{}');
    const sdmBindings = vcap['sdm'] || vcap['dms-integration'] || [];
    const binding = sdmBindings[0];
    if (!binding) throw new Error('No dms-integration service binding found in VCAP_SERVICES');
    return binding.credentials;
}

async function getOAuthToken(credentials) {
    const tokenUrl = `${credentials.uaa.url}/oauth/token`;
    const response = await fetch(tokenUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'client_credentials',
            client_id: credentials.uaa.clientid,
            client_secret: credentials.uaa.clientsecret
        })
    });
    if (!response.ok) {
        throw new Error(`OAuth token request failed: ${response.status} ${await response.text()}`);
    }
    const data = await response.json();
    return data.access_token;
}

async function getRepositoryId(baseUrl, token) {
    const url = `${baseUrl}/browser`;
    console.log('Fetching repositories from:', url);
    const response = await fetch(url, {
        headers: { 'Authorization': `Bearer ${token}` }
    });
    if (!response.ok) {
        throw new Error(`Failed to get repositories: ${response.status} ${await response.text()}`);
    }
    const repos = await response.json();
    console.log('Repositories response:', JSON.stringify(repos));
    // Get the first repository ID
    const repoIds = Object.keys(repos);
    if (repoIds.length === 0) {
        throw new Error('No repositories found in Document Management Service. Please onboard a repository via the SDM admin UI.');
    }
    console.log('Available repositories:', repoIds);
    return repoIds[0];
}

module.exports = async (srv) => {

    srv.on('listRepositories', async (req) => {
        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');

            const response = await fetch(`${baseUrl}/browser`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            const repos = await response.json();
            const repositories = Object.entries(repos).map(([id, details]) => ({
                repositoryId: id,
                name: details.repositoryName || details.productName,
                description: details.repositoryDescription || '',
                rootFolderId: details.rootFolderId
            }));

            console.log('Repositories:', JSON.stringify(repositories, null, 2));

            return JSON.stringify(repositories);
        } catch (err) {
            console.error('Error listing repositories:', err.message || err);
            return req.error(500, `Failed to list repositories: ${err.message || 'Unknown error'}`);
        }
    });

    srv.on('createFolder', async (req) => {
        const { repositoryId, folderName } = req.data;

        if (!repositoryId) {
            return req.error(400, 'Repository ID is required');
        }
        if (!folderName) {
            return req.error(400, 'Folder name is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');

            // Create folder in SAP Document Management via CMIS Browser Binding
            const response = await fetch(`${baseUrl}/browser/${repositoryId}/root`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Authorization': `Bearer ${token}`
                },
                body: new URLSearchParams({
                    'cmisaction': 'createFolder',
                    'propertyId[0]': 'cmis:name',
                    'propertyValue[0]': folderName,
                    'propertyId[1]': 'cmis:objectTypeId',
                    'propertyValue[1]': 'cmis:folder'
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            const result = await response.json();
            const cmisId = result.succinctProperties?.['cmis:objectId']
                || result.properties?.['cmis:objectId']?.value;

            // Log folder metadata
            console.log('Folder created:', { folderName, cmisId, result });

            return { folderName, cmisId };
        } catch (err) {
            console.error('Error creating folder:', err.message || err);
            return req.error(500, `Failed to create folder: ${err.message || 'Unknown error'}`);
        }
    });

    srv.on('deleteFolder', async (req) => {
        const { cmisId } = req.data;

        if (!cmisId) {
            return req.error(400, 'cmisId is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');
            const repoId = await getRepositoryId(baseUrl, token);

            // Delete folder in SAP Document Management via CMIS Browser Binding
            const response = await fetch(`${baseUrl}/browser/${repoId}/root`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Authorization': `Bearer ${token}`
                },
                body: new URLSearchParams({
                    'cmisaction': 'delete',
                    'objectId': cmisId,
                    'allVersions': 'true'
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            console.log('Folder deleted:', { cmisId });

            return `Folder with cmisId '${cmisId}' deleted successfully`;
        } catch (err) {
            console.error('Error deleting folder:', err.message || err);
            return req.error(500, `Failed to delete folder: ${err.message || 'Unknown error'}`);
        }
    });

    srv.on('onboardRepository', async (req) => {
        const { repoName, repoDescription } = req.data;

        if (!repoName) {
            return req.error(400, 'Repository name is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');

            const response = await fetch(`${baseUrl}/rest/v2/repositories`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    repository: {
                        displayName: repoName,
                        description: repoDescription || repoName,
                        repositoryType: 'internal',
                        isVirusScanEnabled: true,
                        skipVirusScanForLargeFile: false,
                        hashAlgorithms: 'SHA-256',
                        isVersionEnabled: true,
                        isThumbnailEnabled: false,
                        isEncryptionEnabled: false
                    }
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            const result = await response.json();
            console.log('Repository onboarded:', JSON.stringify(result));

            return `Repository '${repoName}' onboarded successfully`;
        } catch (err) {
            console.error('Error onboarding repository:', err.message || err);
            return req.error(500, `Failed to onboard repository: ${err.message || 'Unknown error'}`);
        }
    });

    srv.on('deleteRepository', async (req) => {
        const { repositoryId } = req.data;

        if (!repositoryId) {
            return req.error(400, 'Repository ID is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');

            const response = await fetch(`${baseUrl}/rest/v2/repositories/${repositoryId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            console.log('Repository deleted:', { repositoryId });

            return `Repository '${repositoryId}' deleted successfully`;
        } catch (err) {
            console.error('Error deleting repository:', err.message || err);
            return req.error(500, `Failed to delete repository: ${err.message || 'Unknown error'}`);
        }
    });

    srv.on('listFolders', async (req) => {
        const { repositoryId } = req.data;

        if (!repositoryId) {
            return req.error(400, 'Repository ID is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = (credentials.endpoints?.ecmservice?.url || credentials.uri).replace(/\/+$/, '');

            // Get children of root folder
            const response = await fetch(`${baseUrl}/browser/${repositoryId}/root?cmisselector=children`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`SDM API error ${response.status}: ${errText}`);
            }

            const result = await response.json();
            const folders = (result.objects || []).map(obj => {
                const props = obj.object?.properties || {};
                return {
                    cmisId: props['cmis:objectId']?.value,
                    name: props['cmis:name']?.value,
                    type: props['cmis:baseTypeId']?.value,
                    createdBy: props['cmis:createdBy']?.value,
                    createdAt: props['cmis:creationDate']?.value
                };
            });

            console.log('Folders in repository:', JSON.stringify(folders, null, 2));

            return JSON.stringify(folders);
        } catch (err) {
            console.error('Error listing folders:', err.message || err);
            return req.error(500, `Failed to list folders: ${err.message || 'Unknown error'}`);
        }
    });

    // ─── Cloud ALM Document Creation via BTP Destination ─────────────────────────

    srv.on('createCloudALMDocument', async (req) => {
        const { projectUUID, title, documentTypeCode, statusCode } = req.data;

        if (!projectUUID) return req.error(400, 'projectUUID is required');
        if (!title) return req.error(400, 'title is required');

        const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');
        const { getDestination } = require('@sap-cloud-sdk/connectivity');
        const axios = require('axios');

        const DEST = { destinationName: 'CALM_API' };
        const SERVICE_PATH = '/ui/imp-sd-docu-srv/v1/odata/v4/DocumentService';

        try {
            // Resolve destination and extract token for fallback
            const resolved = await getDestination({ destinationName: 'CALM_API' });
            const baseUrl = resolved.url;
            const token = resolved?.authTokens?.find(t => t.value)?.value;
            if (!token) {
                throw new Error('No auth token obtained from destination. Check CALM_API destination credentials.');
            }
            console.log('Cloud ALM: Token obtained, scopes:', JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString()).scope);

            // Step 1: Fetch CSRF token (try SDK first, fallback to axios)
            console.log('Cloud ALM: Fetching CSRF token...');
            let csrfToken;
            let cookies;
            try {
                const csrfResponse = await executeHttpRequest(DEST, {
                    method: 'get',
                    url: SERVICE_PATH,
                    headers: { 'x-csrf-token': 'fetch' }
                });
                csrfToken = csrfResponse.headers['x-csrf-token'];
                cookies = csrfResponse.headers['set-cookie'];
                console.log('Cloud ALM: CSRF token obtained via SDK');
            } catch (sdkErr) {
                console.log('Cloud ALM: SDK failed (' + (sdkErr.response?.status || sdkErr.message) + '), trying axios fallback...');
                const csrfResponse = await axios.get(`${baseUrl}${SERVICE_PATH}`, {
                    headers: {
                        'x-csrf-token': 'fetch',
                        'Authorization': `Bearer ${token}`
                    }
                });
                csrfToken = csrfResponse.headers['x-csrf-token'];
                cookies = csrfResponse.headers['set-cookie'];
                console.log('Cloud ALM: CSRF token obtained via axios fallback');
            }

            if (!csrfToken) {
                throw new Error('No x-csrf-token header in response');
            }

            // Helper: try SDK first, fallback to axios
            const calmRequest = async (method, path, data) => {
                try {
                    return await executeHttpRequest(DEST, {
                        method,
                        url: `${SERVICE_PATH}${path}`,
                        headers: {
                            'Content-Type': 'application/json',
                            'x-csrf-token': csrfToken
                        },
                        data
                    }, { fetchCsrfToken: false });
                } catch (sdkErr) {
                    console.log(`Cloud ALM: SDK failed for ${method.toUpperCase()} ${path}, using axios fallback`);
                    return axios({
                        method,
                        url: `${baseUrl}${SERVICE_PATH}${path}`,
                        headers: {
                            'Content-Type': 'application/json',
                            'x-csrf-token': csrfToken,
                            'Authorization': `Bearer ${token}`,
                            ...(cookies ? { 'Cookie': cookies.join('; ') } : {})
                        },
                        data
                    });
                }
            };

            // Step 2: Create document draft
            console.log('Cloud ALM: Creating document draft...');
            const createResponse = await calmRequest('post', '/Documents', {
                projectUUID: projectUUID,
                isTemplate: false,
                iconUrl: 'sap-icon://document'
            });

            const draft = createResponse.data;
            const documentUUID = draft.uuid;
            console.log('Cloud ALM: Draft created, uuid:', documentUUID);

            // Step 3: Patch required metadata
            const patchBody = { title };
            if (documentTypeCode) patchBody.documentType_code = documentTypeCode;
            if (statusCode) patchBody.status_code = statusCode;

            console.log('Cloud ALM: Patching document metadata...');
            await calmRequest('patch', `/Documents(uuid=${documentUUID},IsActiveEntity=false)`, patchBody);
            console.log('Cloud ALM: Metadata patched');

            // Step 4: draftPrepare
            console.log('Cloud ALM: Preparing draft...');
            await calmRequest('post', `/Documents(uuid=${documentUUID},IsActiveEntity=false)/DocumentService.draftPrepare`, { SideEffectsQualifier: '' });
            console.log('Cloud ALM: Draft prepared');

            // Step 5: draftActivate
            console.log('Cloud ALM: Activating draft...');
            const activateResponse = await calmRequest('post', `/Documents(uuid=${documentUUID},IsActiveEntity=false)/DocumentService.draftActivate`, {});
            console.log('Cloud ALM: Document activated');

            const result = {
                uuid: documentUUID,
                title: title,
                IsActiveEntity: true,
                activateResponse: activateResponse.data
            };

            return JSON.stringify(result);
        } catch (err) {
            console.error('Error creating Cloud ALM document:', err.message || err);
            const detail = err.response?.data || err.message || 'Unknown error';
            return req.error(500, `Failed to create Cloud ALM document: ${JSON.stringify(detail)}`);
        }
    });
};
