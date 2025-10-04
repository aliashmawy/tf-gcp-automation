resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_name}-lb-ip"
  project = var.project_id
}

resource "google_compute_url_map" "default" {
  name            = "${var.project_name}-url-map"
  project = var.project_id
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_backend_service" "default" {
  name                  = "${var.project_name}-backend"
  project = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  connection_draining_timeout_sec = 0

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.project_name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.project_name}-forwarding-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.lb_ip.address
  port_range = "80"
  target     = google_compute_target_http_proxy.default.self_link
}

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.project_name}-cloud-run-neg"
  region                = var.region
  project = var.project_id
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service_name
  }
}