/* jshint esversion: 6 */
const express = require('express');
const app = express();

const port = 8080;
const process = require('process');

app.set('view engine', 'pug');
app.get('/', (req, res) => res.render('index', {
    title: 'Sample Application',
    env: process.env
}));

app.listen(port, () => console.log(`Sample app accessible at http://localhost:${port}/`));