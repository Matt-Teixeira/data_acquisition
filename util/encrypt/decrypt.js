// crypto-secure.js
const crypto = require("crypto");

// Use an AEAD mode for confidentiality + integrity
const ALGORITHM = "aes-256-gcm";
const SALT_BYTES = 16;        // for scrypt
const IV_BYTES = 12;          // recommended for GCM
const KEY_BYTES = 32;         // 256-bit key
const TAG_BYTES = 16;         // GCM default

// Pull your secret from the environment (DON'T hardcode in code)
const PASSPHRASE = process.env.APP_SECRET; // set this in your .env

function deriveKey(passphrase, salt) {
  if (!passphrase) {
    throw new Error("APP_SECRET is not set");
  }
  return crypto.scryptSync(passphrase, salt, KEY_BYTES);
}

/**
 * Encrypts a UTF-8 string and returns a base64 blob that concatenates:
 * [salt | iv | authTag | ciphertext]
 */
function encrypt_string(plaintext, passphrase = PASSPHRASE) {
  const salt = crypto.randomBytes(SALT_BYTES);
  const key = deriveKey(passphrase, salt);
  const iv = crypto.randomBytes(IV_BYTES);

  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return Buffer.concat([salt, iv, authTag, ciphertext]).toString("base64");
}

/**
 * Accepts the base64 blob from encryptString and returns the original UTF-8 string.
 */
function decrypt_string(encoded, passphrase = PASSPHRASE) {
  const data = Buffer.from(encoded, "base64");

  const salt = data.subarray(0, SALT_BYTES);
  const iv = data.subarray(SALT_BYTES, SALT_BYTES + IV_BYTES);
  const authTag = data.subarray(SALT_BYTES + IV_BYTES, SALT_BYTES + IV_BYTES + TAG_BYTES);
  const ciphertext = data.subarray(SALT_BYTES + IV_BYTES + TAG_BYTES);

  const key = deriveKey(passphrase, salt);
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return plaintext.toString("utf8");
}

module.exports = { encrypt_string, decrypt_string };
