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

Setup (run these tasks in the following order)

Load the CBS sports schedule for the current season into the DB

Load the Family Fun schedule for the current season into the DB

``` bash
bundle exec rake scrape:family_fun_schedule
```

``` bash
bundle exec rake scrape:schedule
```

Load the CBS sports point spreads for the current season into the DB

``` bash
bundle exec rake scrape:cbs_lines
```

Generate Blank Picks CSV

```bash
bundle exec rake picks:generate_csv
```

Generate Picks CSV with Choices

```bash
bundle exec rake "picks:generate_choices[randomness_score]"
```

Create User

```bash
bundle exec rake "user:create[<email>,<name>,<nickname>,<phone_number>]"
```

Submit Picks

```bash
bundle exec rake "picks:generate_and_submit[<csv_path>,<tie_breaker>,<nickname>,<password>]"
```

Deploy

1. Copy prod db
2. Re-run 1-3 with RACK_ENV=production

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