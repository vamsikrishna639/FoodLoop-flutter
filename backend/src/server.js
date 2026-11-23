// Entry point: load .env, connect to MongoDB, then start listening.
require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/db');

const PORT = process.env.PORT || 5000;

async function start() {
  if (!process.env.JWT_SECRET) {
    console.error('JWT_SECRET is missing. Copy .env.example to .env first.');
    process.exit(1);
  }
  try {
    await connectDB();
    app.listen(PORT, () => console.log(`FoodLoop API listening on http://localhost:${PORT}`));
  } catch (err) {
    console.error('Could not start the server:', err.message);
    process.exit(1);
  }
}

start();
