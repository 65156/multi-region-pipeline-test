# resource "null_resource" "example" {
#   # Using triggers to force execution on every apply
#   triggers = {
#     always_run = timestamp()
#   }
#   provisioner "local-exec" {
#     command = "echo This is a test resource - 1a"
#   }
# }

