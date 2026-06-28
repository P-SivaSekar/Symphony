const fs = require('fs');
const path = require('path');
const cloudinary = require('cloudinary').v2;
const admin = require('firebase-admin');

// ==========================================
// CONFIGURATION
// ==========================================
const MP3_FOLDER_PATH = "D:\\Mp3 songs";
const FIREBASE_SERVICE_ACCOUNT_KEY = "C:\\Users\\psiva\\Downloads\\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json";

// Initialize Cloudinary
cloudinary.config({ 
  cloud_name: 'dx02qjcqn', 
  api_key: '424668629472834', 
  api_secret: 'Ln3kEROFIDnMSimvM4n27EgavfI' 
});

// Initialize Firebase
const serviceAccount = require(FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// Helpers
function getAllFiles(dirPath, arrayOfFiles) {
  const files = fs.readdirSync(dirPath);
  arrayOfFiles = arrayOfFiles || [];
  files.forEach(function(file) {
    if (fs.statSync(dirPath + "/" + file).isDirectory()) {
      arrayOfFiles = getAllFiles(dirPath + "/" + file, arrayOfFiles);
    } else {
      if (file.toLowerCase().endsWith('.mp3') || file.toLowerCase().endsWith('.m4a')) {
        arrayOfFiles.push(path.join(dirPath, file));
      }
    }
  });
  return arrayOfFiles;
}

async function uploadAudio(filePath) {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload(filePath, { resource_type: "video", folder: "symphony_audio" }, function(error, result) {
      if (error) reject(error);
      else resolve(result.secure_url);
    });
  });
}

function toTitleCase(str) {
  if (!str) return "Unknown Artist";
  return str.split(' ').map(word => {
    if (word.length === 0) return word;
    return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
  }).join(' ');
}

function extractMetadata(rawTitle, rawArtist, filename) {
  let title = rawTitle || filename.replace(/\.(mp3|m4a)$/i, '');
  let artist = rawArtist || "Unknown Artist";

  // Clean common pirated site tags
  const badTagsRegex = /-?\s*(masstamilan|mp3bhai|masstelugu|friendstamilmp3|isaimini|starmusiq|sensongs).*$/i;
  
  title = title.replace(badTagsRegex, '').trim();
  artist = artist.replace(badTagsRegex, '').trim();
  
  if (artist === "" || artist.toLowerCase() === "unknown") {
    artist = "Unknown Artist";
  }

  // Check for Artist after hyphen
  const hyphenMatch = title.match(/^(.*?)\s*-\s*(.+)$/);
  if (hyphenMatch && artist === "Unknown Artist") {
    title = hyphenMatch[1];
    artist = hyphenMatch[2];
  }

  // Check for Artist in parentheses
  const parenMatch = title.match(/^(.*?)\s*\((.+?)\)$/);
  if (parenMatch && artist === "Unknown Artist") {
    title = parenMatch[1];
    artist = parenMatch[2];
  }

  title = title.replace(/\([^)]*\)/g, '').replace(/[- ]+$/, '').trim();
  artist = artist.replace(/\([^)]*\)/g, '').replace(/[- ]+$/, '').trim();

  return { 
    title: toTitleCase(title), 
    artist: toTitleCase(artist === "" ? "Unknown Artist" : artist) 
  };
}

async function searchITunes(title) {
  try {
    const searchQuery = title.split('-')[0].trim();
    const url = `https://itunes.apple.com/search?term=${encodeURIComponent(searchQuery)}&entity=song&limit=1`;
    const res = await fetch(url);
    const json = await res.json();
    if (json.results && json.results.length > 0) {
      const match = json.results[0];
      return {
        artist: match.artistName,
        coverUrl: match.artworkUrl100 ? match.artworkUrl100.replace('100x100bb', '600x600bb') : null
      };
    }
  } catch(e) {
    console.log("    -> iTunes lookup failed:", e.message);
  }
  return null;
}

async function uploadCoverArt(buffer) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: "symphony_covers" },
      function(error, result) {
        if (error) reject(error);
        else resolve(result.secure_url);
      }
    );
    stream.end(buffer);
  });
}

async function main() {
  console.log("Starting bulk upload with Cover Art, Smart Extraction & iTunes Fallback...");
  const files = getAllFiles(MP3_FOLDER_PATH);
  
  if (files.length === 0) {
      console.log("No audio files found in " + MP3_FOLDER_PATH);
      return;
  }
  
  console.log(`Found ${files.length} audio files. Uploading...`);
  const mm = await import('music-metadata');

  let successCount = 0;
  let updateCount = 0;
  let failureCount = 0;

  for (const file of files) {
    const filename = path.basename(file);
    console.log(`\nProcessing: ${filename}`);
    try {
      const metadata = await mm.parseFile(file);
      const extracted = extractMetadata(metadata.common.title, metadata.common.artist, filename);
      let title = extracted.title;
      let artist = extracted.artist;
      
      console.log(`  - Title: '${title}' | Artist: '${artist}'`);

      // Check if song exists first to save bandwidth and API calls
      const existing = await db.collection('songs').where('title', '==', title).limit(1).get();
      
      if (!existing.empty) {
        console.log(`  - Song '${title}' already exists. Skipping...`);
        // We skip updating because we already ran a cleanup script. 
        // If we want to add new songs, we just ignore existing ones.
        continue;
      }

      // Cover Art Extraction
      let coverUrl = '';
      if (metadata.common.picture && metadata.common.picture.length > 0) {
        console.log(`  - Found official MP3 cover art! Uploading...`);
        coverUrl = await uploadCoverArt(metadata.common.picture[0].data);
      } else {
        console.log(`  - No cover art found in file.`);
      }

      // iTunes Fallback for Artist / Cover Art
      if (artist === "Unknown Artist" || coverUrl === '') {
        console.log(`  - Missing artist or cover. Searching iTunes API...`);
        const itunesData = await searchITunes(title);
        if (itunesData) {
          if (artist === "Unknown Artist" && itunesData.artist) {
             artist = itunesData.artist;
             console.log(`    -> Found Artist on iTunes: ${artist}`);
          }
          if (coverUrl === '' && itunesData.coverUrl) {
             coverUrl = itunesData.coverUrl;
             console.log(`    -> Found Cover Art on iTunes!`);
          }
        } else {
          console.log(`    -> No iTunes match found.`);
        }
      }

      console.log(`  - Uploading audio to Cloudinary...`);
      const secure_url = await uploadAudio(file);

      console.log(`  - Saving to Firestore...`);
      await db.collection('songs').add({
        title: title,
        artist: artist,
        audioUrl: secure_url,
        coverUrl: coverUrl,
        isTrending: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`  - Success!`);
      successCount++;
    } catch (e) {
      console.error(`  [ERROR] Failed to process ${filename}:`, e.message);
      failureCount++;
    }
  }

  console.log("\n=========================================");
  console.log("Bulk Upload Completed!");
  console.log(`Total Files Found: ${files.length}`);
  console.log(`New Uploads: ${successCount}`);
  console.log(`Updated Existing: ${updateCount}`);
  console.log(`Failed: ${failureCount}`);
  
  process.exit(0);
}

main().catch(console.error);
