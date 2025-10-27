const fs = require('fs');
const pgp = require('pg-promise')();

const config = {
   host: process.env.PG_HOST,
   port: process.env.PG_PORT,
   database: process.env.PG_DB,
   user: process.env.PG_USER,
   password: process.env.PG_PW,
   ssl: {
      require: true,
      cert: fs.readFileSync(`./db/BaltimoreCyberTrustRoot.crt.pem`),
      rejectUnauthorized: true,
   },
};

const db = pgp(config);

module.exports = db;
