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

1. Add the environment variables from `.env.example` to the GitHub repository
   secrets, filling in any missing values from the Slack app.

1. Wait for the jobs to run every Friday.

## Configure

### Rules

#### Default rules

By default, all channels are archived after 30 days without a "real" message or
channel action. In this case "real" messages or chat actions are messages
visible to anyone in the channel that weren't sent by a bot user, except for
notifications about users joining or leaving the channel.

##### Disable defaults

If you want to disable the default rules, making archiving opt in, set the
`ARCHIVIST_DISABLE_DEFAULTS` environment variable to any value.

#### Create rule exceptions

To create an exception to the rules and prevent a channel from being archived by
the bot under any circumstances, you can specify a magic string via the
`NO_ARCHIVE_LABEL` environment variable. If you set this environment variable,
if a channel has its value in the description or topic, it will be ignored.

Bear in mind that we look for it anywhere in the description or topic, including
mid-sentence and mid-word, so be sure to use some form of delimeter to avoid
false positives.
