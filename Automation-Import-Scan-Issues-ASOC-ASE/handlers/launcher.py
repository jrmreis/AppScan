import subprocess, sys, time, re

def handle(webhookObj, data):
    pattern=r"(?<=reports\/)[^']*"
    file=re.search(pattern,str(data))
    file=file.group(0)
    print(file)
    p = subprocess.Popen(["pwsh.exe","-File","importScanResults.ps1",file],stdout=sys.stdout)
    p.communicate()
