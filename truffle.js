module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8546,
            network_id: "*", // Match any network id,
            gas: 4600000
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};
