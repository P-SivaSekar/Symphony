#!/usr/bin/env python3
"""
Symphony Music Player - Song Cover URL Updater
==============================================
This script automates the process of replacing low-resolution / low-quality 
Cloudinary song cover URLs with official, high-resolution (500x500, 640x640, or 800x800)
cover URLs from Spotify (primary option) or JioSaavn (fallback).

How it works:
1. If Spotify credentials (client_id, client_secret) are provided, the script
   searches Spotify's official Web API and extracts the 640x640 cover URL (e.g., https://i.scdn.co/image/...).
2. If Spotify fails or if credentials are not provided, the script searches JioSaavn's public
   API (https://saavn.dev/api/search/songs) and extracts the 500x500 or 800x800 image URL.
3. If both search attempts fail, it gracefully keeps the existing Cloudinary URL.

Prerequisites:
  pip install requests
"""

import json
import logging
import re
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

# ==============================================================================
# CONFIGURATION & SETTINGS
# ==============================================================================

# 1. DATA INPUT METHOD
# Options: "placeholder" (use RAW_DATA_PLACEHOLDER below) or "file" (read from INPUT_FILE_PATH)
DATA_SOURCE = "placeholder"
INPUT_FILE_PATH = "songs_input.json"
OUTPUT_FILE_PATH = "updated_songs.json"
LOG_FILE_PATH = "cover_update_issues.log"

# 2. SPOTIFY API CREDENTIALS (Recommended for i.scdn.co URLs)
# To get these: Go to https://developer.spotify.com/, log in, click "Create App",
# and copy the Client ID and Client Secret. Leave empty to skip Spotify and use JioSaavn directly.
SPOTIFY_CLIENT_ID = ""
SPOTIFY_CLIENT_SECRET = ""

# 3. KEY MAPPING (How to read/write properties in your song dictionaries)
KEY_SONG_NAME = "title"       # Key for song/track name in your source data
KEY_ALBUM_NAME = "album"      # Key for album/movie title in your source data
KEY_COVER_URL = "coverUrl"    # Key for the cover image URL in your source data

# 4. REQUEST CONFIGURATION
SAAVN_API_ENDPOINT = "https://saavn.dev/api/search/songs"
MAX_WORKERS = 5               # Number of parallel threads to fetch URLs
REQUEST_TIMEOUT = 10          # Timeout per request in seconds
BACKOFF_FACTOR = 1.0          # Delay multiplier between retries
MAX_RETRIES = 3               # Number of retries for failed requests

# ==============================================================================
# 1. READ MY EXISTING DATA - PLACEHOLDER
# ==============================================================================
# Paste your raw JSON or Python list representation of songs here.
RAW_DATA_PLACEHOLDER = """[
  {
    "id": "1",
    "title": "Naanga Naalu Peru",
    "album": "Karuppu",
    "coverUrl": "https://res.cloudinary.com/dx02qjcqn/image/upload/v1779194288/symphony_covers/atzrkuhibd3j7ggrqcic.jpg"
  }
]"""

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE_PATH, encoding="utf-8"),
        logging.StreamHandler()
    ]
)

class CoverFetcher:
    def __init__(self, client_id=None, client_secret=None):
        self.session = self._setup_session()
        self.spotify_token = None
        self.spotify_token_expires = 0
        self.client_id = client_id.strip() if client_id else None
        self.client_secret = client_secret.strip() if client_secret else None
        
        if self.client_id and self.client_secret:
            logging.info("Spotify credentials detected. Attempting token generation...")
            self._authenticate_spotify()
        else:
            logging.info("No Spotify credentials configured. Script will default directly to JioSaavn.")

    def _setup_session(self) -> requests.Session:
        session = requests.Session()
        retry_strategy = Retry(
            total=MAX_RETRIES,
            backoff_factor=BACKOFF_FACTOR,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "POST"]
        )
        adapter = HTTPAdapter(max_retries=retry_strategy, pool_connections=MAX_WORKERS * 2, pool_maxsize=MAX_WORKERS * 2)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        })
        return session

    def _authenticate_spotify(self):
        """Fetches Client Credentials Token from Spotify accounts service."""
        try:
            url = "https://accounts.spotify.com/api/token"
            data = {"grant_type": "client_credentials"}
            response = self.session.post(
                url, 
                data=data, 
                auth=(self.client_id, self.client_secret),
                timeout=REQUEST_TIMEOUT
            )
            response.raise_for_status()
            token_data = response.json()
            self.spotify_token = token_data.get("access_token")
            # Set expiry with a small safety margin
            self.spotify_token_expires = time.time() + token_data.get("expires_in", 3600) - 30
            logging.info("Successfully authenticated with Spotify Web API.")
        except Exception as e:
            logging.error(f"Spotify Authentication failed: {e}. Defaulting to JioSaavn.")
            self.spotify_token = None

    def get_spotify_token(self):
        """Returns a valid Spotify token, refreshing if necessary."""
        if not self.client_id or not self.client_secret:
            return None
        if not self.spotify_token or time.time() > self.spotify_token_expires:
            self._authenticate_spotify()
        return self.spotify_token

    def clean_query_term(self, text: str) -> str:
        """Cleans up names/titles to form a better search query."""
        if not text:
            return ""
        # Remove parentheses content like (From "Movie"), (Feat. Artist), etc.
        text = re.sub(r'[\(\[\{].*?[\)\]\}]', '', text)
        # Clean special characters but keep alphanumeric and spaces
        text = re.sub(r'[^\w\s-]', '', text)
        return " ".join(text.split()).strip()

    def fetch_spotify_cover(self, song_name: str, album_name: str) -> str:
        """Searches Spotify Web API and extracts the 640x640 cover URL."""
        token = self.get_spotify_token()
        if not token:
            return None

        cleaned_song = self.clean_query_term(song_name)
        cleaned_album = self.clean_query_term(album_name)
        
        # Build search query
        query = f"track:{cleaned_song}"
        if cleaned_album:
            query += f" album:{cleaned_album}"
            
        url = f"https://api.spotify.com/v1/search?q={urllib.parse.quote(query)}&type=track&limit=1"
        headers = {"Authorization": f"Bearer {token}"}
        
        try:
            response = self.session.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
            # If rate limited or token expired, we let it fall through
            if response.status_code == 401:
                self.spotify_token = None  # Force re-authentication next time
                return None
            response.raise_for_status()
            
            data = response.json()
            tracks = data.get("tracks", {}).get("items", [])
            if not tracks:
                # Retry search with song name alone if album filter made it too specific
                if cleaned_album:
                    fallback_url = f"https://api.spotify.com/v1/search?q=track:{urllib.parse.quote(cleaned_song)}&type=track&limit=1"
                    resp = self.session.get(fallback_url, headers=headers, timeout=REQUEST_TIMEOUT)
                    if resp.ok:
                        tracks = resp.json().get("tracks", {}).get("items", [])
            
            if tracks:
                # The track album has an 'images' array. 
                # images[0] is usually 640x640, images[1] is 300x300, images[2] is 64x64
                images = tracks[0].get("album", {}).get("images", [])
                if images:
                    return images[0].get("url")  # Return 640x640 cover
        except Exception as e:
            logging.debug(f"Spotify Search error for query '{query}': {e}")
        return None

    def fetch_jiosaavn_cover(self, song_name: str, album_name: str) -> str:
        """Searches JioSaavn wrapper API and extracts the highest res image URL."""
        cleaned_song = self.clean_query_term(song_name)
        cleaned_album = self.clean_query_term(album_name)
        
        query = cleaned_song
        if cleaned_album:
            query = f"{cleaned_song} {cleaned_album}"
            
        url = f"{SAAVN_API_ENDPOINT}?query={urllib.parse.quote(query)}"
        
        try:
            response = self.session.get(url, timeout=REQUEST_TIMEOUT)
            response.raise_for_status()
            res_data = response.json()
            
            if not res_data.get("success") or "data" not in res_data:
                return None
            
            results = res_data["data"].get("results", [])
            if not results and cleaned_album:
                # Fallback to searching song name alone
                fallback_url = f"{SAAVN_API_ENDPOINT}?query={urllib.parse.quote(cleaned_song)}"
                fallback_resp = self.session.get(fallback_url, timeout=REQUEST_TIMEOUT)
                if fallback_resp.ok:
                    results = fallback_resp.json().get("data", {}).get("results", [])
            
            if results:
                best_match = results[0]
                image_list = best_match.get("image")
                if image_list and isinstance(image_list, list):
                    last_image = image_list[-1]
                    if isinstance(last_image, dict):
                        return last_image.get("url") or last_image.get("link") or list(last_image.values())[0]
                    elif isinstance(last_image, str):
                        return last_image
        except Exception as e:
            logging.debug(f"JioSaavn Search error for query '{query}': {e}")
        return None

    def process_song(self, song: dict) -> dict:
        """Processes a single song, trying Spotify then JioSaavn, with fallback to original URL."""
        song_name = song.get(KEY_SONG_NAME, "").strip()
        album_name = song.get(KEY_ALBUM_NAME, "").strip()
        original_url = song.get(KEY_COVER_URL, "")
        
        if not song_name:
            return {**song, "_status": "skipped_empty"}
            
        # 1. Try Spotify first if authenticated
        if self.get_spotify_token():
            spotify_url = self.fetch_spotify_cover(song_name, album_name)
            if spotify_url:
                logging.info(f"SPOTIFY MATCH: '{song_name}' -> {spotify_url}")
                return {**song, KEY_COVER_URL: spotify_url, "_status": "updated_spotify"}
                
        # 2. Try JioSaavn as fallback
        saavn_url = self.fetch_jiosaavn_cover(song_name, album_name)
        if saavn_url:
            logging.info(f"JIOSAAVN MATCH: '{song_name}' -> {saavn_url}")
            return {**song, KEY_COVER_URL: saavn_url, "_status": "updated_jiosaavn"}
            
        # 3. Keeping original fallback
        logging.warning(f"NO MATCH FOUND: '{song_name}' (Album: '{album_name}'). Keeping original cover.")
        return {**song, "_status": "not_found"}

# ==============================================================================
# MAIN CONTROLLER
# ==============================================================================
def main():
    print("=" * 60)
    print("      Official High-Resolution Cover Image URL Updater")
    print("=" * 60)
    
    songs = []
    if DATA_SOURCE == "placeholder":
        print("Reading song data from RAW_DATA_PLACEHOLDER...")
        try:
            songs = json.loads(RAW_DATA_PLACEHOLDER)
        except json.JSONDecodeError:
            try:
                import ast
                songs = ast.literal_eval(RAW_DATA_PLACEHOLDER)
            except Exception as ae:
                print(f"Failed to parse data: {ae}")
                return
    else:
        print(f"Reading song data from: {INPUT_FILE_PATH}...")
        try:
            with open(INPUT_FILE_PATH, "r", encoding="utf-8") as f:
                songs = json.load(f)
        except FileNotFoundError:
            print(f"Error: '{INPUT_FILE_PATH}' not found. Please verify details.")
            return

    if not isinstance(songs, list):
        print("Error: Input data must be a list of song objects.")
        return
        
    total_songs = len(songs)
    print(f"Loaded {total_songs} songs to process.")
    
    fetcher = CoverFetcher(client_id=SPOTIFY_CLIENT_ID, client_secret=SPOTIFY_CLIENT_SECRET)
    updated_songs = []
    
    stats = {"spotify": 0, "jiosaavn": 0, "not_found": 0, "skipped": 0}
    start_time = time.time()
    
    print(f"Processing requests asynchronously via ThreadPoolExecutor. Please wait...")
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_song = {executor.submit(fetcher.process_song, song): song for song in songs}
        completed_count = 0
        
        for future in as_completed(future_to_song):
            completed_count += 1
            result = future.result()
            status = result.pop("_status", "unknown")
            updated_songs.append(result)
            
            if status == "updated_spotify":
                stats["spotify"] += 1
            elif status == "updated_jiosaavn":
                stats["jiosaavn"] += 1
            elif status == "not_found":
                stats["not_found"] += 1
            else:
                stats["skipped"] += 1
                
            if completed_count % 10 == 0 or completed_count == total_songs:
                pct = (completed_count / total_songs) * 100
                print(f"Progress: {completed_count}/{total_songs} ({pct:.1f}%) processed...")

    elapsed_time = time.time() - start_time
    print("\nProcessing complete!")
    print("=" * 60)
    print("                    RUN STATISTICS")
    print("=" * 60)
    print(f"Total Songs Processed:   {total_songs}")
    print(f"Updated from Spotify:    {stats['spotify']}")
    print(f"Updated from JioSaavn:   {stats['jiosaavn']}")
    print(f"Not Found (Fallback):    {stats['not_found']}")
    print(f"Skipped:                 {stats['skipped']}")
    print(f"Total Time Elapsed:      {elapsed_time:.2f} seconds")
    print(f"Detailed logs written to: {LOG_FILE_PATH}")
    print("=" * 60)
    
    # Save the output
    print(f"Saving final updated song data to: {OUTPUT_FILE_PATH}...")
    try:
        # Re-sort to original order
        original_title_id_map = { (song.get(KEY_SONG_NAME), song.get(KEY_ALBUM_NAME), index): index for index, song in enumerate(songs) }
        def get_original_index(s):
            for k, original_idx in original_title_id_map.items():
                if k[0] == s.get(KEY_SONG_NAME) and k[1] == s.get(KEY_ALBUM_NAME):
                    return original_idx
            return 999999
            
        updated_songs.sort(key=get_original_index)
        
        with open(OUTPUT_FILE_PATH, "w", encoding="utf-8") as out_f:
            json.dump(updated_songs, out_f, indent=2, ensure_ascii=False)
        print("Data successfully saved.")
    except Exception as e:
        print(f"Error saving output file: {e}")

if __name__ == "__main__":
    main()
