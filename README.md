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
