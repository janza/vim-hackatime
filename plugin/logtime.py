#!/usr/bin/env python

import argparse
import datetime
import os
import sqlite3
import http.client
from base64 import b64encode


class Storage():
    DB_FILE = os.path.join(os.path.expanduser('~'), '.hackatime.db')

    def __init__(self):
        self.DB_FILE

        conn = sqlite3.connect(self.DB_FILE, isolation_level=None)
        c = conn.cursor()

        c.execute('''CREATE TABLE IF NOT EXISTS log (
            entity text,
            time real,
            project text,
            branch text,
            language text,
            write boolean
        )''')

        self.conn = conn
        self.c = c

    def save(self, data):
        self.c.execute('''INSERT INTO log VALUES (
             :entity,
             :time,
             :project,
             :branch,
             :language,
             :write
        )''', data)
        self.conn.commit()
        self.conn.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--entity', required=True)
    parser.add_argument('--time', default=datetime.datetime.utcnow().isoformat() + 'Z')
    parser.add_argument('--project', default='')
    parser.add_argument('--branch', default='')
    parser.add_argument('--language', default='')
    parser.add_argument('--host', required=True)
    parser.add_argument('--auth', required=True)
    parser.add_argument('--write', action='store_true')

    args = vars(parser.parse_args())

    args['time'] = int((datetime.datetime.strptime(args.get('time'), '%Y-%m-%dT%H:%M:%S.%fZ') -
                        datetime.datetime(1970, 1, 1)).total_seconds())

    s = Storage()
    s.save(args)

    h = http.client.HTTPSConnection(args.get('host'))

    def filterTag(tag):
        return tag.replace(',', "\,").replace('=', '\=').replace(' ', '\ ')

    tags = []
    for k, v in args.items():
        if v and k in ['language', 'branch', 'project', 'entity']:
            tags.append('{}={}'.format(k, filterTag(v)))

    userAndPass = b64encode(args.get('auth').encode('utf8')).decode('utf8')

    h.request(
        'POST',
        '/write?db=codelog&precision=s',
        'code,' + ','.join(tags) + ' heartbeat=1i,timestamp={time} {time}'.format(**args),
        {'Authorization': 'Basic {}'.format(userAndPass)}
    )
    h.getresponse()
    h.close()


if __name__ == '__main__':
    main()
