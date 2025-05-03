variable "DOCKERHUB_REPO" {
  default = "aykutmursalo"
}

variable "DOCKERHUB_IMG" {
  default = "hidream-inference"
}

variable "RELEASE_VERSION" {
  default = "latest"
}

group "default" {
  targets = ["final"]
}

target "final" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "final"
  platforms  = ["linux/amd64"]
  tags       = [
    "${DOCKERHUB_REPO}/${DOCKERHUB_IMG}:${RELEASE_VERSION}",
    "${DOCKERHUB_REPO}/${DOCKERHUB_IMG}:latest"
  ]
}
