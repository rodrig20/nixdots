# agenix rules: recipients allowed to decrypt each .age in this repo (discovered by the agenix CLI; secrets.nix is deprecated).
# Add a secret: line below + `echo VALUE | nix run github:ryantm/agenix -- -e secrets/NAME.age` + age.secrets."NAME" in the consuming HM module.
let
  # Dedicated agenix key (~/.ssh/id_ed25519_agenix), not the GitHub key.
  age = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+4H8IhyFunXFKt5W+PxJFNXm8Ngy0hS8f4elBYroeS";
in
{ } # No secrets yet.
