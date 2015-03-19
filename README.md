Delete all bindings and service instances for a service
=======================================================

You might discover this problem once in your life: you've shipped a new service broker into your Cloud Foundry and then discovered a big in it. But everyone started using it. So you want to delete all user cases, fix the issue, and re-create everyone's service & binding.

There are probably more use cases where you want to actually upgrade/patch/fix the service instances. But in this scenario you decide you want to blow away all the service instances.

For us the example was a Logstash/Elastic Search service. It was buggy - and the elastic search containers were cross-contaminating their logs (they auto-clustered). So we didn't want to upgrade/fix them. We wanted to blow them away and recreate them all without bad data in them.

Usage
-----

Log into Cloud Foundry with admin user credentials; and target an arbitrary organization/space. It doesn't matter which - the `./bin/delete.sh` command will destroy all bindings/service instances across all orgs/spaces.

```
cf login -a <api.url> -u admin -p PASSWORD
```

In our case, the bad service was `logstash14` (for all plans). To find all service instances and service bindings, then unbind the bindings and delete the service instances we ran:

```
./bin/delete.sh logstash14
```

As a bonus, the output showed us exactly what commands to run to recreate the service instances and rebind the applications (after we fixed the service).

For example:

```
Recreate service instances and bindings:
cf target -o system -s dev; cf cs logstash14 free logstash-one
cf target -o system -s dev; cf bs app-one-log-one logstash-one; cf restart app-one-log-one
cf target -o system -s dev; cf cs logstash14 free logstash-one
cf target -o system -s dev; cf bs app-two-log-one logstash-one; cf restart app-two-log-one
cf target -o system -s dev; cf cs logstash14 free logstash-two
cf target -o system -s dev; cf bs app-three-log-two logstash-two; cf restart app-three-log-two
```

Trial
-----

You might want to try this out first before running in production.

Start up a dedicated Cloud Foundry, such as with bosh-lite.

Then run:

```
./bin/setup.sh
```

This is an example script to deploy some apps, create some services, and bind them together.

You will have the following service instances/app bindings:

```
$ cf s
name           service      plan   bound apps                         status
logstash-one   logstash14   free   app-one-log-one, app-two-log-one   available
logstash-two   logstash14   free   app-three-log-two                  available
```

You can then delete them with the `./bin/delete.sh` command above.

```
./bin/delete.sh logstash14
```

At this point, since we only had `logstash14` service instances, we will now have no service instances. For example:

```
$ cf s
Getting services in org system / space dev as admin...
OK

No services found
```

Finally, you recreate the service instances/bindings with the recommended commands to run (from the `./bin/delete.sh logstash14` command):

```
cf target -o system -s dev; cf cs logstash14 free logstash-one
cf target -o system -s dev; cf bs app-one-log-one logstash-one; cf restart app-one-log-one
cf target -o system -s dev; cf cs logstash14 free logstash-one
cf target -o system -s dev; cf bs app-two-log-one logstash-one; cf restart app-two-log-one
cf target -o system -s dev; cf cs logstash14 free logstash-two
cf target -o system -s dev; cf bs app-three-log-two logstash-two; cf restart app-three-log-two
```
