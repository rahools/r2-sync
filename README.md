# R2 Sync Script

A bash script to sync files from a local directory to Cloudflare R2.

## Prerequisites

1. AWS CLI installed
   ```bash
   pip install awscli
   ```

2. Cloudflare R2 credentials configured
   You can either:
   - Use command line arguments (`--access-key` and `--secret-key`)
   - Configure AWS CLI profile
     ```bash
     aws configure --profile r2
     ```
     When prompted, enter:
     - Access Key ID: Your Cloudflare R2 Access Key
     - Secret Access Key: Your Cloudflare R2 Secret Key
     - Default region name: auto
     - Default output format: json

## Usage

```bash
./r2-sync.sh --account-id ACCOUNT_ID --bucket BUCKET_NAME --path /path/to/source
```

Or using short options:

```bash
./r2-sync.sh -a ACCOUNT_ID -b BUCKET_NAME -p /path/to/source
```

### Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--account-id` | `-a` | Cloudflare Account ID for R2 |
| `--bucket` | `-b` | R2 Bucket name |
| `--path` | `-p` | Source directory path to sync |
| `--log-file` | `-l` | Log file path (default: `/var/log/r2-sync.log`) |
| `--access-key` | `-k` | R2 Access Key (optional) |
| `--secret-key` | `-s` | R2 Secret Key (optional) |
| `--help` | `-h` | Show help message |

## Example

```bash
./r2-sync.sh --account-id abc123 --bucket my-backup --path /data/files
```

With credentials:

```bash
./r2-sync.sh -a abc123 -b my-backup -p /data/files -k YOUR_ACCESS_KEY -s YOUR_SECRET_KEY
```

## Setting up as a Cron Job

1. Make the script executable:
   ```bash
   chmod +x r2-sync.sh
   ```

2. Edit the crontab:
   ```bash
   crontab -e
   ```

3. Add a line to run the script daily (example: run at 2 AM):
   ```
   0 2 * * * /full/path/to/r2-sync.sh --account-id abc123 --bucket my-backup --path /data/files
   ```

## Notes

- The script uses the AWS CLI's `s3 sync` command, which only uploads new or modified files
- If you want to prevent overwriting existing files, add `--no-overwrite-existing` to the `aws_opts` variable in the script
- Consider enabling versioning on your R2 bucket to maintain file history
- Make sure the user running the cron job has permission to access the source directory and write to the log file 