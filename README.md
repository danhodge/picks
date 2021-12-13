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
