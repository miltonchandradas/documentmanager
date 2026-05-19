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

module.exports = async (srv) => {

    srv.on('createFolder', async (req) => {
        const { folderName } = req.data;

        if (!folderName) {
            return req.error(400, 'Folder name is required');
        }

        try {
            const credentials = getSDMCredentials();
            const token = await getOAuthToken(credentials);
            const baseUrl = credentials.endpoints?.ecmservice?.url || credentials.uri;

            // Create folder in SAP Document Management via CMIS Browser Binding
            const response = await fetch(`${baseUrl}/browser/root`, {
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
            const cmisId = result.succinctProperties?.['cmis:objectId'];

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
            const baseUrl = credentials.endpoints?.ecmservice?.url || credentials.uri;

            // Delete folder in SAP Document Management via CMIS Browser Binding
            const response = await fetch(`${baseUrl}/browser/root`, {
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
};
