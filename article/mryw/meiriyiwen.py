#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import time
import datetime
import requests
import contextlib
import json
import difflib

try:
    import opencc
    CCer = opencc.OpenCC('t2s.json')
except:
    CCer = None

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
        print("[Info] Get %d downloaded results from '%s'." % (old_L, output))
    results = {}
    results_404 = []
    for day in dates(start, stop):
        try:
            if day not in old_results:
                data = get_day_data(day)
                if data:
                    print("[Info] Get data of day: %s" % day)
                    results[day] = data
                    time.sleep(dt)
            else:
                data = old_results[day]
            if data == 40404:
                results_404.append(day)
            elif type(data) != dict:
                print(day, ':', data)  # never
        except KeyboardInterrupt:
            ask = input("\n[Interrupt] Stop downloading?")
            if ask in ('y', 'Y'):
                break
    if results_404:
        print('[Info] %d empty(40404) days.' % len(results_404))
        #print('\t', results_404)
    if results:
        results.update(old_results)
        with open(output, 'w', encoding='utf8') as out:
            print()
            print("[Info] Save %d results to %s ..." % (len(results), output))
            json.dump(results, out, ensure_ascii=False)


def split_json(file, outdir='./split-jsons'):
    '''Read results in source file, save them to outdir/{date,title}-names.'''
    if not os.path.exists(file):
        print("[Error] %s not found!" % file)
        return

    with open(file, 'r', encoding='utf8') as f:
        results = json.load(f)
    L = len(results)
    print("[Info] Read %d results from '%s'." % (L, file))
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    N = 0
    alias = {}  # title-author
    for day in results:
        if results[day] == 40404:
            continue
        N += 1
        title = '{title}-{author}'.format(**results[day])
        digest = results[day]['digest'].replace(' ', '')
        # __dl.append(len(digest)) # sorted, 59, 60, .., 69, 70, 70, ...
        if CCer:
            digest = CCer.convert(digest)
        if title not in alias:
            alias[title] = {digest: [day]}
        else:
            if digest not in alias[title]:
                added = False
                for dig in alias[title].keys():
                    sr = difflib.SequenceMatcher(None, dig, digest).ratio()
                    # 0.571 0.714 0.857 0.885 , >0.9
                    if sr > 0.9:
                        #print('%s %s' % (sr, title))
                        #print(alias[title][dig], dig)
                        #print([day], digest, '\n')
                        alias[title][dig].append(day)  # similar-add
                        added = True
                        break
                if not added:
                    alias[title][digest] = [day]  # new-add
            else:
                alias[title][digest].append(day)  # equal-add
    M = len(alias)
    print("[Info] Get (%d/%d)dates, (%d/%d)titles." % (N, L, M, N))

    # DO alias[title] = {digest1: [days-1], digest2: [days-2], ...}
    u_dates, l_dates, l_titles = [], [], []

    def _write_data(day, daylinks, titlelinks):
        output = '%s/%s.json' % (outdir, day)
        if os.path.isfile(output):
            print("[Info] %s exists." % output)
            return
        with open(output, 'w', encoding='utf8') as out:
            #print("[Info] Writting %s ..." % output)
            json.dump(dict(data=results[day]), out, ensure_ascii=False)
        u_dates.append(day)
        l_dates.extend(daylinks)
        l_titles.extend(titlelinks)
        for ln in daylinks + titlelinks:
            link = '%s/%s.json' % (outdir, ln)
            if os.path.isfile(link):
                print("[Info] %s exists." % link)
            else:
                src = os.path.basename(output)  # same dir with *link*
                #print("[Info] Linking %s -> %s ..." % (link, src))
                os.symlink(src, link)

    for title, ds in alias.items():
        # sort -> [[days-1], ...]
        dsl = []
        for dig, days in ds.items():
            days.sort()
            dsl.append(days)
        dsl.sort()
        if len(dsl) > 1:
            # title(title-1), title-2, ...
            # [days-1],       [days-2], ...
            i = 0
            for days in dsl:
                i += 1
                tlinks = ['%s-%d' % (title, i)]
                if i == 1:
                    tlinks.append(title)
                _write_data(days[0], days[1:], tlinks)
        else:
            # title, [days]
            days = dsl[0]
            _write_data(days[0], days[1:], [title])

    keys = u_dates + l_dates + l_titles
    with open('%s/keys.json' % outdir, 'w', encoding='utf8') as out:
        print("[Info] Writting (%d/%d) dates ..." % (len(u_dates), L))
        print("[Info] Writting (%d/%d) link-dates ..." % (len(l_dates), L))
        print("[Info] Writting (%d/%d) link-titles ..." % (len(l_titles), L))
        json.dump(sorted(keys), out, ensure_ascii=False)


if __name__ == '__main__':
    output = './meiriyiwen-all.json'
    main(output, dt=2)
    split_json(output)
