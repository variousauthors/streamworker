= Streamworker

A Rails Engine for using http streaming requests to perform long-running tasks. This allows avoiding the overhead of background workers on cloud providers.

This probably only makes sense when the long-running tasks are long-running because they do a lot of waiting, ie, they consume a third-party api which is the source of slowness.

This plugin was extracted from our Shopify apps.

[![Build Status](https://travis-ci.org/lastobelus/streamworker.png)](https://travis-ci.org/lastobelus/streamworker)
