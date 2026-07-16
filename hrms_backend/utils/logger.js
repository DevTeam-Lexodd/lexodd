// Simple logger - accepts an optional metadata object as a second argument
const format = (level, msg, meta) => {
  if (meta && Object.keys(meta).length > 0) {
    return `${level}: ${msg} ${JSON.stringify(meta)}`;
  }
  return `${level}: ${msg}`;
};

const logger = {
  info: (msg, meta) => console.log(format('INFO', msg, meta)),
  warn: (msg, meta) => console.warn(format('WARN', msg, meta)),
  error: (msg, meta) => console.error(format('ERROR', msg, meta)),
  debug: (msg, meta) => console.log(format('DEBUG', msg, meta))
};

module.exports = logger;