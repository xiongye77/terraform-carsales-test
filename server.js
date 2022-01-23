'use strict';

const express = require('express');

// Constants
const PORT = 80;
const HOST = '0.0.0.0';

// App
const app = express();

app.get('/health', (req, res) => res.send('Health check status: ok'))
app.get('/carsales1/', (req, res) => {
  res.send('Hello Worlda  version 3');
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);

