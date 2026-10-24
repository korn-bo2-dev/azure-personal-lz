# azure-personal-lz

An enterprise-style [Azure Landing Zone](https://aka.ms/alz) (Cloud Adoption
Framework) in Terraform, built on the Azure Verified Modules ALZ pattern
(`Azure/avm-ptn-alz` + the ALZ reference library), sized for three
subscriptions in Australia East.

## Architecture

```
Tenant Root Group
└── alz                     Azure Landing Zones (intermediate root, ~ALZ root policies)
    ├── platform
    │   ├── management      sub-platform-001: Log Analytics, DCRs, AMA identity, TF state
    │   ├── connectivity    (empty for now: hub network comes later)
    │   ├── identity
    │   └── security
    ├── landingzones
    │   ├── corp            sub-prod-001, sub-dev-001
    │   ├── online
    │   └── local
    ├── sandbox
    └── decommissioned
```

```
bootstrap/      run once, locally: TF state storage + CI/CD identity (OIDC), in the platform sub
landing-zone/
  main.tf         ALZ management groups + policies (avm-ptn-alz), management resources (avm-ptn-alz-management)
  budgets.tf      monthly budget + alerts on each subscription
  cicd.tf         grants the CI/CD identity Owner on the `alz` management group
```

## Cost

| Item | Monthly (rough) |
|---|---|
| Management groups, policies, budgets | free |
| Log Analytics (capped at 1 GB/day, 30-day retention) | usually a few dollars; worst case ~US$90 at the cap |
| TF state storage | cents |
| Defender for Cloud paid plans | **off** (`defender_plans_enabled = false`) |
| DDoS Network Protection (~US$3,000) | **off** (policy set to DoNotEnforce) |
| Hub network / Azure Firewall (Basic ~US$300, Standard ~US$900+) | not deployed yet |

Policy assignments set to `DoNotEnforce` so they don't deploy paid features or
fail without a hub: `Deploy-MDFC-*` and `Deploy-MDEndpoints*` (until
`defender_plans_enabled = true`), `Enable-DDoS-VNET`, and `Deploy-Private-DNS-Zones`
(until connectivity exists). Everything else follows the ALZ defaults. Note
`Deploy-VM-Backup` in landing zones will create Recovery Services vaults for VMs.

## Prerequisites

- Terraform >= 1.12, Azure CLI, Git.
- Three subscriptions under the same billing account: `sub-platform-001`
  (where bootstrap ran), `sub-prod-001`, `sub-dev-001`.
- Your account must be able to manage the tenant root management group. As a
  Global Administrator: Entra ID > Properties > **Access management for Azure
  resources = Yes**, then sign out and in again (`az logout; az login`). You
  can turn it off again after the first apply.

## First-time deployment

```sh
# bootstrap (already done if rg-tfstate exists)
cd bootstrap && terraform init && terraform apply

# landing zone
cd ../landing-zone
cp terraform.tfvars.example terraform.tfvars   # fill in the three subscription IDs + email
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=sttfstate<suffix>" \
  -backend-config="container_name=tfstate"
terraform plan
terraform apply
```

The first apply creates several hundred resources (policy definitions,
assignments, role assignments) and can take 20-40 minutes. If it fails on a
transient Azure error, run `terraform apply` again.

## GitHub Actions

`.github/workflows/terraform.yml` runs **validate** on every PR/push, **plan**
on PRs and **apply** on merge to `main` (in the `prod` environment). Plan and
apply are skipped until these repository **variables** exist (Settings >
Secrets and variables > Actions > Variables; none are secrets):

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | bootstrap output `cicd_client_id` |
| `AZURE_TENANT_ID` | bootstrap output `tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | platform subscription ID |
| `PROD_SUBSCRIPTION_ID` | prod subscription ID |
| `DEV_SUBSCRIPTION_ID` | dev subscription ID |
| `NAME_SUFFIX` | bootstrap `name_suffix` |
| `SECURITY_CONTACT_EMAIL` | your email |

Also create a `prod` environment (Settings > Environments) with yourself as a
required reviewer.

## Next steps

- **Connectivity:** hub VNet + Azure Firewall (or Virtual WAN) and private DNS
  zones in the platform (or a dedicated connectivity) subscription, using the AVM ALZ connectivity pattern modules.
- **Workloads:** spoke VNets and resources in the prod/dev subscriptions.
