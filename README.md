vim-wakatime
============

Quantify your coding inside Vim.


Installation
------------

1. Install [Vundle](https://github.com/gmarik/vundle), the Vim plugin manager.

2. Using [Vundle](https://github.com/gmarik/vundle):<br />
  `echo "Bundle 'wakatime/vim-wakatime'" >> ~/.vimrc && vim +BundleInstall`

  or using [Pathogen](https://github.com/tpope/vim-pathogen):<br />
  `cd ~/.vim/bundle && git clone git://github.com/wakatime/vim-wakatime.git`

3. Point hackatime to your influxdb instance (and optionally set Basic Authorization information):

    let g: wakatime_InfluxHost = 'influx.example.com'
    let g: wakatime_BasicAuth  = 'user:password'       " optional

4. Use Vim and your coding activity will be displayed on your [Grafana dashboard](https://grafana.jjanzic.com).

Note: HackaTime depends on [Python](http://www.python.org/getit/) being installed to work correctly. To use a custom python binary:

    let g:wakatime_PythonBinary = '/usr/bin/python'
