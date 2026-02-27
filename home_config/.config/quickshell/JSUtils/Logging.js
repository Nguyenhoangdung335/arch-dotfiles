// .pragma library

/**
 * Log a message with the given level.
 *
 * @param {string} level - The log level (e.g. "INFO")
 * @param {string} message - The message to log
 * @param {any[]} optionalParams - Optional parameters to include in the log message
 */

function log(level, message, ...optionalParams) {
  switch (level) {
    case "INFO":
      logInfo(message, ...optionalParams);
      break;
    case "WARNING":
      logWarning(message, ...optionalParams);
      break;
    case "ERROR":
      logError(message, ...optionalParams);
      break;
    default:
      console.error("Invalid log level: " + level);
  }
}

/**
 * Log an info message with the given level.
 *
 * @param {string} message - The message to log
 * @param {any[]} optionalParams - Optional parameters to include in the log message
 */
function info(message, ...optionalParams) {
  if (typeof message === "object") {
    message = JSON.stringify(message);
  }
  let jsonParams = [];
  for (let i = 0; i < optionalParams.length; i++) {
    if (typeof optionalParams[i] === "object") {
      jsonParams[i] = JSON.stringify(optionalParams[i]);
    }
  }
  console.log("[INFO]", message, ...jsonParams);
}

/**
 * Log a warning message with the given level.
 *
 * @param {string} message - The message to log
 * @param {any[]} optionalParams - Optional parameters to include in the log message
 */
function warn(message, ...optionalParams) {
  if (typeof message === "object") {
    message = JSON.stringify(message);
  }
  for (let i = 0; i < optionalParams.length; i++) {
    if (typeof optionalParams[i] === "object") {
      optionalParams[i] = JSON.stringify(optionalParams[i]);
    }
  }

  console.warn("[WARNING]", message, ...optionalParams);
}

/**
 * Log an error message with the given level.
 *
 * @param {string} message - The message to log
 * @param {any[]} optionalParams - Optional parameters to include in the log message
 */
function error(message, ...optionalParams) {
  if (typeof message === "object") {
    message = JSON.stringify(message);
  }
  for (let i = 0; i < optionalParams.length; i++) {
    if (typeof optionalParams[i] === "object") {
      optionalParams[i] = JSON.stringify(optionalParams[i]);
    }
  }

  console.error("[ERROR]", message, ...optionalParams);
}
