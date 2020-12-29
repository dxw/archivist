# Archivist

A Slack bot to automate archiving channels based on activity.

Inspired by
[Symantec/slack-autoarchive](https://github.com/Symantec/slack-autoarchive).

## Set up

1. Fork this repository.

1. Create a new Slack app.

1. Create a bot user with the following permissions:

   - `channels:read`
   - `channels:join`
   - `channels:history`
   - `channels:manage`
   - `chat:write`

1. Add the environment variables from `.env.example` to the GitHub repository
   secrets, filling in any missing values from the Slack app.

1. Wait for the jobs to run every Friday.

## Configure

### Schedule

The schedule for running the rules is determined by the crontab expression in
[`.github/workflows/cron:archive_channels.yml`](.github/workflows/cron:archive_channels.yml).
To change the schedule, modify that expression.

### Rules

#### Default rules

By default, all channels are warned after 30 days without a "real" message or
channel action. If the channel is still stale after ~7 days, the channel is
archived.

In this case "real" messages or chat actions are messages visible to anyone in
the channel that weren't sent by Slackbot, except for notifications about users
joining or leaving the channel.

##### Disable defaults

If you want to disable the default rules, making archiving opt in, set the
`ARCHIVIST_DISABLE_DEFAULTS` environment variable to any value.

#### Create rules

To create additional rules, set the `ARCHIVIST_RULES` environment variable to a
semicolon (`;`) separated list of rules.

Rules, in turn, are a comma-separated list of key-value pairs. For example,
`prefix=chat-,days=90` means "Wait at least 90 days before archiving inactive
channels with names starting with `#chat-`".

All whitespace is ignored.

The available arguments are:

- `prefix` (string - **required**)

  The channel name prefix this rule applies to. If more than one rule could
  apply to the same channel, an exception will be raised.

- `days` (integer)

  The minimum number of days a channel must be inactive before being warned.

- `skip` (boolean)

  Whether or not to skip all channels with the given prefix. This is useful when
  channels should be monitored by default, but some subset of them should be
  excluded.

  `skip` overrides all other arguments.

### Activity report

Archivist can be configured to report the actions it took. To enable that
behaviour, set `ARCHIVIST_REPORT_CHANNEL_ID` to the ID of the channel you want
the report to be posted to.
