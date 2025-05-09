resource "google_storage_bucket" "website" {                      # Create a new Google Cloud Storage bucket
  provider = google                                               # Use the configured Google Cloud provider
  name     = "gcp-terraform-website-bucket-by-aditya-saxena"      # Assign a unique name to the bucket
  location = "northamerica-northeast2"                            # Set the bucket region to Montréal, Canada
  force_destroy = true                                            # Allow bucket deletion even if it contains files
  uniform_bucket_level_access = true                              # Enforce uniform IAM access to all objects

  website {                                                       # Enable website configuration for the bucket
    main_page_suffix = "index.html"                               # Serve index.html as the default root page
  }
}

resource "google_storage_bucket_iam_member" "public_access" {     # Grant public read access to the bucket's objects
  bucket = google_storage_bucket.website.name                     # Target the bucket created above
  role   = "roles/storage.objectViewer"                           # Assign the objectViewer role
  member = "allUsers"                                             # Apply this role to all users (public)
}

resource "google_storage_bucket_object" "html_file" {             # Upload the HTML file to the bucket
  name   = "index.html"                                           # Name it index.html in the bucket
  bucket = google_storage_bucket.website.name                     # Place it in the same website bucket
  source = "${path.module}/Website/index.html"                    # Path to the local index.html file
  content_type = "text/html" 
}

resource "google_storage_bucket_object" "css_file" {              # Upload the CSS file to the bucket
  name   = "style.css"                                            # Name it style.css in the bucket
  bucket = google_storage_bucket.website.name                     # Use the same website bucket
  source = "${path.module}/Website/style.css"                     # Path to the local style.css file
  content_type = "text/css" 
}

resource "google_storage_bucket_object" "js_file" {               # Upload the JavaScript file to the bucket
  name   = "script.js"                                            # Name it script.js in the bucket
  bucket = google_storage_bucket.website.name                     # Use the same website bucket
  source = "${path.module}/Website/script.js"                     # Path to the local script.js file
  content_type = "application/javascript"
}