variable "save_to" {
    default = ""
}

data "archive_file" "generate_zip" {
  type        = "zip"
  output_path = (var.save_to != "" ? "${var.save_to}/lustre.zip" : "${path.module}/dist/lustre.zip")
  source_dir = "../"
  excludes    = ["terraform.tfstate", "terraform.tfvars.template", "terraform.tfvars", "provider.tf", ".terraform", "images" , "orm" , ".git"  ]
}

