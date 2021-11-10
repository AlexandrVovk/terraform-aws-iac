provider "aws" {
  profile    = "default"
  region     = var.region-master
  access_key = var.access_key
  secret_key = var.secret_key
  alias      = "region-master"

}

provider "aws" {
  profile    = "default"
  region     = var.region-worker
  access_key = var.access_key
  secret_key = var.secret_key
  alias      = "region-worker"
}
