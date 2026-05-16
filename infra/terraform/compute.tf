data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_22_04" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "hoocowork" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_index].name
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.A1.Flex"
  display_name        = var.instance_display_name

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_22_04.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = false
    hostname_label   = "hoocowork"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = filebase64("${path.module}/../scripts/setup-vm.sh")
  }

  preserve_boot_volume = false
}

data "oci_core_vnic_attachments" "instance" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.hoocowork.id
}

data "oci_core_vnic" "primary" {
  vnic_id = data.oci_core_vnic_attachments.instance.vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "primary" {
  vnic_id = data.oci_core_vnic.primary.id
}

resource "oci_core_public_ip" "hoocowork" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.instance_display_name}-ip"
  private_ip_id  = data.oci_core_private_ips.primary.private_ips[0].id
}
