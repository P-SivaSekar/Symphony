import firebase_admin
from firebase_admin import credentials, firestore

cred_path = r"C:\Users\psiva\Downloads\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json"
try:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    songs_ref = db.collection('songs')
    for doc in songs_ref.stream():
        data = doc.to_dict()
        print(f"ID: {doc.id} | Title: {data.get('title')} | Audio: {data.get('audioUrl')}")
except Exception as e:
    print(f"Error: {e}")
