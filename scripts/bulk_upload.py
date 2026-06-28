import os
import glob
import cloudinary
import cloudinary.uploader
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from tinytag import TinyTag

# ==========================================
# CONFIGURATION
# ==========================================
# 1. Set the path to the folder containing your MP3 files
MP3_FOLDER_PATH = r"D:\Mp3 songs"

# 2. Set the path to your Firebase Admin SDK service account key JSON file
#    (Get this from Firebase Console -> Project Settings -> Service Accounts -> Generate new private key)
FIREBASE_SERVICE_ACCOUNT_KEY = r"C:\Users\psiva\Downloads\symphony-music-app-6eddc-firebase-adminsdk-fbsvc-8b2075f944.json"
# ==========================================

# Initialize Cloudinary
cloudinary.config(
    cloud_name="dx02qjcqn",
    api_key="424668629472834",
    api_secret="Ln3kEROFIDnMSimvM4n27EgavfI"
)

def init_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
        return firestore.client()
    except Exception as e:
        print(f"Failed to initialize Firebase: {e}")
        return None

def process_and_upload_mp3s(directory_path, db):
    print(f"Starting bulk upload from: {directory_path}")
    print("-" * 50)
    
    # Use glob to find all .mp3 files recursively in the directory
    mp3_files = glob.glob(os.path.join(directory_path, '**/*.mp3'), recursive=True)
    
    if not mp3_files:
        print("No MP3 files found in the specified directory.")
        return

    print(f"Found {len(mp3_files)} MP3 files. Beginning processing...")
    
    success_count = 0
    failure_count = 0

    for file_path in mp3_files:
        filename = os.path.basename(file_path)
        print(f"\nProcessing: {filename}")
        
        try:
            # 1. Extract Metadata using tinytag
            tag = TinyTag.get(file_path)
            
            # Fallback to filename if title is missing in metadata
            title = tag.title
            if not title or title.strip() == "":
                title = os.path.splitext(filename)[0]
                
            artist = tag.artist
            if not artist or artist.strip() == "":
                artist = "Unknown Artist"
                
            print(f"  - Extracted metadata -> Title: '{title}', Artist: '{artist}'")

            # 2. Upload to Cloudinary
            print("  - Uploading audio to Cloudinary...")
            upload_result = cloudinary.uploader.upload(
                file_path, 
                resource_type="video", # Audio files MUST use resource_type 'video' in Cloudinary
                folder="symphony_audio" # Optional: keeps your Cloudinary dashboard clean
            )
            
            secure_url = upload_result.get('secure_url')
            if not secure_url:
                raise Exception("Cloudinary upload succeeded but no secure_url was returned.")
                
            print(f"  - Cloudinary upload successful. URL: {secure_url}")

            # 3. Save to Firestore
            print("  - Saving metadata to Firestore...")
            doc_ref = db.collection('songs').document()
            
            song_data = {
                'title': title.strip(),
                'artist': artist.strip(),
                'audioUrl': secure_url,
                'coverUrl': '', # Can be updated later by admin
                'isTrending': False,
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            doc_ref.set(song_data)
            print(f"  - Successfully added to Firestore with ID: {doc_ref.id}")
            
            success_count += 1
            
        except Exception as e:
            print(f"  [ERROR] Failed to process {filename}: {e}")
            failure_count += 1
            continue # Important: continue to the next file if this one fails

    print("\n" + "=" * 50)
    print("Bulk Upload Completed!")
    print(f"Total Files Found: {len(mp3_files)}")
    print(f"Successfully Uploaded: {success_count}")
    print(f"Failed Uploads: {failure_count}")

if __name__ == "__main__":
    if MP3_FOLDER_PATH == "C:/path/to/your/mp3/folder":
        print("ERROR: Please open the script and update 'MP3_FOLDER_PATH' with your actual folder path.")
    elif FIREBASE_SERVICE_ACCOUNT_KEY == "C:/path/to/serviceAccountKey.json":
        print("ERROR: Please open the script and update 'FIREBASE_SERVICE_ACCOUNT_KEY' with the path to your Firebase credentials JSON file.")
    else:
        db = init_firebase()
        if db:
            process_and_upload_mp3s(MP3_FOLDER_PATH, db)
