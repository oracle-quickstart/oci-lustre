# oci-lustre
These are Terraform modules that deploy [Lustre](http://lustre.org/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).

## High Level Architecture 
![](./images/Lustre_OCI_High_Level_Arch.png)

## Prerequisites
First off you'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

## Clone the Terraform template
Now, you'll want a local copy of this repo.  You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-lustre.git
    cd oci-lustre/terraform
    ls

## Update variables.tf file (optional)
This is optional, but you can update the variables.tf to change compute shapes, block volumes, etc. 

## Deployment and Post Deployment
Deploy using standard Terraform commands

        terraform init
        terraform plan
        terraform apply

![](./images/Single-Node-TF-apply.PNG)
