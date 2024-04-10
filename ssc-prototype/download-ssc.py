'''
Download copy of the Statistical Software Components (SSC) archive

Principles:

1. Each package is identified by its .pkg file
2. Each package its saved into <name>.zip
3. The .pkg file is modified accordingly (relative paths)
4. Incomplete packages are mentioned
5. (Optional) Orphan files are stored in an orphan folder
6. (TODO) How do we save and keep track of changes (with file hashes?)

'''

import csv
import logging
import re
import requests
import time
import zipfile

from bs4 import BeautifulSoup
from urllib.parse import urljoin
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

from tqdm import tqdm

# Package names can contain "-" (e.g. hallt-skewt.pkg)
regex_file_d = re.compile(r"^\s*d\s+'(?P<package>[a-zA-Z0-9_-]+)'\s*:\s*(?P<description>.*)\s*$")
regex_file_d_malformed = re.compile(r"^\s*d\s+'(?P<package>[a-zA-Z0-9_-]+)'\s+(?P<description>.*)\s*$")

regex_file_f = re.compile(r'^\s*(?P<prefix>[fF])\s+(?P<filename>[a-zA-Z0-9_/.-]+[.][a-zA-Z0-9_-]+)\s*$')
regex_file_g = re.compile(r'^\s*(?P<prefix>[gG])\s+(?P<platform>[A-Z0-9.]+)\s+(?P<filename>[a-zA-Z0-9_/.-]+[.][a-zA-Z0-9_-]+)(?P<rest>\s*.*)$')
regex_stop = re.compile(r'^\s*[e]$')

# Invalid packages. Reasons include
# - No files listed in pkg
# - dynsimple: typo of dynsimpie; fixable
# - x11as: malformed description in .pkg file
# - ad-src-package.pkg: not an actual package but a template file (part of the adodown package)
invalid_packages = ['_grminmax', 'aformat', '_gstd01', 'atkplot', 'calibr', 'dave', 'dynsimple',
                    'encode_label', 'estoutold', 'foobar', 'test1', 'x11as', 'ad-src-package']
invalid_packages = set(invalid_packages)

# Not removed:
#, 'circularkde', 'codci')
# - circularkde: circdex1.do instead of circkdex1.do; can be fixed
# - codci: a dta is missing; can be fixed



class NotFoundException(Exception):
    '''Raised with 404 Not Found Errors'''
    pass


class InvalidPackageException(Exception):
    '''Raised with 404 Not Found Errors'''
    pass


def get_folder(fn):
    first_letter = fn[0].lower()
    # Ad-hoc cases
    if first_letter in ('1',):
        first_letter = '_'
    return first_letter


def get(session, url):
    response = session.get(url)
    while response.status_code != 200:
        logging.error("request failed, error code %s [%s]", response.status_code, response.url)
        if 500 <= response.status_code < 600:
            # server is overloaded? give it a break
            time.sleep(5)
        elif response.status_code == 404:
            raise(NotFoundException(url))
        else:
            # crash and burn...
            raise(Exception(url))

    # Finally succeeded...
    return response


def get_pkg(response, packages):
    soup = BeautifulSoup(response.text, 'html.parser')
    links = [a['href'] for a in soup.find_all('a', href=True)]  # Get list of links
    links = [l[:-4] for l in links if l.endswith('.pkg')]  # Keep pkgs
    packages.extend(links)


def outer_process_package(package_name, session, basepath, ssc_url, invalid_list, verbose=False):
    try:
        process_package(package_name=package_name, session=session, basepath=basepath, ssc_url=ssc_url, verbose=verbose)
    except InvalidPackageException as e:
        zip_fn = e.args[2]
        assert zip_fn.suffix == '.zip'
        logging.info(f'Package "{package_name}" is invalid; skipping')
        zip_fn.unlink()
        invalid_list.append(package_name)
    return package_name


def process_package(package_name, session, basepath, ssc_url, verbose=False):
    first_letter = package_name[0]
    path = basepath / first_letter
    path.mkdir(exist_ok=True)
    pkg_url = f'{ssc_url}{first_letter}/{package_name}.pkg'
    response = get(session, pkg_url)

    new_text = []
    header = None
    zip_fn = basepath / get_folder(package_name) / f'{package_name}.zip'
    pkg_fn = basepath / get_folder(package_name) / f'{package_name}.pkg'

    with zipfile.ZipFile(zip_fn, 'w') as myzip:

        for line in response.text.splitlines():
            if verbose:
                print('>>>', line)

            url = fixed_fn = None

            if regex_stop.match(line):
                print('Stopping!')
                new_text.append(line)
                break

            if m := regex_file_d.match(line):
                package = m.group('package').lower()
                description = m.group('description')
                header = f'p {package} {description}'
            elif m := regex_file_d_malformed.match(line):
                print(f'Warning: malformed description in {package_name}')
                package = m.group('package').lower()
                description = m.group('description')
                header = f'p {package} {description}'
            elif m := regex_file_f.match(line):
                fn = m.group('filename')
                fixed_fn = fn.split('/')[-1]
                url = f'{ssc_url}{get_folder(fixed_fn)}/{fixed_fn}'
                if verbose:
                    print(f'F Match! {fn} ~~ {url} ~~ {fixed_fn}')
                prefix = m.group('prefix')
                line = f'{prefix} {fixed_fn}'
            elif m := regex_file_g.match(line):
                fn = m.group('filename')
                fixed_fn = fn.split('/')[-1]
                url = f'{ssc_url}{get_folder(fixed_fn)}/{fixed_fn}'
                if verbose:
                    print(f'G Match! {fn} ~~ {url} ~~ {fixed_fn}')
                prefix = m.group('prefix')
                platform = m.group('platform')
                # WIN is an invalid platform but is used in the matwrite package
                # WIN64a is an invalid platform but is used in the ngram package
                # WIN32 is a <now> invalid platform but is used in the runmixregls package (and maybe others...)
                # LINUX is an invalid platform but is used in the runmixregls package
                # MACINTEL is an invalid platform but is used in the runmlwin package
                # MACINTEL is an invalid platform but is used in the runmlwin package
                # MAC is an invalid platform but is used in the runmlwin package
                # OSX.PPC is an invalid platform but is used in the runmlwin package
                assert platform in ('WIN64', 'MACARM64', 'OSX.ARM64', 'MACINTEL64', 'OSX.X8664', 'LINUX64', 'LINUX64P',
                    'WIN', 'WIN64A', 'WIN32', 'LINUX', 'MACINTEL', 'OSX.X86', 'MAC',
                    'OSX.PPC'), (package_name, platform)
                rest = m.group('rest')
                line = f'{prefix} {platform} {fixed_fn}{rest}'

            if url is not None:
                assert fixed_fn is not None
                try:
                    response = get(session, url)
                except NotFoundException as e:
                    suffix = e.args[0].split('.')[-1]
                    if suffix in ('do', 'dta', 'pdf', 'ico', 'sthlp'):
                        # Nonessential file; package might still be valid
                        logging.info(f'Package "{package_name}" warning: file not found: {url}')
                    else:
                        raise InvalidPackageException(package_name, url, zip_fn)
                else:
                    zip_info = zipfile.ZipInfo(fixed_fn)
                    zip_info.compress_type = zipfile.ZIP_DEFLATED
                    myzip.writestr(zip_info, response.content)
                    new_text.append(line)  # Append line only if file exists
            else:
                # Append the line normally
                new_text.append(line)


        new_text = '\n'.join(new_text)

        # Save stata.toc to .zip
        assert header is not None, pkg_url
        zip_info = zipfile.ZipInfo('stata.toc')
        zip_info.compress_type = zipfile.ZIP_DEFLATED
        myzip.writestr(zip_info, header)
        
        # Save .pkg to .zip
        zip_info = zipfile.ZipInfo(f'{package_name}.pkg')
        zip_info.compress_type = zipfile.ZIP_DEFLATED
        myzip.writestr(zip_info, new_text)

        # Save .pkg as file
        pkg_fn.write_text(new_text, encoding='utf-8')


def get_header(fn):
    '''
    Parse the start of the .pkg file to build the description in stata.toc
    '''

    with fn.open(encoding='utf-8') as file:
        for line in file:
            if m := regex_file_d.match(line):
                package = m.group('package').lower()
                description = m.group('description')
                return f'p {package} {description}'
            elif m := regex_file_d_malformed.match(line):
                print(f'Warning: malformed description in {fn}')
                package = m.group('package').lower()
                description = m.group('description')
                return f'p {package} {description}'

    raise Exception(f"pkg file {fn} has no description")


def main():

    # Constants
    ssc_url = 'http://fmwww.bc.edu/repec/bocode/'
    use_threads = True
    thread_pool = 16
    output_path = Path('C:/Git/ssc-mirror')

    # Initialize logging
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)-8s %(message)s',
        level=logging.INFO,
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    logging.info('Starting SSC download...')
    t0 = time.perf_counter()


    # Create a reusable connection pool with python requests.
    # See: https://stackoverflow.com/a/68583332/5994461
    session = requests.Session()
    adapter = requests.adapters.HTTPAdapter(
        pool_maxsize = thread_pool,
        max_retries = 3,
        pool_block = True)
    session.mount('http://', adapter)
    session.mount('https://', adapter)

    # Get list of subfolders
    response = session.get(ssc_url)
    soup = BeautifulSoup(response.text, 'html.parser')
    links = [a['href'] for a in soup.find_all('a', href=True)]  # Get list of links
    links = [l for l in links if len(l)==2 and l[-1]=='/']  # Remove extraneous links
    links = [urljoin(ssc_url, l) for l in links]  # Create absolute links
    #links = links[:5] # TODO REMOVE
    
    # Get list of packages
    logging.info(f'Finding packages in {len(links)} subfolders')
    #links = links[2:]
    packages = []
    f = lambda response: get_pkg(response=response, packages=packages)
    with ThreadPoolExecutor(max_workers=thread_pool) as executor:
        # wrap in a list() to wait for all requests to complete
        for response in list(executor.map(lambda url: get(session=session, url=url), links)):
            f(response)
    packages = [p for p in packages if p not in invalid_packages]  # remove invalid packages
    packages.sort()
    logging.info(f'Found {len(packages):,} packages')

    # Process all packages
    #packages = packages[:2] # TODO REMOVE
    output_path.mkdir(parents=True, exist_ok=True)
    new_invalid_packages = []

    if use_threads:
        f = lambda package_name: outer_process_package(package_name=package_name, session=session, basepath=output_path, ssc_url=ssc_url, invalid_list=new_invalid_packages)
        with ThreadPoolExecutor(max_workers=thread_pool) as executor:
            # wrap in a list() to wait for all requests to complete
            #for package_name in list(executor.map(f, packages)):
            for package_name in tqdm(executor.map(f, packages)):
                pass
    else:
        for i, package in enumerate(packages):
            print(f'Processing package {i}: "{package}"')
            try:
                process_package(package_name=package, session=session, basepath=output_path, ssc_url=ssc_url)
            except InvalidPackageException as e:
                zip_fn = e.args[2]
                assert zip_fn.suffix == '.zip'
                logging.info(f'Package "{package}" is invalid; skipping')
                zip_fn.unlink()
                new_invalid_packages.append(package_name)

    # Create stata.toc files
    logging.info(f'Creating stata.toc files')
    for path in output_path.glob('*'):
        text = []
        for fn in path.glob('*.pkg'):
            header = get_header(fn)
            text.append(header)
        
        if not text:
            logging.info(f'Folder {path} has no packages; stata.toc not created')
            continue

        text = '\n'.join(text)
        toc_fn = path / 'stata.toc'
        toc_fn.write_text(text, encoding='utf-8')


    elapsed = time.perf_counter() - t0
    elapsed = format(elapsed, "8.2f").strip()
    logging.info(f'SSC download completed in {elapsed} seconds')

    print('\nAdditional invalid packages:')
    for package in new_invalid_packages:
        print(package)

    exit()


if __name__ == '__main__':
    main()