const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  page.on('console', msg => {
    console.log(`PAGE LOG [${msg.type()}]: ${msg.text()}`);
  });

  page.on('pageerror', error => {
    console.log(`PAGE ERROR: ${error.message}`);
  });

  page.on('requestfailed', request => {
    console.log(`REQUEST FAILED: ${request.url()} - ${request.failure()?.errorText}`);
  });

  console.log("Navigating to the web app...");
  await page.goto('https://symphony-music-app-6eddc.web.app', { waitUntil: 'networkidle0', timeout: 15000 }).catch(e => console.log(e));
  
  console.log("Waiting for 3 seconds...");
  await new Promise(r => setTimeout(r, 3000));

  console.log("Done.");
  await browser.close();
})();
