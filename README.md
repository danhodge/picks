picks
=====

Usage

```
nohup bundle exec foreman start&
```

Add a Migration

``` bash
bundle exec rake db:create_migration NAME=create_table
```

Setup

Load the CBS sports schedule for the current season into the DB

``` bash
bundle exec rake scrape:schedule
```

Load the Family Fun schedule for the current season into the DB

``` bash
bundle exec rake scrape:family_fun_schedule
```

Load the CBS sports point spreads for the current season into the DB

``` bash
bundle exec rake scrape:lines
```

Export the participants

``` bash
# re-run this after the games start to download all of the participants into the DB
bundle exec rake scrape:family_fun_schedule

# run this to export the participants JSON to S3
AWS_ACCESS_KEY_ID=<> AWS_SECRET_ACCESS_KEY=<> bundle exec rake scrape:export_participants
```

Update the scores

``` bash
AWS_ACCESS_KEY_ID=<> AWS_SECRET_ACCESS_KEY=<> bundle exec rake scrape:update_scores
```

### sqlite

``` bash
# how to exit the sqlite3 CLI gracefully
sqlite> .quit

# how to make a copy of the existing DB
sqlite> .backup main backup.sqlite
```
