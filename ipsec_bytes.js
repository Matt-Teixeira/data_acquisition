const axios = require("axios");
const https = require("https");
const fs = require("fs/promises");

async function git_it() {
  const url = `https://35.237.84.83:8000/api/status/ipsec`;
  const agent = new https.Agent({
    rejectUnauthorized: false
  });
  const pw = "BIhcHB8t4Q";
  const options = {
    httpsAgent: agent,
    headers: {
      Accept: "application/json",
      Authorization: "Basic " + Buffer.from("api:" + pw).toString("base64")
    }
  };

  try {
    const res = await axios.get(url, options);
    const ipsec_status = res?.data;

    const jsonString = JSON.stringify(ipsec_status, null, 2);

    await fs.writeFile("ipsec.json", jsonString);

    console.log("Data saved to output.json");
  } catch (error) {
    console.log(error);
  }
}
git_it();
