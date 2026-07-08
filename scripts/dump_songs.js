const admin = require('firebase-admin');
const serviceAccount = require("C:\\Users\\psiva\\Downloads\\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();
db.collection('songs').get().then(snapshot => {
  snapshot.forEach(doc => {
    console.log(`ID: ${doc.id} | Title: "${doc.data().title}" | Cover: "${doc.data().coverUrl}"`);
  });
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});
