output "public_ip" {
  description = "Reserved public IP address of the hoocowork VM"
  value       = oci_core_public_ip.hoocowork.ip_address
}

output "hoocowork_url" {
  description = "HTTPS URL to access hoocowork (Caddy terminates TLS, reverse-proxies to localhost:8080)"
  value       = "https://${replace(oci_core_public_ip.hoocowork.ip_address, ".", "-")}.nip.io"
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i /path/to/your/ssh-private-key ubuntu@${oci_core_public_ip.hoocowork.ip_address}"
}

output "instance_ocid" {
  description = "OCID of the created compute instance"
  value       = oci_core_instance.hoocowork.id
}
