const { existsSync, readFileSync } = require("fs")
const { load } = require("js-yaml")
const configPath = require("./configPath")
const { railsEnv } = require("../env")

const integrityEnabled = () => {
  if (!existsSync(configPath)) return false

  try {
    const appYmlObject = load(readFileSync(configPath), "utf8")
    const envAppConfig = appYmlObject[railsEnv]

    if (envAppConfig) return !!envAppConfig.integrity

    /* eslint no-console:0 */
    console.warn(
      `Warning: ${railsEnv} key not found in ${configPath}. Assuming integrity disabled.`
    )

    return false
  } catch (error) {
    console.error(
      `Error occurred while trying to check integrity attribute: ${error}, assuming integrity disabled.`
    )

    return false
  }
}

module.exports = integrityEnabled
