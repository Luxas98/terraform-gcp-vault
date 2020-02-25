resource "google_project_service" "compute-service" {
 project = "${var.project_id}"
 service = "compute.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "cloudapis-service" {
 project = "${var.project_id}"
 service = "cloudapis.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "cloudkms-service" {
 project = "${var.project_id}"
 service = "cloudkms.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "cloudresource-service" {
 project = "${var.project_id}"
 service = "cloudresourcemanager.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "cloudshell-service" {
 project = "${var.project_id}"
 service = "cloudshell.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "container-service" {
 project = "${var.project_id}"
 service = "container.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "containerreg-service" {
 project = "${var.project_id}"
 service = "containerregistry.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}

resource "google_project_service" "iam-service" {
 project = "${var.project_id}"
 service = "iam.googleapis.com"
 disable_dependent_services = false
 disable_on_destroy = false
}