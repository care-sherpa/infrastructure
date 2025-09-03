output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = module.networking.network_self_link
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.networking.subnet_name
}

output "subnet_self_link" {
  description = "Self link of the subnet"
  value       = module.networking.subnet_self_link
}