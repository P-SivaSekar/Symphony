const https = require('https');

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
        headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://www.jiosaavn.com/',
        }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

async function test() {
  try {
    const res = await fetch('https://www.jiosaavn.com/api.php?__call=search.getResults&q=tamil&n=5&p=1&_format=json&_marker=0&ctx=web6dot0');
    console.log(res);
  } catch (e) {
    console.error(e);
  }
}

test();
