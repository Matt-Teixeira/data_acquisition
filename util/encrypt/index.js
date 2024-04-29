const crypto = require("crypto");
const algorithm = "aes-256-cbc";
const key = "your-encryption-key"; // Replace with your secure encryption key

function encryptString(text) {
  const cipher = crypto.createCipher(algorithm, key);
  let encrypted = cipher.update(text, "utf8", "hex");
  encrypted += cipher.final("hex");
  return encrypted;
}

function decryptString(encryptedText) {
  const decipher = crypto.createDecipher(algorithm, key);
  let decrypted = decipher.update(encryptedText, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}

/* let user = decryptString("10ee1736338ac090fb42ecbc060574c4");
let pass = decryptString("708be4af9aa45c87dceebabb80eb7b45");

// let user = encryptString("insite");
// let pass = encryptString("713704HMR4@mr");

console.log("USER: " + user);
console.log("PASS: " + pass); */

module.exports = { encryptString, decryptString };
