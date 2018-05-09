variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable private_key_path {
  description = "Path to the private key used to connect to instance"
}

variable project {
  description = "GCP project"
}

variable region {
  description = "GCE Region"
}

variable zone {
  description = "GCE Zone"
}

variable machine_type {
  description = "VM type"
}

variable host_image {
  description = "Disk image for reddit app"
  default     = "ubuntu-1604-xenial"
}

variable vm_qty {
  description = "Number of VMs to create"
  default     = "1"
}
