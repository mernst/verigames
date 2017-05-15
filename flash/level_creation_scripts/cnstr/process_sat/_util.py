import sys, time
import json, os

start_time = None
last_time = None

def json_dump(obj, fp):
    json.dump(obj, fp, indent=2, separators=(',',': '), sort_keys=True)
    fp.write('\n')

def print_step(step):
    global start_time, last_time
    curr_time = time.time()
    if start_time == None:
        start_time = curr_time
    if last_time != None:
        print ' ... took %0.2fs' % (curr_time - last_time)
    last_time = curr_time
    if step == None:
        print 'done. total %0.2fs' % (curr_time - start_time)
    else:
        print step, '...'
    sys.stdout.flush()

def get_vals(js, lst, ignore=None):
    for key, val in js.iteritems():
        if key not in lst and key not in ignore:
            raise RuntimeError('JSON has unrecognized key ' + key)

    ret = []
    for key in lst:
        if not js.has_key(key):
            raise RuntimeError('JSON missing key ' + key)
            
        ret.append(js[key])

    if ignore:
        for key in ignore:
            if not js.has_key(key):
                ret.append(None)
            else:
                ret.append(js[key])

    if len(ret) == 1:
        return ret[0]
    else:
        return ret
