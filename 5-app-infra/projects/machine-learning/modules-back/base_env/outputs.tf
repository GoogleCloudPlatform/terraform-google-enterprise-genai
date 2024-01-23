########################
#      Composer        #
########################

output "composer" {
  value       = module.composer
  description = "Cloud Composer Environment."
}

########################
#      Metadata        #
########################

output "metadata" {
  description = "an identifier for the resource with format {{name}}"
  value       = module.metadata
}

########################
#       Bucket         #
########################
output "bucket" {
  description = "Generated unique name fort the bucket"
  value       = module.bucket
}

########################
#      TensorBoard     #
########################

output "tensorboard" {
  description = "TensorBoard object."
  value       = module.tensorboard
}
