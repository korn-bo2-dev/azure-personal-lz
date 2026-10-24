# azure-personal-lz

A personal-scale Azure landing zone in Terraform: one subscription, a few
guardrails, and one of each workload (VM, storage, Key Vault, free Azure SQL)
on a basic network.

## Layout

```
bootstrap/      run once, locally: Terraform state storage + CI/CD identity (OIDC)
landing-zone/   everything else, state stored remotely
  governance.tf     mg-personal, policies (allowed region, no public IPs on NICs), budget alerts
  platform.tf       rg-platform: Log Analytics (0.5 GB/day cap), activity log export
  network.tf        rg-network: VNet 10.10.0.0/16, snet-vm, snet-pe, NSGs, Bastion Developer (free)
  compute.tf        rg-workload: Ubuntu 24.04 VM (B1s, no public IP, 23:00 auto-shutdown)
  data-services.tf  storage account, Key Vault (RBAC), Azure SQL free offer (Entra ID auth only)
```

## Expected cost

Close to zero on a new account (B1s is in the 12-month free offer). The SQL
database uses the free offer and auto-pauses when the monthly free limit is
used, so it never bills. Main paid items after the free year: the VM (~$8/mo
if left on 24/7) and its disk (~$1.50/mo). The budget alert defaults to 30.

## First-time setup

Prereqs: Terraform >= 1.9, Azure CLI, `az login` as the subscription Owner.

```sh
# 1. Bootstrap (local state)
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in, never commit
terraform init && terraform apply

# 2. Landing zone (remote state)
cd ../landing-zone
cp backend.hcl.example backend.hcl             # use the bootstrap output
cp terraform.tfvars.example terraform.tfvars   # fill in, never commit
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Run the first landing-zone apply yourself: creating the management group and
moving the subscription needs your own tenant permissions. After that, grant
the CI/CD identity Owner on `mg-personal` and let the pipeline take over:

```sh
az role assignment create --assignee <cicd_client_id> --role Owner \
  --scope /providers/Microsoft.Management/managementGroups/mg-personal
```

## GitHub Actions

`.github/workflows/terraform.yml` runs:

- **validate** on every PR and push: `fmt -check` and `validate` for both roots. Needs no Azure access.
- **plan** on PRs, with the plan in the job summary.
- **apply** on merge to `main`, in the `prod` environment.

Plan and apply are skipped until these exist. None of them are secrets, so
they are repository **variables** (Settings > Secrets and variables > Actions > Variables):

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | bootstrap output `cicd_client_id` |
| `AZURE_TENANT_ID` | bootstrap output `tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | your subscription ID |
| `NAME_SUFFIX` | same as in tfvars |
| `BUDGET_CONTACT_EMAILS` | HCL list, e.g. `["you@example.com"]` |
| `VM_ADMIN_SSH_PUBLIC_KEY` | your `.pub` key contents |
| `SQL_ADMIN_LOGIN` | your UPN |
| `SQL_ADMIN_OBJECT_ID` | `az ad signed-in-user show --query id -o tsv` |
| `ALLOWED_CLIENT_IPS` | optional, e.g. `["203.0.113.10"]` |

Also create a `prod` environment (Settings > Environments) and add yourself as
a required reviewer, so every apply waits for your click.

## Connecting to things

- VM: Portal > vm-personal > Connect > Bastion, SSH with your key.
- SQL: sign in with your Entra ID account (add your home IP to
  `allowed_client_ips`), or from the VM via the service endpoint.
- Storage / Key Vault: Entra ID RBAC, already granted to you and the VM.

## Later hardening (optional, costs a little)

- Private endpoints for SQL, storage and Key Vault in `snet-pe`, plus private DNS zones.
- Disable shared keys on storage accounts (`shared_access_key_enabled = false`).
- Defender for Cloud plans, diagnostic settings per resource.
