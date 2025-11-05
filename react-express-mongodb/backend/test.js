// Simple dummy test for backend
console.log('Running backend tests...');

// Test 1: Check if server file exists
const fs = require('fs');
if (fs.existsSync('./server.js')) {
  console.log('✓ Server file exists');
} else {
  console.error('✗ Server file missing');
  process.exit(1);
}

// Test 2: Check if package.json is valid
try {
  const pkg = require('./package.json');
  if (pkg.name && pkg.version) {
    console.log('✓ Package.json is valid');
  } else {
    throw new Error('Invalid package.json');
  }
} catch (err) {
  console.error('✗ Package.json validation failed:', err.message);
  process.exit(1);
}

// Test 3: Basic smoke test
console.log('✓ All tests passed');
process.exit(0);
