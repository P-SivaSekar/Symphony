const cloudinary = require('cloudinary').v2;
const admin = require('firebase-admin');

const FIREBASE_SERVICE_ACCOUNT_KEY = "C:\\Users\\psiva\\Downloads\\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json";

cloudinary.config({
    cloud_name: "dx02qjcqn",
    api_key: "424668629472834",
    api_secret: "Ln3kEROFIDnMSimvM4n27EgavfI"
});

const serviceAccount = require(FIREBASE_SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

async function fixFirestore() {
    console.log("Fetching all resources from Cloudinary (symphony_audio)...");
    
    let resources = [];
    let next_cursor = null;
    
    do {
        const result = await cloudinary.api.resources({
            resource_type: 'video',
            prefix: 'symphony_audio',
            max_results: 500,
            next_cursor: next_cursor
        });
        resources = resources.concat(result.resources);
        next_cursor = result.next_cursor;
    } while (next_cursor);
    
    console.log(`Fetched ${resources.length} resources from Cloudinary.`);
    
    console.log("Fetching all songs from Firestore...");
    const snapshot = await db.collection('songs').get();
    console.log(`Fetched ${snapshot.size} songs from Firestore.`);
    
    let batch = db.batch();
    let updates = 0;
    
    for (const doc of snapshot.docs) {
        const data = doc.data();
        const id = doc.id;
        
        let originalTitle = data.title || "";
        let audioUrl = data.audioUrl || "";
        let coverUrl = data.coverUrl || "";
        
        // Find matching resource in cloudinary by original_filename (e.g. "Manjanathi Marathu Katta" original filename might be "Chillax")
        // Wait, how do we match if the title was overwritten?
        // Let's just list mismatched ones and see!
        
        if (audioUrl.includes('saavncdn') || originalTitle.toLowerCase().includes('manjanathi')) {
            console.log(`Mismatched song found: [${id}] ${originalTitle}`);
            console.log(`   Audio: ${audioUrl}`);
        }
    }
}

fixFirestore().catch(console.error);
