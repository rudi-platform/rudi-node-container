import json
import sys

pfiles = [
    "rudi-catalog/package.json",
    "rudi-storage/package.json",
    "rudi-manager/package.json",
    "rudi-manager/front/package.json",
]

def error(msg):
    sys.stderr.write('error: '+msg+'\n')
    sys.exit(1)

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
            c = json.load(open(f,'r'))
            if not "dependencies" in c: error('invalid package '+f)
            pl = c["dependencies"]
            #print(f)
            #print(pl)
            for p in pl:
                if p in self.packages:
                    e = self.packages[p]
                    e['v'].append(pl[p])
                    e['c']+=1
                else:
                    self.packages[p] = { 'v': [pl[p]], 'c':1 }

    def genPackage(self):
        r = dict(self.template)
        sp = sorted(self.packages, key = lambda i: -self.packages[i]['c'])
        for e in sp:
            c = self.packages[e]['c']
            if c > 1:
                vmin=0 ; found = ""
                #print(self.packages[e]['v'])
                for v in self.packages[e]['v']:
                    if v[0] != '^': vmin=0; break
                    vp = v[1:].split('.')
                    s = 0; o = 1;
                    for i in range(len(vp)-1, -1, -1):
                        s += int(vp[i]) * o
                        o *= 100
                    #print("{} {}".format(vp, s))
                    if vmin < s:
                        found = v
                        vmin = s
                if vmin == 0: continue
                r['dependencies'][e] = found
        self.genPackages = r

    def __repr__(self):
        r = ''
        sp = sorted(self.packages, key = lambda i: -self.packages[i]['c'])
        for e in sp: r+= str(e) + ':' + str(self.packages[e]['c']) + ' '
        return r

    def __str__(self):
        return json.dumps(self.genPackages)

if len(sys.argv) > 1:
    #print (sys.argv)
    pfiles = sys.argv[1:]

po = PackagesOpt(pfiles)
print(str(po))
