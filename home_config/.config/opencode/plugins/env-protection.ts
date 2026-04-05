/**
 * .env Protection Plugin: Prevents agents from reading sensitive files.
 * Blocks reads of .env files, credentials, secrets, and private keys.
 */

export const EnvProtectionPlugin = async () => {
  const sensitivePatterns = [
    ".env",
    ".env.local",
    ".env.production",
    ".env.development",
    ".env.staging",
    "credentials",
    "secrets",
    "private-key",
    "id_rsa",
    "id_ed25519",
    ".pem",
    ".key",
    "authorized_keys",
  ]

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "read" && input.tool !== "grep" && input.tool !== "glob")
        return

      const filePath = output.args?.filePath || output.args?.path || ""
      const lowerPath = filePath.toLowerCase()

      if (sensitivePatterns.some((pattern) => lowerPath.includes(pattern))) {
        throw new Error(
          `Blocked: Cannot access sensitive file "${filePath}". ` +
            `Files matching ${sensitivePatterns.join(", ")} are protected.`
        )
      }
    },
  }
}
