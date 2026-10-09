const db_dock = require("../../db/pgPool");
// pgPool_old (the Azure-era source) is gone from this flow: since the migration,
// the old-format ciphertext lives in the LOCAL database — read and write the same pool.
const { decryptString } = require("./enc_denc");
const { encrypt_string, decrypt_string } = require("./decrypt");

// Converts a legacy seed of hhm_credentials (enc_denc.js scheme) to the
// APP_SECRET scheme (decrypt.js), once per seed (server runbook 4.1.7).
// Prints counts only, never a credential. All updates run in one transaction
// and are proved before commit: every row must decrypt under APP_SECRET to
// the value it had under the legacy scheme, or nothing is written.
const update_creds = async () => {
  const old_creds = await db_dock.any(
    "SELECT id, user_enc, password_enc FROM hhm_credentials ORDER BY id ASC"
  );
  console.log(`rows read: ${old_creds.length}`);

  // Throws on the first row that is not a legacy value (e.g. already converted).
  const plain = old_creds.map((cred) => ({
    id: cred.id,
    user: decryptString(cred.user_enc),
    password: decryptString(cred.password_enc),
  }));
  console.log(`decrypted with the legacy scheme: ${plain.length}`);

  await db_dock.tx(async (t) => {
    let updated = 0;
    for (const cred of plain) {
      const res = await t.result(
        "UPDATE hhm_credentials SET user_enc = $1, password_enc = $2 WHERE id = $3",
        [encrypt_string(cred.user), encrypt_string(cred.password), cred.id]
      );
      updated += res.rowCount;
    }
    console.log(`rows updated: ${updated}`);

    const new_creds = await t.any(
      "SELECT id, user_enc, password_enc FROM hhm_credentials ORDER BY id ASC"
    );
    const by_id = new Map(plain.map((cred) => [cred.id, cred]));
    let round_trip_ok = 0;
    for (const cred of new_creds) {
      const was = by_id.get(cred.id);
      if (
        was &&
        decrypt_string(cred.user_enc) === was.user &&
        decrypt_string(cred.password_enc) === was.password
      ) {
        round_trip_ok += 1;
      }
    }
    if (updated !== plain.length || round_trip_ok !== plain.length) {
      throw new Error(
        `conversion check failed (updated ${updated}, round-trip ${round_trip_ok} of ${plain.length}); rolled back`
      );
    }
    console.log(`round-trip under APP_SECRET: ${round_trip_ok} of ${plain.length}; committing`);
  });
};

module.exports = update_creds;
