/* jshint esversion: 6 */
import express from 'express';
const app = express();

const port = 8080;
import { env } from 'process';

app.set('view engine', 'pug');

app.get('/healthz', (req, res) => res
    .status(200)
    .send("healthy")
);

app.get('/', (req, res) => res.render('index', {
    title: 'Sample Application',
    data: { environment: env, headers: req.headers }
}));

app.listen(port, () => console.log(`Sample app accessible at http://localhost:${port}/`));