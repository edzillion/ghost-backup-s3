# ghost-backup-s3

[ghost-backup-s3] is a simple, automated, backup (and restore) [docker] container for a [ghost] blog. It supports ghost configured with either sqlite or mysql. 
> the mysql implementation is currently untested.

By default it will create a backup of the ghost content files (images, themes, apps, config.js) and the database (actual posts) daily.

Inspired by [ghost-backup] and [docker-s3-volume] (thanks y'all!)

**Note:** default behaviour is only to backup (on a schedule and when the container is shut down). To enable restore, you need to set `BACKUP_ONLY=true`
> **Warning** `BACKUP_ONLY=false` will overwrite the current ghost installation. This is so that we can automate server provisioning scripts to restore ghost fully on boot.

### Quick Start

First create your s3 bucket. Take note of the region and add it to the `AWS_DEFAULT_REGION` environment variable. Turn on versioning and you can leave everything else on defaults.

> **Recommended** To limit the amount of backups you keep, (and $$$ to Lord Bezos) go to AWS s3 console and select your bucket. Click on _Management_ > _Add lifecycle rule_ > add rule name like 'File Expire Rule' > _Next_ > _Next_ (again) > Then edit settings as in image below

![add bucket lifecycle rule](https://raw.githubusercontent.com/edzillion/ghost-backup-s3/master/readme_screenshot_1.png)

Create and data volume to be shared by ghost-backup-s3 and ghost:

`docker volume create ghost_data`

Run ghost on port 80 and set it to use the ghost_data volume:

`docker run -d --name blog -v ghost_data:/var/lib/ghost/content -p 80:2368 ghost`

Then run ghost-backup-s3 and link it to the same volume, replacing `s3://your-bucket-here/folder` with your s3 bucket:

`docker run -d --name ghost-backup-s3 -v ghost_data:/data edzillion/ghost-backup-s3 s3://your-bucket-here/folder`

That's it! This will create and run a container named 'ghost-backup-s3' which will backup your files and db to s3 every day.

### Advanced Configuration
ghost-backup has a number of options which can be configured as you need. 

| Environment Variable  | Default       | Meaning           |
| --------------------- | ------------- | ----------------- | 
| BACKUP_INTERVAL       | "1d"   | interval (s, m, h or d as the suffix)|
| AWS_DEFAULT_REGION       | "eu-central-1"    | **Note:** must be same as s3 bucket|
| BACKUP_ONLY  | true            | Will disable the initial restore|

For example, if you wanted to backup every 8 hours to the s3 bucket located in the `us-east-1` region called `us-east-1-bucket` and overwrite the current ghost installation:

`docker run --name ghost-backup-s3 -d -v ghost_data:/data -e BACKUP_INTERVAL=8h -e AWS_DEFAULT_REGION=us-east-1 -e BACKUP_ONLY=false edzillion/ghost-backup-s3 s3://us-east-1-bucket/folder`

> This example is for Ghost using sqlite. If you're using mysql/mariadb just add the linked mysql containers as described above.

### Other Info
When using sqlite, the backup/restore is handled using the [command line shell] of the [online backup API].

When using mysql/mariadb, the backup/restore is handled using mysqldump. You should use InnoDB tables for [online backup].

 [ghost-backup-s3]: https://github.com/edzillion/ghost-backup-s3
 [docker]: https://www.docker.com/
 [ghost]: https://ghost.org/
 [ghost-backup]: https://github.com/bennetimo/ghost-backup
 [docker-s3-volume]: https://github.com/elementar/docker-s3-volume
 [configuration]: http://support.ghost.org/config/#database
 [mariadb]: https://hub.docker.com/_/mariadb/
 [command line shell]: https://www.sqlite.org/cli.html
 [online backup API]: https://www.sqlite.org/backup.html
 [online backup]: https://dev.mysql.com/doc/refman/5.5/en/mysqldump.html