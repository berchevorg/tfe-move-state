# tfe-move-state

This repo is a guideline how to **move the state locally** and after that to move the same state to TFE using **atlas backend**

## Files
- `main/main.tf` - terraform configuration file
- `random_pet/module.tf` - terraform module file to which we will move the state locally

## Requirements
- Terraform installed. If you do not have Terraform installed on your computer, install it from [here](https://learn.hashicorp.com/terraform/getting-started/install.html)
- Registration to [TFE](https://app.terraform.io) (recomended is to use user, the same as github)
- You need to crete [organization](https://www.terraform.io/docs/enterprise/getting-started/access.html#creating-an-organization)
- Generate [token](https://www.terraform.io/docs/enterprise/users-teams-organizations/users.html#api-tokens)

## Instructions

**Part 1: Creating terraform project with random_pet and null_resource together**

- Create a github repo
- Clone it locally to your computer: `git clone git@github.com:your_github_organization/name_of your_repo.git`
- Create directory called **main** and add **main.tf**, file inside, with following content:
```
resource "random_pet" "name" {
 length    = "4"
 separator = "-"
}

resource "null_resource" "hello" {
  provisioner "local-exec" {
    command = "echo Hello ${random_pet.name.id}"
  }
}
```
- Into **main** directory type: `terraform init`
- Into **main** directory type: `terraform apply`, now you have some resources created. In my case:
```
random_pet.name: Creation complete after 0s (ID: legally-widely-internal-stud)
null_resource.hello: Creating...
null_resource.hello: Provisioning with 'local-exec'...
null_resource.hello (local-exec): Executing: ["/bin/sh" "-c" "echo Hello legally-widely-internal-stud"]
null_resource.hello (local-exec): Hello legally-widely-internal-stud
null_resource.hello: Creation complete after 0s (ID: 2231687696833739750)

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

**Part 2: Separate random_pet (as module) and move the state without destroying of created resources**

- Create directory **random_pet** in the same directory as **main**
- Into **random_pet** add **module.tf** file with content:
```
resource "random_pet" "name" {
  length    = "4"
  separator = "-"
}

output "out" {
  value = "${random_pet.name.id}"
}
```
- Edit **main/main.tf** file as follows:
```
module "move_state" {
  source = "../random_pet"
}

resource "null_resource" "hello" {
  provisioner "local-exec" {
    command = "echo Hello ${module.move_state.out}"
  }
}
```
- Into **main** directory type: `terraform state mv random_pet.name module.move_state`, in order to move the state
- Into **main** directory type: `terraform init`
- Into **main** directory type: `terraform apply`, output should be like this:
```
random_pet.name: Refreshing state... (ID: legally-widely-internal-stud)
null_resource.hello: Refreshing state... (ID: 2231687696833739750)

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```
- This means that state is moved successfully

**Part 3: Move the state to TFE**

- Create new workspace in your organization in TFE:
  - Click on **Workspaces**
  - Click on **New Workspace**
  - Type **Name** (type the same as repo name)
  - For **Source** choose **None**
  - Click **Create Workspace**
- Create file that ends on **.env** (name does not matters. In my case **georgiman.env**) with following content (replace the value of ATLAS_TOKEN with the token generated in **Requirements** section):
```
export ATLAS_TOKEN=xxxxxxxx.atlasv1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
- Type **source your_file.env**
- Edit **main/main.tf** as follows:
```
terraform {
  backend "atlas" {
    name    = "your_organization/name_of_your_repo"
  }
}

module "move_state" {
  source = "../random_pet"
}

resource "null_resource" "hello" {
  provisioner "local-exec" {
    command = "echo Hello ${module.move_state.out}"
  }
}

```
- Type **terraform init** and when prompted for answer, type **yes** in order to copy the state to your workspace.
- Type **terraform apply**. Output should be like this:
```
random_pet.name: Refreshing state... (ID: legally-widely-internal-stud)
null_resource.hello: Refreshing state... (ID: 2231687696833739750)

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```
- Type: **terraform destroy** will destroy your current project and state

After all, your repo should look like mine
