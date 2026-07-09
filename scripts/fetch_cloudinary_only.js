const cloudinary = require('cloudinary').v2;
const fs = require('fs');

cloudinary.config({
    cloud_name: "dx02qjcqn",
    api_key: "424668629472834",
    api_secret: "Ln3kEROFIDnMSimvM4n27EgavfI"
});

async function fetchCloudinary() {
    console.log("Fetching all resources from Cloudinary (symphony_audio)...");
    
    let resources = [];
    let next_cursor = null;
    
    do {
        const result = await cloudinary.search
            .expression('resource_type:video AND folder:symphony_audio')
            .max_results(500)
            .next_cursor(next_cursor)
            .execute();
            
        resources = resources.concat(result.resources);
        next_cursor = result.next_cursor;
    } while (next_cursor);
    
    console.log(`Fetched ${resources.length} resources from Cloudinary.`);
    
    const mapped = resources.map(r => ({
        original_filename: r.filename, // or r.public_id
        secure_url: r.secure_url
    }));
    
    fs.writeFileSync('cloudinary_resources.json', JSON.stringify(mapped, null, 2));
    console.log("Wrote cloudinary_resources.json");
}

fetchCloudinary().catch(console.error);
