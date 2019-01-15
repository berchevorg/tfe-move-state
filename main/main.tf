terraform {
  backend "atlas" {
    name    = "berchevorg/tfe-move-state"
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
