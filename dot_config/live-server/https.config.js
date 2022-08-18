const fs = require('fs');
const path = require('path');

function resolveHome(filepath) {
    if (filepath[0] === '~') {
        return path.join(process.env.HOME, filepath.slice(1));
    }
    return filepath;
}

const ssl_base_dir = resolveHome('~/workspace/personal/pogoda.lan.r35.net/ssl-lan.r35.net');
const ssl_cert = path.join(ssl_base_dir, 'k8s_bundle.pem')
const ssl_key = path.join(ssl_base_dir, 'wild.lan.r35.net.key')

module.exports = {
    cert: fs.readFileSync(ssl_cert),
    key: fs.readFileSync(ssl_key),
    passphrase: null,
};
