vim-hackatime
============

Quantify your coding inside Vim.


Installation
------------

1. Point hackatime to your influxdb instance (and optionally set Basic Authorization information):

```
    let g: hackatime_InfluxHost = 'influx.example.com'
    let g: hackatime_BasicAuth  = 'user:password'       " optional
```

2. Use Vim and your coding activity will be displayed on your [Grafana dashboard](https://grafana.com).

Note: HackaTime depends on [Python](http://www.python.org/getit/) being installed to work correctly. To use a custom python binary:

    let g:hackatime_PythonBinary = '/usr/bin/python'

TODO
----

Release influx/grafana dashboad setup.
