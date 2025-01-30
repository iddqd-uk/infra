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

> [!TIP]
> To easily access the master node using SSH, you may want to add this lines to your `~/.ssh/config` file:
> ```shell
> Host iddqd-uk-master-node
>   HostName kube.iddqd.uk
>   Port <ssh-port>
>   User root
> ```

> [!NOTE]
> First, please ensure that the K8s cluster is up and running before proceeding with the following steps:
> ```shell
> # you should see the master and worker nodes
> ssh iddqd-uk-master-node kubectl get nodes
> ```

```shell
# copy the kubeconfig file to the local machine to access the cluster
scp iddqd-uk-master-node:/etc/rancher/k3s/k3s.yaml ~/.kube/iddqd

# replace the localhost address with the public IP/domain of the master node
sed -i 's#https://127.0.0.1#https://kube.iddqd.uk#g' ~/.kube/iddqd

# update the kubeconfig secret in Doppler (required for future deployments)
doppler --no-check-version secrets set --project iddqd-uk --config helm --type yaml KUBE_CONFIG < ~/.kube/iddqd
```

## Managing the Infrastructure & DNS Records

To manage the infrastructure and DNS records, ensure that `make` and `docker` are installed on your machine. The
required tools for management are listed in the [Dockerfile](Dockerfile), but since everything is containerized,
there is no need to install them locally.

Before you begin, obtain a new token (or reuse an existing one) from the [Doppler](https://www.doppler.com/)
dashboard associated with this project. Add the token to the `.env` file (you can refer to the `.env.example`
file for guidance), and you will be ready to go.

You can use all available commands in the `Makefile` to manage the infrastructure. To preview/deploy DNS records,
use `make dns-*`, and to deploy the infrastructure, use `make terraform-*`.

> [!NOTE]
> A few words about the secrets - they are stored in three locations:
>
> - **GitHub Secrets** (stores only the authorization token for Doppler)
> - **Doppler** (contains all critical secrets, including credentials for Terraform Cloud)
> - **Terraform Cloud** (stores secrets required for infrastructure deployment)
>
> To manage the infrastructure, you only need the Doppler token. This approach simplifies secrets management,
> making it more convenient. However, determining where a specific secret is stored and how to access it may not
> always be straightforward, so please keep this in mind.
