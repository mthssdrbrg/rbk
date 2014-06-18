# rbk

rbk, short for "Repo BacKup", is a small tool written in Ruby that attempts to
make it easy to backup __ALL__ repos belonging to an organization's GitHub
account to a specific bucket on S3.

## Installation

```
[sudo] gem install rbk
```

## Usage

The following example shows the easiest invocation of `rbk`:

```
rbk -o <organization-name> -b <s3-bucket>
```

This does however assume that the following environment variables are available:

- `GITHUB_ACCESS_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

It is also possible to specify them as command line arguments:

```
rbk -o <organization-name> -b <s3-bucket> --github-access-token=<TOKEN> --access-key-id=<KEY> --secret-access-key=<KEY>
```

See `rbk -h` for further usage:

```
Usage: rbk [options]
    -o, --organization=NAME          (GitHub) Organization name
    -b, --bucket=NAME                S3 bucket where to store backups
        --github-access-token=TOKEN  GitHub access token
        --access-key-id=KEY          AWS access key id
        --secret-access-key=KEY      AWS secret access key
    -h, --help                       Display this screen
```
