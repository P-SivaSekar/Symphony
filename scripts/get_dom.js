const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  await page.goto('https://symphony-music-app-6eddc.web.app', { waitUntil: 'networkidle0', timeout: 15000 }).catch(e => console.log(e));
  
  await new Promise(r => setTimeout(r, 3000));

  const bodyHTML = await page.evaluate(() => document.body.innerHTML);
  console.log("BODY HTML:");
  console.log(bodyHTML);

  await browser.close();
})();
