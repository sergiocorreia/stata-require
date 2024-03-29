'''
Create a map from ADO files to packages

Uses the zipfiles generated by 'download-ssc.py'
'''

import csv
import zipfile
from pathlib import Path

def save_csv(filename, header, data, encoding='utf8', debug=True, strict=False):
    if debug:
        print(f'Saving CSV: {filename}')
    if strict:
        assert len(header) == len(data[0])
    with filename.open(mode='w', newline='', encoding=encoding) as f:
        writer = csv.writer(f, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)
        writer.writerows(data)



basepath = Path('C:/Git/ssc-mirror')
outpath = Path('./journal-counts/ado2pkg.tsv')

paths = [p for p in basepath.glob('*') if p.is_dir()]
zipfiles = [f for p in paths for f in p.glob('*.zip')]
header = ['pkg', 'file']
data = [[z.stem, f] for z in zipfiles for f in zipfile.ZipFile(z).namelist()]

with outpath.open(mode='w', newline='', encoding='utf8') as f:
    writer = csv.writer(f, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(header)
    writer.writerows(data)

print('Done!')
