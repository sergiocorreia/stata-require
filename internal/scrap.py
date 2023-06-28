import requests
import csv
from pathlib import Path



def read_data(fn):
    print(f'- Reading input file {fn}')
    data = []
    with fn.open(mode='r', encoding='utf8') as fh:
        reader = csv.reader(fh, delimiter='\t')
        next(reader)  # header
        for row in reader:
            package, url, weight = row
            data.append([package, url, int(weight)])
    print(f'  Loaded {len(data):,} rows')
    return data


def main():
    basepath = Path('../test')
    package_fn = basepath / 'package-list.tsv'
    data = read_data(package_fn)
    for package, url, weight in data:
        fn = basepath / 'cache' / Path(url).name
        if fn.exists():
            continue
        print(url)
        r = requests.get(url)
        with fn.open(mode='w', encoding='utf8') as fh:
            #fh.write(r.text)
            fh.writelines(f'{s}\n' for s in r.text.splitlines())


if __name__ == '__main__':
    main()