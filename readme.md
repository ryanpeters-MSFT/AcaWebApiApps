# Azure Container Apps Deployments

This example deploys a web and API application into an Azure Container Apps environment. The application environment is using the `--internal-only` flag which limits ingress scope to the VNET/subnet. 

## Notes/Observations
- This example creates a private DNS zone, which is required for the VM to resolve the load balancer ingress IP for the container app environment
- The `--ingress 'internal'` flag on the API application defines that its ingress is only accessible from within the container app environment (not the VNET).
- The `--ingress 'external'` flag on the API application defines that its ingress is accessible from within the VNET (as per `--internal-only` on the environment).