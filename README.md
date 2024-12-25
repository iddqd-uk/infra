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

[terraform-cloud]:https://app.terraform.io/app/iddqd-uk/workspaces/infra/

The following manual actions are required after the infrastructure is created:

```shell
# Copy the kubeconfig file to the local machine for cluster access
scp iddqd-uk-master-node:/etc/rancher/k3s/k3s.yaml ~/k3s.yaml
```
