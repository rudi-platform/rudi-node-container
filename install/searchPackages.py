import json
import sys

pfiles = [
    "rudi-catalog/",
    "rudi-storage/",
    "rudi-manager/"
]

def error(msg):
    #sys.stderr.write('error: '+msg+'\n')
    sys.exit(1)

def warning(msg):
    #sys.stderr.write('warning: '+msg+'\n')
    pass

class PackagesOpt():
    template = {
        "name": "rudi_packages",
        "version": "1.0.0",
        "description": "",
        "dependencies": {},
        "author": "Laurent Morin",
        "license": "MIT"
    }

    def __init__(self, plist):
        self.plist = plist
        self.packages = {}
        self.load()
        self.genPackage()

    def load(self):
        for f in self.plist:
            for bf in (r'node_modules/.package-lock.json', r'package.json'):
                try:
                    nf = f+bf; c = json.load(open(nf,'r'))
                except: warning('package not found '+(f+bf))
                if r'packages' not in c: self.processPackage(nf,c)
                else:
                    pl = c[r'packages']
                    for p in pl: self.processPackage(f, pl[p])
                #print(json.dumps(c))

    def processPackage(self, fn, c):
        if not "dependencies" in c: warning('invalid package '+fn); return
        pl = c["dependencies"]
        #print(fn)
        #print(pl)
        for p in pl:
            if p in self.packages:
                e = self.packages[p]
                e['v'].append(pl[p])
                ct = e['c']
                if fn in ct: ct[fn] += 1
                else:        ct[fn] =  1
            else:
                self.packages[p] = { 'v': [pl[p]], 'c': { fn:1  } }

    def genPackage(self):
        r = dict(self.template)
        sp = sorted(self.packages, key = lambda i: -len(self.packages[i]['c']))
        for e in sp:
            ct = self.packages[e]['c']
            if len(ct) > 1:
                vmin=0 ; found = ""
                #print(self.packages[e]['v'])
                for v in self.packages[e]['v']:
                    if v[0] == '^' or v[0] == '=' or v[0] == '~': v = v[1:]
                    vp = v.split('.')
                    s = 0; o = 1;
                    for i in range(len(vp)-1, -1, -1):
                        try:
                            s += int(vp[i]) * o
                            o *= 100
                        except: pass
                    #print("{} {}".format(vp, s))
                    if vmin < s:
                        found = '^' +v
                        vmin = s
                if vmin == 0: continue
                r['dependencies'][e] = found
        r[r'stats'] = self.packages
        self.genPackages = r

    def __repr__(self):
        r = ''
        sp = sorted(self.packages, key = lambda i: -len(self.packages[i]['c']))
        for e in sp: r+= str(e) + ':' + str(self.packages[e]['c']) + ' '
        return r

    def __str__(self):
        return json.dumps(self.genPackages)

if len(sys.argv) > 1:
    #print (sys.argv)
    pfiles = sys.argv[1:]

po = PackagesOpt(pfiles)
print(str(po))
