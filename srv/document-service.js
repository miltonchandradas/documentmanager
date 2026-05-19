const cds = require('@sap/cds');

module.exports = async (srv) => {

    const { Folders } = srv.entities;

    srv.on('createFolder', async (req) => {
        const { folderName } = req.data;

        if (!folderName) {
            return req.error(400, 'Folder name is required');
        }

        // Get SDM service binding credentials
        const sdm = await cds.connect.to('dms-integration');

        // Create folder in SAP Document Management via CMIS Browser Binding
        const response = await sdm.send({
            method: 'POST',
            path: '/browser/root',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            data: new URLSearchParams({
                'cmisaction': 'createFolder',
                'propertyId[0]': 'cmis:name',
                'propertyValue[0]': folderName,
                'propertyId[1]': 'cmis:objectTypeId',
                'propertyValue[1]': 'cmis:folder'
            }).toString()
        });

        const cmisId = response.succinctProperties?.['cmis:objectId'];

        // Persist folder metadata
        const folder = await INSERT.into(Folders).entries({
            name: folderName,
            cmisId: cmisId
        });

        return await SELECT.one.from(Folders).where({ cmisId: cmisId });
    });
};
