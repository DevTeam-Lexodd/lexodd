// Simple logger - no winston dependency
const logger = {
  info: (msg) => console.log(`INFO: ${msg}`),
  warn: (msg) => console.log(`WARN: ${msg}`),
  error: (msg) => console.log(`ERROR: ${msg}`),
  debug: (msg) => console.log(`DEBUG: ${msg}`)
};

module.exports = logger;
