Delete all bindings and service instances for a service
=======================================================

You might discover this problem once in your life: you've shipped a new service broker into your Cloud Foundry and then discovered a big in it. But everyone started using it. So you want to delete all user cases, fix the issue, and re-create everyone's service & binding.

There are probably more use cases where you want to actually upgrade/patch/fix the service instances. But in this scenario you decide you want to blow away all the service instances.

For us the example was a Logstash/Elastic Search service. It was buggy - and the elastic search containers were cross-contaminating their logs (they auto-clustered). So we didn't want to upgrade/fix them. We wanted to blow them away and recreate them all without bad data in them.

Usage
-----

In our case, the bad service was `logstash14` (for all plans). To find all service instances and service bindings, then unbind the bindings and delete the service instances we ran:

```
./bin/delete.sh logstash14
```

As a bonus, the output showed us exactly what commands to run to recreate the service instances and rebind the applications (after we fixed the service).

Trial
-----

You might want to try this out first before running in production.

```
./bin/setup.sh
```

This is an example script to deploy some apps, create some services, and bind them together.

You can then delete them with the `./bin/delete.sh` command above.
