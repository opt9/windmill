# osquery-tls-server

## Why do you want this

If you're running `osquery` you may want an easy-to-manage way of delivering
configuration file updates to the osquery process on your running servers. This
software provides a TLS server that delivers configuration to osquery and also
allows you to roll out new configs to small samples of servers to make sure that
the new config does not cause problem before deploying to all machines.

## Getting started

The quickest way to get started is to click this button down here.

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

If you deploy to Heroku using the button above, you'll need to view the
environment variables to get the random secret that was generated for the NODE_ENROLL_SECRET
used by the windmill application.

## Not using Heroku

For security purposes, the software requires new endpoints to supply a shared
secret which is found in an environment variable named `NODE_ENROLL_SECRET`.
While  not completely necessary, you may want to set a random in an environment
variabled  named `COOKIE_SECRET`. If you do not set `COOKIE_SECRET` then users
will have to  re-authenticate every time you restart the server. Finally, since
this was written by a Heroku employee intending to run this on Heroku if you run
the app in production the code expects an environment variable named
DATABASE_URL with a url pointing to a postgres database. Absent that variable,
production mode will fall back to a postgres database on localhost.

To run the server run the following commands. The first two commands should only
need to be run once

```
bundle install
rake db:setup
ruby server.rb
```

If you want to use the faster puma server you can run the app with this command:

```
puma -C puma.rb
```

## Compatibility

This has been tested most recently against osquery version 1.6.0

## Configuring osqueryd

The easiest way to configure osqueryd is to put your command line options
into a flag file. By default on linux systems, osqueryd will look for
`/etc/osquery/osquery.flags` You need to have the following options set there
for osqueryd to look to your server.

```
--tls_hostname=dns.name.of.your.server.with.no.https.on.the.front.com
--config_plugin=tls
--config_tls_endpoint=/api/config
--config_tls_refresh=14400
--enroll_tls_endpoint=/api/enroll
--enroll_secret_path=/etc/osquery/osquery.secret
```

The lines above seem to be the minimum necessary to make osquery pull config
from a TLS endpoint. You will need to populate the `/etc/osqueryd/osqueryd.secret`
file with the value of your NODE_ENROLL_SECRET environment variable. Additional
lines that you may include in your osquery.flags file include:

```
--database_path=/var/osquery/osquery.db
--schedule_splay_percent=10
--logger_plugin=syslog
--logger_syslog_facility=3
--log_results_events=true
--verbose
```

Then you can start osqueryd (on linux) with a simple `/etc/init.d/osqueryd start`
or `service start osqueryd`

## Authentication and logging in
Users must authenticate to access the windmill UI. There is no local storage of
user information, users must authenticate using an OAuth provider, such as
Google or GitHub. You'll need to get an OAuth ID and an OAuth Secret from the
provider of your choice.

### Authorized Users

You also need to create a whitelist of allowed email addresses.

The prefered option is to set the environment variable `AUTHORIZEDUSERS` with a
comma seperated list of email addresses.

`export AUTHORIZEDUSERS=user1@example.com,user2@example.com`

The secondary option is listing users in a file named `authorized_users.txt`.

__Example:__ authorized\_users.txt

```
user1@example.com
user2@example.com
```
> If you're running windmill on Heroku one easy way to manage users without having
merge problems from master is to create a separate branch named users, uncomment
the line in `.gitignore` that hides `authorized_users.txt`.  Then populate your
`authorized_users.txt` file. Finally you can `git push heroku users:master`.
Later you can switch back to master and git pull for updates. Then just go back
to your user branch and `git rebase master`.

### Authenticate with GitHub

Populate an environment variable named `GITHUB_KEY` and a variable named
`GITHUB_SECRET`. If *both*  of these variables are populated with a value, then
the login with GitHub option  will be visible on the login page.

### Authenticate with Heroku

Populate an environment variable named `HEROKU_KEY` and a variable named
`HEROKU_SECRET`. If *both*  of these variables are populated with a value, then
the login with Heroku option  will be visible on the login page.

### Authenticate with Google

Populate an environment variable named `GOOGLE_ID` and a variable named
`GOOGLE_SECRET`. If *both*  of these variables are populated with a value, then
the login with Google option  will be visible on the login page. You will also need to authorize the callback URL `https://yourserver.yourdomain.com/auth/google/callback` for your credentials.

Special note, logging in with Google may require an extra step to avoid protocol
mismatch if you use a service that runs your app unencrypted but uses a service
in between to encrypt, such as Heroku. In those cases when you try to
authenticate with google the requested callback address will not have the https.
To fix this, you need to set yet another environment variable called `FULL_URL`.
That should have the https address of your server, e.g.
`https://yourserver.yourdomain.com`.

### API Authentication

If you've logged into the windmill server you can create api keys with either
read or read/write permission. The resulting key must be passed with every
api call as an http header called Authentication. For example, using curl you
could get a list of configuration groups with this command:

```
curl -i \
-H "authentication: 0944660295b1e3c09aba1ce7ffcfe5da336a510d9963b94dbb0376153ac31e33" \
http://localhost:4567/api/configuration_groups
```

A key with write permission is necessary for any request
that doesn't use the GET method.

## Enrolling osquery endpoints

The osquery endpoints will reach out to the TLS server and send a POST to
`/api/enroll` with a `enroll_secret` value that it read from it's own filesystem
(`/etc/osquery/osquery.secret` if you followed the `osquery.flags` file above).
The value in that file must match the node secret being used by the TLS server
and specify a configuration group. The TLS server takes node secret value from
an environment variable named NODE_ENROLL_SECRET. If you have not set that
variable then it defaults to "valid_test".

If the server sends a valid node_secret then it will be enrolled and joined to
the configuration group that was specified. The endpoint will receive a node key
that it can use to pull its configuration from the server.

You can also store a host identifier for osquery endpoints by adding a host
identifier to the front of the group label and enroll secret stored in
`/etc/osquery/osquery.secret`. The values are separated by a colon.

### Example osquery.secret

 `www-1:web:bigrandomstringofcharactersforthewin`

That will label the endpoint with an identifier of `www-1` and join it to the
`web` configuration group. From that point on it will receive the configuration
file that the `web` configuration group assigns to that endpoint.

If you enroll an endpoint with an invalid configuration group name or a missing
configuration group name it will be added to the `default` configuration group.

## Serving configuration files

Configuration files are kept in a database and are assigned to endpoints by the
configuration group to which they belong. When the application is initialized a
configuration group named `default` is created automatically and a default
configuration file is added to that group.

Additional configuration groups and configuration files can be added by pointing
your browser at the root of the application. There you will find a GUI for
adding new configuration groups and new configuration files.

After an endpoint is enrolled it will make a POST request to /api/config and
provide the node secret it was given when it enrolled. The Windmill server will
look up that node secret and find the configuration file that is assigned to
that endpoint and provide that back to the endpoint.

## Helpful links

* The reference implementation in python: https://github.com/facebook/osquery/blob/master/tools/tests/test_http_server.py
* The documentation: https://github.com/facebook/osquery/blob/master/docs/wiki/deployment/remote.md

## Running tests

The tests are written in RSpec and make use of the `rack-test` gem. If you do a
`bundle install` you should have that.

Then you can just run `rspec spec/` to run the tests.

## Customizing the look and feel
You can add additional stylesheets and javascript to the layout of the page by
adding a file `views/additiona_css.erb` and `views/additonal_js.erb`. These are
embedded ruby file which are rendered in the main layout. The stylesheet partial
is rendered in the head of the html and the javascript is rendered after the
closing body tag.

## Command-line utilities
Windmill comes with two command-line utilities: `console` and `endpoint-cleanup`.

### console
The `console` utility gives you a simple IRB shell that you can use to examine and manipulate the Windmill database.  Take care here, because nothing will prevent you from deploying an osquery configuration without a proper canary test!

Run the `console` utility like this:

```
heroku run bundle exec bin/console
```

### endpoint-cleanup
The `endpoint-cleanup` utility deletes endpoints that have not polled for their configuration recently.  This can be useful if hosts in your infrastructure frequently come and go.  It is not strictly necessary to delete old endpoints, but doing so can make the Windmill UI easier to manage.

Run the `endpoint-cleanup` utility like this:
```
heroku run bundle exec bin/endpoint-cleanup --help
```

With no arguments, this utility will **automatically** purge all endpoints that have not checked in within the past day, without confirmation.  The `-i` option prompts you for confirmation and allows you to view a list of endpoints that will be deleted.

If desired, this utility is designed to be run in non-interactive mode using Heroku Scheduler or a similar scheduling add-on.
