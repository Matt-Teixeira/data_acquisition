const crypto = require("crypto");

const algorithm = "aes-256-cbc";

// Key must be 32 bytes for aes-256-cbc
const key = crypto.createHash("sha256").update("your-encryption-key").digest();

// IV must be 16 bytes
const iv = crypto.randomBytes(16);

function encryptString(text) {
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  const encrypted = Buffer.concat([cipher.update(text, "utf8"), cipher.final()]);
  // Store IV alongside ciphertext so you can decrypt later
  return iv.toString("hex") + ":" + encrypted.toString("hex");
}

function decryptString(encryptedText) {
  const [ivHex, encryptedHex] = encryptedText.split(":");
  const iv = Buffer.from(ivHex, "hex");
  const encrypted = Buffer.from(encryptedHex, "hex");

  const decipher = crypto.createDecipheriv(algorithm, key, iv);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return decrypted.toString("utf8");
}

// let data = decryptString('18fd25d7d4ec9fb0dd6a17564f10f184');

let data = encryptString('Manager');

console.log(data);

module.exports = { encryptString, decryptString };
