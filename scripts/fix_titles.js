const admin = require('firebase-admin');

// CONFIGURATION
const FIREBASE_SERVICE_ACCOUNT_KEY = "C:\\Users\\psiva\\Downloads\\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json";

// Initialize Firebase
const serviceAccount = require(FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

function toTitleCase(str) {
  return str.split(' ').map(word => {
    if (word.length === 0) return word;
    return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
  }).join(' ');
}

function cleanTitle(str) {
  if (!str) return str;
  
  // 1. Remove "- MassTamilan" or any variation (case insensitive)
  let cleaned = str.replace(/-?\s*masstamilan.*$/i, '');
  
  // 2. Remove anything inside parentheses, e.g. "(Santhosh Narayanan)"
  cleaned = cleaned.replace(/\([^)]*\)/g, '');
  
  // 3. Remove trailing hyphens and spaces
  cleaned = cleaned.replace(/[- ]+$/, '');
  
  // 4. Trim spaces
  cleaned = cleaned.trim();
  
  // 5. Convert to Title Case
  return toTitleCase(cleaned);
}

function cleanArtist(str) {
  if (!str) return "Unknown Artist";
  let cleaned = str.replace(/-?\s*masstamilan.*$/i, '');
  cleaned = cleaned.trim();
  if (cleaned === "" || cleaned.toLowerCase() === "masstamilan" || cleaned.toLowerCase() === "unknown") {
    return "Unknown Artist";
  }
  return toTitleCase(cleaned);
}

async function fixSongs() {
  console.log("Fetching all songs from Firestore to fix titles...");
  const snapshot = await db.collection('songs').get();
  
  if (snapshot.empty) {
    console.log("No songs found in Firestore.");
    return;
  }

  console.log(`Found ${snapshot.size} songs. Starting cleanup...`);
  
  let updateCount = 0;
  
  // Using batches to update multiple documents efficiently
  let batch = db.batch();
  let operationsInBatch = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const originalTitle = data.title || "";
    const originalArtist = data.artist || "";
    
    const newTitle = cleanTitle(originalTitle);
    const newArtist = cleanArtist(originalArtist);
    
    // Only update if there is a change
    if (originalTitle !== newTitle || originalArtist !== newArtist) {
      console.log(`\nOriginal: ${originalTitle} | ${originalArtist}`);
      console.log(`Fixed   : ${newTitle} | ${newArtist}`);
      
      batch.update(doc.ref, {
        title: newTitle,
        artist: newArtist
      });
      
      updateCount++;
      operationsInBatch++;
      
      // Firestore batches have a limit of 500 operations
      if (operationsInBatch >= 450) {
        await batch.commit();
        batch = db.batch();
        operationsInBatch = 0;
      }
    }
  }

  // Commit any remaining updates in the last batch
  if (operationsInBatch > 0) {
    await batch.commit();
  }

  console.log("\n=========================================");
  console.log(`Cleanup complete!`);
  console.log(`Total songs checked: ${snapshot.size}`);
  console.log(`Total songs fixed: ${updateCount}`);
  process.exit(0);
}

fixSongs().catch(console.error);
