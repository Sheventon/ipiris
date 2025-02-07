
variable "yc_token" {
  description = "Yandex cloud token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex cloud id"
  type        = string
  sensitive   = true
}

variable "yc_folder_id" {
  description = "Yandex cloud folder id"
  type        = string
  sensitive   = true
}

variable "yc_zone" {
  description = "Yandex cloud zone"
  type        = string
  default     = "ru-central1-a"
}