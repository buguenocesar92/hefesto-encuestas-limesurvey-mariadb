#!/usr/bin/env python3
import hashlib,json,os,subprocess,sys,tarfile
from pathlib import Path,PurePosixPath
root=Path(__file__).resolve().parents[1];os.chdir(root)
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/restore.py /ruta/respaldo')
p=Path(sys.argv[1]).resolve();m=json.loads((p/'manifest.json').read_text())
required={'database.sql','upload.tar.gz','config.tar.gz','.env','compose.yaml','Dockerfile'}
if m.get('status')!='completed' or set(m.get('sha256',{}))!=required:raise SystemExit('Manifest incompleto')
for name in required:
    with (p/name).open('rb') as f:
        if hashlib.file_digest(f,'sha256').hexdigest()!=m['sha256'][name]:raise SystemExit('Hash incorrecto: '+name)
for name in ['upload','config']:
    with tarfile.open(p/(name+'.tar.gz')) as tf:
        for member in tf:
            if PurePosixPath(member.name).is_absolute() or '..' in PurePosixPath(member.name).parts or not(member.isfile() or member.isdir()):raise SystemExit('Tipo/ruta de archivo no admitido: '+member.name)
def dc(*a,**kw):return subprocess.run(['docker','compose',*a],check=True,**kw)
def run(*a,**kw):return subprocess.run(['docker',*a],check=True,**kw)
if not (root/'.env').is_file():raise SystemExit('Preparar .env del destino')
if dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('app debe estar detenida')
c=json.loads(dc('config','--format','json',capture_output=True,text=True).stdout)
image=c['services']['app']['image']
count=dc('exec','-T','db','sh','-c','MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u "$MARIADB_USER" -N -B "$MARIADB_DATABASE" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()"',capture_output=True,text=True).stdout.strip()
if count!='0':raise SystemExit('Base no vacía; no se sobrescribe')
mounts={}
for name in ['upload','config']:
    v=c['volumes'][name]['name'];run('volume','create',v,capture_output=True)
    mount='type=volume,src='+v+',dst=/restore,volume-nocopy';mounts[name]=mount
    found=run('run','--rm','--user','0','--entrypoint','find','--mount',mount,image,'/restore','-mindepth','1','-maxdepth','1',capture_output=True,text=True).stdout.strip()
    if found:raise SystemExit('Volumen no vacío: '+name)
with (p/'database.sql').open('rb') as f:
    dc('exec','-T','db','sh','-c','MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u "$MARIADB_USER" "$MARIADB_DATABASE"',stdin=f)
for name in ['upload','config']:
    with (p/(name+'.tar.gz')).open('rb') as f:
        run('run','--rm','-i','--user','0','--entrypoint','tar','--mount',mounts[name],image,'-xzf','-','-C','/restore',stdin=f)
    run('run','--rm','--user','0','--entrypoint','chown','--mount',mounts[name],image,'-R','33:33','/restore')
print('Restaurado. Iniciar app y ejecutar aceptación. Ante fallo parcial usar destinos nuevos.')
