fs_name="Lustre"
fs_type="Persistent"
fs_workload_type="Large Files"


persistent_storage_server_shape="VM.Standard2.2"
storage_server_node_count=2
storage_tier_1_disk_count=4
storage_tier_1_disk_size=50
storage_tier_1_disk_perf_tier="Balanced"

management_server_shape="VM.Standard2.1"

metadata_server_node_count=2
persistent_metadata_server_shape="VM.Standard2.2"
metadata_server_disk_count=1
metadata_server_disk_size=50

create_compute_nodes=true
# Client nodes variables
client_node_shape="VM.Standard2.2"
client_node_count=1


# Valid values for Availability Domain: 0,1,2, if the region has 3 ADs, else only 0.
ad_number=2

# uses OL77_3.10.0-1062.9.1.el7.x86_64 image.  (non-UEK)
use_marketplace_image=false


#scratch_metadata_server_shape
#metadata_server_node_count=1
#scratch_metadata_server_shape
#metadata_server_disk_count=2
#metadata_server_disk_size=55

#scratch_storage_server_shape="VM.DenseIO2.24"
#storage_server_node_count=2
# Below variables, not applicable for Scratch
#storage_tier_1_disk_count=2
#storage_tier_1_disk_size=60


/* RHCK OL79 image
*/

image = {
  eu-frankfurt-1= "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaanwv3rcimife7nmc5fg76n5e5mrqi2npgbyd73vw3vzvgvfgbsaza"
}
