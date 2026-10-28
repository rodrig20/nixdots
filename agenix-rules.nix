# agenix rules: recipients allowed to decrypt each .age in this repo (discovered by the agenix CLI; secrets.nix is deprecated).
# Add a secret: line below + `echo VALUE | nix run github:ryantm/agenix -- -e secrets/NAME.age` + age.secrets."NAME" in the consuming HM module.
let
  # Agenix SSH key (~/.ssh/id_ed25519_agenix).
  age = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+4H8IhyFunXFKt5W+PxJFNXm8Ngy0hS8f4elBYroeS";
in
{
  "secrets/rclone-gdrive-client-secret.age".publicKeys = [ age ];
  "secrets/rclone-gdrive-token.age".publicKeys = [ age ];
  "secrets/openrouter-api-key.age".publicKeys = [ age ];
}
