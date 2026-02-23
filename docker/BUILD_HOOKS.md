# Build Hook System

The Dockerfile supports optional local customizations via `build-local.sh`.

## How It Works

1. Create a `build-local.sh` script in the `docker/` directory
2. Add your custom installation commands (work-specific tools, packages, etc.)
3. The script runs during Docker build if present
4. The file is gitignored and won't be committed to the public repo

## Example Use Cases

- Install private Python packages
- Add company-specific CLI tools
- Configure work environment settings
- Install additional development dependencies

## Example Script

See `build-local.sh.example` for a template. Copy and modify it:

```bash
cd docker/
cp build-local.sh.example build-local.sh
# Edit build-local.sh with your customizations
chmod +x build-local.sh
```

## Creating Your Script

Copy the example and customize it:

```bash
cd docker/
cp build-local.sh.example build-local.sh
# Edit build-local.sh with your customizations
chmod +x build-local.sh
```

Your `build-local.sh` stays local and never gets committed to the repository.

## Security Notes

- Never commit `build-local.sh` to public repos
- Don't include secrets or tokens in the script
- Use environment variables or mounted volumes for sensitive data
- The script runs as root during build - use with caution
