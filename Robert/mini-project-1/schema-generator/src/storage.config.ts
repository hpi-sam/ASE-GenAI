import { readFileSync } from "fs";

// For testing purposes.
console.log('Current directory: ', __dirname);

const SETUP_QUERIES = readFileSync('./sql/create_tables.sql', 'utf8');
const LOAD_QUERIES = readFileSync('./sql/load.sql', 'utf8');

export {
  SETUP_QUERIES,
  LOAD_QUERIES
};
