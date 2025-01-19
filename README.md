# 🏗 Infrastructure

## DNS records

DNS records are managed using the DNScontrol tool. The configuration is stored in the [configuration file][dnsconfig],
which contains all the records for the domain.

[dnsconfig]:dns/dnsconfig.js

> [!NOTE]
> Any records created manually via the Cloudflare web interface will be removed or overwritten by the DNScontrol tool.

To apply the changes to the Cloudflare DNS server, trigger the corresponding GitHub Action from the GitHub Actions page.

## Servers, Networking, and More

The infrastructure is managed with Terraform, and all configurations are stored in the [terraform](terraform)
directory. After making changes, you can apply the updated Terraform configuration by running the corresponding
GitHub Action.

The state and variables are managed in [Terraform Cloud][terraform-cloud], eliminating the need to handle the state
file or secrets manually.

Before deploying the infrastructure, ensure the following resources are available in the Hetzner Cloud:

- A public SSH key (its ID is required for `owner-key-id`)
- Public IPv4 and IPv6 addresses (`primary-ips.ipv4-id` and `primary-ips.ipv6-id`)
- A volume to mount to the master node (`volumes.master-node-id`)

These resources are not managed by Terraform to prevent accidental deletion due to human error.

[terraform-cloud]:https://app.terraform.io/app/iddqd-uk/workspaces/infra/

The following manual actions are required after the infrastructure is created:

```shell
# copy the kubeconfig file to the local machine to access the cluster
scp iddqd-uk-master-node:/etc/rancher/k3s/k3s.yaml ~/.kube/iddqd

# replace the localhost address with the public IP address
sed -i 's#https://127.0.0.1#https://78.47.216.176#g' ~/.kube/iddqd
```
