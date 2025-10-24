const fs = require("fs");
const path = require("path");

function loadDeployment(networkName) {
  // Prefer exact network file: deployments/<network>.json
  // Go up two levels from scripts/lib/ to project root
  const base = path.join(__dirname, "..", "..", "deployments");
  const primary = path.join(base, `${networkName}.json`);
  if (fs.existsSync(primary)) {
    return JSON.parse(fs.readFileSync(primary, "utf8"));
  }

  // Legacy fallbacks
  const fallbacks = [
    path.join(base, `${networkName}-energy-system.json`),
    path.join(base, `${networkName}-deploy.json`),
    path.join(base, `polygon.json`),
    path.join(base, `localhost.json`),
  ];
  for (const f of fallbacks) {
    if (fs.existsSync(f)) {
      return JSON.parse(fs.readFileSync(f, "utf8"));
    }
  }

  throw new Error(`No deployment file found for network '${networkName}' in ${base}`);
}

module.exports = { loadDeployment };
