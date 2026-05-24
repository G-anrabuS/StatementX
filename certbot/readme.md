# StatementX SSL Certbot Directories

This directory holds SSL certificates and dynamic Let's Encrypt validation files.
- `certbot/www`: Mounted inside Nginx at `/var/www/certbot` for ACME webroot verification challenges.
- `certbot/conf`: Mounted inside Nginx at `/etc/letsencrypt` to hold production certificates.

To generate certificates:
```bash
docker run -it --rm --name certbot \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot -d statementxapp.duckdns.org --email your-email@gmail.com --agree-tos --no-eff-email
```
