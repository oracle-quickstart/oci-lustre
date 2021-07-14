variable "save_to" {
    default = ""
}

data "archive_file" "generate_zip" {
  type        = "zip"
  output_path = (var.save_to != "" ? "${var.save_to}/lustre.zip" : "${path.module}/dist/lustre.zip")
  source_dir = "../"
  excludes    = [".gitignore" , "terraform.tfstate", "terraform.tfvars.template", "terraform.tfvars", ".terraform", "images" , "orm" , ".git" , "RM_Mktpce_public_oci_lustre.xcworkspace" , "scripts/lnet_selftest_wrapper.sh"  , "scripts/passwordless_ssh.sh" , "terraform.tfstate.backup", "oci-lustre-redesign.xcworkspace", "terraform.tfstate.backup" , "local_only" ,  "terraform.tfstate.has_gpu48_temp"  ]
}

# "provider.tf"


