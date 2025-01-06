# Azure Container Apps Deployments

This example deploys a web and API application into an Azure Container Apps environment. The "internal" application environment is using the `--internal-only` flag which limits ingress scope to the VNET/subnet, while the "external" option allows for the web URL to be publically accessible. 

## Examples

There are two examples available:

- **External** - Deploys a web and API application where the web application is publically accessible and the API is internal from only within the environment.
- **Internal** - Deploys a web and API application where the web application is publically accessible and the API is internal from only within the environment.

## Notes/Observations
- This example creates a private DNS zone, which is required for the VM to resolve the load balancer ingress IP for the container app environment
- The `--ingress 'internal'` flag on the API application defines that its ingress is only accessible from within the container app environment (not the VNET).
- The `--ingress 'external'` flag on the API application defines that its ingress is accessible from within the VNET (as per `--internal-only` on the environment).