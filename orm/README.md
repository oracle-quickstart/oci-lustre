# Deploy Lustre using Resource Manager Service
You can also deploy [Lustre](http://lustre.org/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure) using [Resource Manager Servic](https://docs.cloud.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) in OCI console or via OCI CLI.  See below for deployment steps.  


## Deployment Steps


  1. Check if the dist folder has a Terraform Configuration (.zip) file. If yes, you can download it locally and create a Resource Manager Stack via console/CLI using steps documented [here](https://docs.cloud.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/samplecomputeinstance.htm#build).
 
  2. If the Terraform Configuration (.zip) file, does not exist,  you can generate the zip file using the steps below. 


	git clone https://github.com/oracle-quickstart/oci-lustre.git
        cd oci-lustre/orm 
        terraform init     
        terraform apply

  3. You should now see a zip file in the dist/ folder. 


