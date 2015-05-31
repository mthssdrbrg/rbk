# rbk

[![Build Status](https://travis-ci.org/mthssdrbrg/rbk.svg?branch=master)](https://travis-ci.org/mthssdrbrg/rbk)
[![Coverage Status](https://coveralls.io/repos/mthssdrbrg/rbk/badge.svg?branch=master)](https://coveralls.io/r/mthssdrbrg/rbk?branch=master)
[![Gem Version](https://badge.fury.io/rb/rbk.svg)](http://badge.fury.io/rb/rbk)

rbk, short for "Repo BacKup", is a small tool written in Ruby that attempts to
make it easy to backup all repos belonging to an organization's GitHub
account to a specific bucket on S3.

## Installation

```shell
$ [sudo] gem install rbk
```

## Usage

The following example shows the simplest invocation of `rbk`:

```shell
$ rbk -o <organization-name> -b <s3-bucket>
```

This does however assume that the following environment variables are available:

- `GITHUB_ACCESS_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

It is also possible to specify them as arguments to `rbk`:

```shell
$ rbk -o <organization-name> -b <s3-bucket> --github-access-token=<TOKEN> --access-key-id=<KEY> --secret-access-key=<KEY>
```

See `rbk -h` for further usage:

```shell
$ rbk -h
Usage: rbk [options]
    -o, --organization=NAME          (GitHub) Organization name
    -b, --bucket=NAME                S3 bucket where to store backups
        --github-access-token=TOKEN  GitHub access token
        --access-key-id=KEY          AWS access key id
        --secret-access-key=KEY      AWS secret access key
    -h, --help                       Display this screen
```

## Copyright

© 2015 Mathias Söderberg, see LICENSE.txt (BSD 3-Clause).
