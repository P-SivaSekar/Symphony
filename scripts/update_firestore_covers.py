import sys
import urllib.parse
import requests
import firebase_admin
from firebase_admin import credentials, firestore

# Path to Firebase Admin SDK credential file
cred_path = r"C:\Users\psiva\Downloads\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json"

def main():
    print("Initializing Firebase Admin SDK...")
    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        sys.exit(1)

    print("Fetching songs from Firestore 'songs' collection...")
    songs_ref = db.collection('songs')
    docs = list(songs_ref.stream())
    print(f"Found {len(docs)} song records.")

    updated_count = 0
    skipped_count = 0

    for doc in docs:
        song_id = doc.id
        data = doc.to_dict()
        title = data.get('title', '').strip()
        artist = data.get('artist', '').strip()
        current_cover = data.get('coverUrl', '').strip()

        # Check if coverUrl needs updating (is empty, placeholder, or is a deleted cloudinary URL)
        needs_update = (
            not current_cover or
            "cloudinary.com" in current_cover or
            "placeholder" in current_cover or
            "via.placeholder.com" in current_cover
        )

        if not needs_update:
            print(f"Skipping '{title}' (Already has valid cover: {current_cover})")
            skipped_count += 1
            continue

        print(f"Resolving cover for '{title}' (by {artist})...")
        try:
            # Query the CORS-friendly JioSaavn Vercel API proxy
            query = urllib.parse.quote(title)
            url = f"https://jiosaavn-api.vercel.app/search?query={query}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                res_data = response.json()
                cover_url = None
                
                if res_data.get('status') is True and res_data.get('results'):
                    results = res_data['results']
                    # Attempt to find the first result with images
                    first_match = results[0]
                    images = first_match.get('images', {})
                    if images and isinstance(images, dict) and images.get('500x500'):
                        cover_url = images['500x500']
                    else:
                        cover_url = first_match.get('image')

                if cover_url:
                    # Replace resolution placeholder with high quality 500x500 if present
                    cover_url = cover_url.replace('50x50', '500x500').replace('150x150', '500x500')
                    print(f"  -> Found Cover: {cover_url}")
                    
                    # Update the record in Firestore
                    doc.reference.update({'coverUrl': cover_url})
                    print("  -> Updated Firestore successfully.")
                    updated_count += 1
                else:
                    print("  -> No cover art found on JioSaavn.")
            else:
                print(f"  -> API returned status code {response.status_code}")
        except Exception as e:
            print(f"  -> Error: {e}")

    print("\n" + "=" * 50)
    print("Database Update Complete!")
    print(f"Total Songs Inspected: {len(docs)}")
    print(f"Updated coverUrl:      {updated_count}")
    print(f"Skipped (already OK):  {skipped_count}")
    print("=" * 50)

if __name__ == "__main__":
    main()
