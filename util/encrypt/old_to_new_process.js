const db_dock = require("../../db/pgPool");
const db_old = require("../../db/pgPool_old");
const { encryptString, decryptString } = require("./enc_denc");
const { encrypt_string, decrypt_string } = require("./decrypt");

const update_creds = async () => {
  let old_creds = await db_old.any(
    "SELECT * FROM hhm_credentials ORDER BY id ASC"
  );

  /* let new_creds = await db_dock.any(
    "SELECT * FROM hhm_credentials ORDER BY id ASC"
  ); */

  const credentials = {
    old: [],
    new: [],
    new_dec: [],
  };

  for (let cred of old_creds) {
    let user_enc = cred.user_enc;
    let password_enc = cred.password_enc;

    let user = decryptString(user_enc);
    let password = decryptString(password_enc);

    const creds_dec = {
      id: cred.id,
      user,
      password,
    };

    credentials.old.push(creds_dec);
  }

  console.log("\ncredentials.old");
  console.log(credentials.old);

  for (let cred of credentials.old) {
    let user = encrypt_string(cred.user);
    let password = encrypt_string(cred.password);

    const creds_enc = {
      id: cred.id,
      user,
      password,
    };

    credentials.new.push(creds_enc);
  }

  for await (let cred of credentials.new) {
    await db_dock.any("UPDATE hhm_credentials SET user_enc = $1, password_enc = $2 WHERE id = $3", [cred.user, cred.password, cred.id])
  }
};

module.exports = update_creds;

/* 
{
    id: 24,
    user_num: '1',
    pass_num: '1',
    manufacturer: 'avante',
    modality: 'mmb',
    user_enc: '71c3549a9139e73ea21ed4e32ff482e3',
    password_enc: '9430765b9a651638e6d2e309bdf703c7'
  }
*/
