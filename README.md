# Mealie Backup Container

This project provides a lightweight Docker container that automatically:

1. Triggers a new Mealie backup via the Mealie admin API  
2. Fetches the list of existing backups  
3. Identifies the most recent backup  
4. Retrieves the `fileToken`  
5. Downloads the backup ZIP file  

Backups are saved inside the container at `/app/backups`, and can be mounted locally.

---

## Requirements

- Docker or Podman
- A Mealie API token (Admin → Settings → API Tokens)

---

##  Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env