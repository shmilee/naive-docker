#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import time
import datetime
import requests
import contextlib
import json

URL = 'https://interface.meiriyiwen.com/article/day?dev=1&date='


def get_day_data(date):
    '''
    Get data by date: 20110308 -> 20200909
    '''
    url = URL+str(date)
    try:
        with contextlib.closing(requests.get(url)) as rp:
            if rp.status_code == 404:
                print('\033[31m[Download %s 404 Not Found]\033[0m' % url)
                return 40404
            elif rp.status_code == 200:
                return json.loads(rp.text)['data']
    except Exception as err:
        print('\033[31m[Download %s Error]\033[0m' % url, err)


def dates(start, stop):
    '''date str generator, from start=(2011,3,18) to stop=(2020,9,9)'''
    start = datetime.date(*start)
    stop = datetime.date(*stop)
    delta = datetime.timedelta(days=1)
    while start <= stop:
        yield start.strftime(r'%Y%m%d')
        start = start + delta


def main(output, start=(2011, 3, 8), stop=(2020, 9, 9), dt=3):
    '''
    Get all data, save them to output json file.
    '''
    old_results = {}
    if os.path.exists(output):
        try:
            with open(output, 'r', encoding='utf8') as out:
                old_results = json.load(out)
        except Exception:
            pass
        old_L = len(old_results)
        print("[Info] Read %d results from '%s'." % (old_L, output))
    results = {}
    for day in dates(start, stop):
        try:
            if day not in old_results:
                data = get_day_data(day)
                if data:
                    print("[Info] Get data of day: %s" % day)
                    results[day] = data
                    time.sleep(dt)
            elif type(old_results[day]) != dict:
                print(day, ':', old_results[day])
        except KeyboardInterrupt:
            ask = input("\n[Interrupt] Stop downloading?")
            if ask in ('y', 'Y'):
                break
    if results:
        results.update(old_results)
        with open(output, 'w', encoding='utf8') as out:
            print()
            print("[Info] Save %d results to %s ..." % (len(results), output))
            json.dump(results, out, ensure_ascii=False)


def split_json(file, outdir='./split-jsons'):
    '''Read results in file, save them to outdir/date-names.'''
    if os.path.exists(file):
        with open(file, 'r', encoding='utf8') as f:
            results = json.load(f)
        L = len(results)
        print("[Info] Read %d results from '%s'." % (L, file))
        if not os.path.exists(outdir):
            os.mkdir(outdir)
        all_dates = []
        for day in results:
            if results[day] == 40404:
                continue
            all_dates.append(day)
            output = '%s/%s.json' % (outdir, day)
            if os.path.isfile(output):
                print("[Info] %s exists." % output)
                continue
            with open(output, 'w', encoding='utf8') as out:
                #print("[Info] Writting %s ..." % output)
                json.dump(dict(data=results[day]), out, ensure_ascii=False)
        with open('%s/dates.json' % outdir, 'w', encoding='utf8') as out:
            print("[Info] Writting (%d/%d) dates ..." % (len(all_dates), L))
            json.dump(sorted(all_dates), out, ensure_ascii=False)


if __name__ == '__main__':
    output = './meiriyiwen-all.json'
    main(output, dt=2)
    split_json(output)
