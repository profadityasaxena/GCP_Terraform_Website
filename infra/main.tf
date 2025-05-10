# Google Cloud Storage Bucket: Create a bucket for hosting the website
resource "google_storage_bucket" "website" {                                   
    provider                     = google                                      # Specify the Google Cloud provider
    name                         = "gcp-terraform-website-bucket-by-aditya-saxena"  # Unique bucket name
    location                     = "northamerica-northeast2"                  # Region where the bucket will be created
    force_destroy                = true                                       # Allow bucket deletion even if it contains objects
    uniform_bucket_level_access  = true                                       # Enable uniform access control for the bucket

    website {                                                                 
        main_page_suffix = "index.html"                                       # Specify the default page for the website
    }
}

# IAM Policy: Grant public read access to the bucket's objects
resource "google_storage_bucket_iam_member" "public_access" {                   
    bucket = google_storage_bucket.website.name                               # Reference the bucket name
    role   = "roles/storage.objectViewer"                                     # Grant object viewer role
    member = "allUsers"                                                       # Allow public access
}

# Upload HTML file to the bucket
resource "google_storage_bucket_object" "html_file" {                           
    name         = "index.html"                                               # Name of the HTML file in the bucket
    bucket       = google_storage_bucket.website.name                         # Reference the bucket name
    source       = "${path.module}/Website/index.html"                        # Path to the local HTML file
    content_type = "text/html"                                                # Specify the content type
}

# Upload CSS file to the bucket
resource "google_storage_bucket_object" "css_file" {                            
    name         = "style.css"                                                # Name of the CSS file in the bucket
    bucket       = google_storage_bucket.website.name                         # Reference the bucket name
    source       = "${path.module}/Website/style.css"                         # Path to the local CSS file
    content_type = "text/css"                                                 # Specify the content type
}

# Upload JavaScript file to the bucket
resource "google_storage_bucket_object" "js_file" {                             
    name         = "script.js"                                                # Name of the JavaScript file in the bucket
    bucket       = google_storage_bucket.website.name                         # Reference the bucket name
    source       = "${path.module}/Website/script.js"                         # Path to the local JavaScript file
    content_type = "application/javascript"                                   # Specify the content type
}

# Reserve a static external IP address for the load balancer
resource "google_compute_address" "external_ip" {                               
    name   = "website-external-ip"                                            # Name of the external IP address
    region = "northamerica-northeast2"                                        # Region where the IP address will be reserved
}

# Retrieve the DNS managed zone
data "google_dns_managed_zone" "managed_zone" {                                 
    name = "gcp-terraform-website-zone"                                       # Name of the DNS managed zone
}

# Create a DNS record for the website
resource "google_dns_record_set" "dns_record" {                                 
    name         = "gcp.adityasaxena.xyz."                                    # Fully qualified domain name
    type         = "A"                                                       # Record type
    ttl          = 300                                                       # Time-to-live for the DNS record
    managed_zone = data.google_dns_managed_zone.managed_zone.name            # Reference the DNS managed zone
    rrdatas      = [google_compute_address.external_ip.address]              # Use the reserved external IP address
}

# Create a backend bucket for the CDN
resource "google_compute_backend_bucket" "cdn_backend" {                        
    name        = "website-backend-bucket"                                    # Name of the backend bucket
    bucket_name = google_storage_bucket.website.name                         # Reference the storage bucket
    enable_cdn  = true                                                       # Enable CDN for the backend bucket
}

# Define a URL map for routing traffic
resource "google_compute_url_map" "url_map" {                                   
    name            = "website-url-map"                                       # Name of the URL map
    default_service = google_compute_backend_bucket.cdn_backend.id           # Default backend service

    host_rule {                                                                 
        hosts        = ["gcp.adityasaxena.xyz"]                               # Hostnames to match
        path_matcher = "default-path-matcher"                                # Path matcher name
    }

    path_matcher {                                                              
        name            = "default-path-matcher"                              # Name of the path matcher
        default_service = google_compute_backend_bucket.cdn_backend.id       # Default backend service
    }
}

# Create an HTTP proxy for the URL map
resource "google_compute_target_http_proxy" "http_proxy" {                      
    name    = "website-http-proxy"                                            # Name of the HTTP proxy
    url_map = google_compute_url_map.url_map.id                              # Reference the URL map
}

# Set up a global forwarding rule for HTTP traffic
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {       
    name                 = "website-http-forwarding-rule"                    # Name of the forwarding rule
    target               = google_compute_target_http_proxy.http_proxy.id   # Reference the HTTP proxy
    port_range           = "80"                                              # Port for HTTP traffic
    ip_address           = google_compute_address.external_ip.address       # Use the reserved external IP address
    load_balancing_scheme = "EXTERNAL"                                       # External load balancing scheme
    ip_protocol          = "TCP"                                             # Protocol for the forwarding rule
}

# Create a managed SSL certificate for HTTPS
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
    name    = "website-ssl-cert"                                             # Name of the SSL certificate
    managed {
        domains = ["gcp.adityasaxena.xyz"]                                   # Domain for the SSL certificate
    }
}

# Create an HTTPS proxy for the URL map
resource "google_compute_target_https_proxy" "https_proxy" {
    name             = "website-https-proxy"                                 # Name of the HTTPS proxy
    url_map          = google_compute_url_map.url_map.id                    # Reference the URL map
    ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id] # Reference the SSL certificate
}

# Set up a global forwarding rule for HTTPS traffic
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
    name                 = "website-https-forwarding-rule"                   # Name of the forwarding rule
    target               = google_compute_target_https_proxy.https_proxy.id # Reference the HTTPS proxy
    port_range           = "443"                                             # Port for HTTPS traffic
    ip_address           = google_compute_address.external_ip.address       # Use the reserved external IP address
    load_balancing_scheme = "EXTERNAL"                                       # External load balancing scheme
    ip_protocol          = "TCP"                                             # Protocol for the forwarding rule
}
