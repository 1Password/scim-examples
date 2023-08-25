# Overlays

Contained here are overlays to customize and configure 1Password SCIM Bridge.

- `letsencrypt` contains the patches necessary for the default option of utilizing Let's
Encrypt to manage the TLS certificate for the SCIM bridge.
- `workspace` contains the patches necessary to configure the SCIM bridge for use with
Google Workspace as the identity provider.
- `self-managed-tls` contains what is needed to bring your own TLS certificate and
private key.

`deploy` is where your specific selections will be chosen and used as the deployment.