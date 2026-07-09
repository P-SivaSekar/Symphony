const admin = require('firebase-admin');
const serviceAccount = require("C:\\Users\\psiva\\Downloads\\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function dump() {
  const snapshot = await db.collection('songs').get();
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`ID: ${doc.id} | Title: ${data.title} | Audio: ${data.audioUrl}`);
  });
}

dump().catch(console.error);
