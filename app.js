import { createServer } from 'http';

const PORT = process.env.PORT || 1000;
const ENV  = process.env.APP_ENV || 'development';

const server = createServer((req, res) => {

  // Health check endpoint — CloudWatch aur K8s yahi check karta hai
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', env: ENV }));
    return;
  }

  // Main endpoint
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(`Hello from Shipyard! Env: ${ENV}, Port: ${PORT}`);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${ENV} mode`);
});