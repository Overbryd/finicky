#!/usr/bin/env python3
"""Focused private URL transport mutation test. No real URL or installed-app change."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MUTATIONS = [
    ("argv-leak", "Browsers.swift", 'browserOpts.urlTransport == "stdin" ? [] : [url.absoluteString]', '[url.absoluteString]'),
    ("stdin-missing", "Browsers.swift", 'browserOpts.urlTransport == "stdin" ? Data(url.absoluteString.utf8) : nil', 'nil as Data?'),
    ("size-cap", "Utilities.swift", 'input!.count <= 16384', 'true'),
    ("auth-host-log", "Utilities.swift", 'url.host?.lowercased() == "samlsp.private.zscaler.com"', 'false'),
    ("source-log", "Utilities.swift", 'sourceBundleId?.lowercased() == "com.zscaler.zscaler"', 'false'),
    ("callback-log", "Utilities.swift", 'url.scheme?.lowercased() == "zsa"', 'false'),
]
results=[]
with tempfile.TemporaryDirectory(prefix='finicky-private-mutations-') as directory:
    stage=Path(directory)
    sources={name:(ROOT/'Finicky/Finicky'/name).read_text() for name in ['Utilities.swift','Browsers.swift','AppDescriptor.swift']}
    for name,file,old,new in [('baseline',None,None,None),*MUTATIONS]:
        for path,text in sources.items():
            if path==file:
                if text.count(old)!=1:raise SystemExit('mutation source changed: '+name)
                text=text.replace(old,new,1)
            (stage/path).write_text(text)
        binary=stage/'tests'
        build=subprocess.run(['xcrun','swiftc',*(str(stage/x) for x in sources),str(ROOT/'scripts/PrivateURLTransportTests.swift'),'-o',str(binary)],capture_output=True,timeout=60)
        if build.returncode:result='unviable'
        else:
            try:
                test=subprocess.run([str(binary)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=10)
                result='passed' if test.returncode==0 else 'caught'
            except subprocess.TimeoutExpired:result='timeout'
        if name=='baseline' and result!='passed':raise SystemExit('private transport baseline failed')
        results.append({'mutation':name,'result':result})
report=Path('/tmp/finicky-private-url-mutations.json');report.write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results))
if any(x['result']!='caught' for x in results[1:]):raise SystemExit('private URL mutation gate failed')
