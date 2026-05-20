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
};
