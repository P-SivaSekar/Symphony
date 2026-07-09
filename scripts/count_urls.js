const fs = require('fs');

try {
  const data = fs.readFileSync('D:/Studies/Projects/Music Player/firestore_songs.json', 'utf8');
  
  // The JSON is likely chunked or slightly malformed due to the logging wrapper
  // We can just use regex to count URLs!
  
  const saavnMatches = data.match(/https:\/\/aac\.saavncdn\.com[^"]*/g) || [];
  const cloudinaryMatches = data.match(/https:\/\/res\.cloudinary\.com[^"]*/g) || [];
  
  console.log(`Saavn URLs found: ${saavnMatches.length}`);
  console.log(`Cloudinary URLs found: ${cloudinaryMatches.length}`);
  
  // Find "Chillax" or "Manjanathi"
  const manjanathiMatches = data.match(/[^"]*manjanathi[^"]*/gi) || [];
  console.log(`Manjanathi found: ${manjanathiMatches.length} times`);
  
} catch (e) {
  console.error(e);
}
