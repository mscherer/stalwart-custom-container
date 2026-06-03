import sys
import subprocess
import requests
import os
import shutil

REPOS = 'stalwartlabs/stalwart'
TAG = 'latest'
# either 'debug' or 'release'
BUILD = 'release'

API_URL = f'https://api.github.com/repos/{REPOS}/releases/{TAG}'
rpm_features = {
    # storage
    'sqlite': [],
    'postgres': [],
    'mysql': [],
    'foundation': ['clang-devel'],
    'rocks': ['clang-devel', 'libstdc++-static'],
    's3': [],
    'redis': [],
    # azure blob support
    'azure': [],
    # coordination
    'nats': [],
    'zenoh': [],
    'kafka': ['gcc-c++', 'cmake', 'libstdc++-static', 'curl-devel'],
    # non free stuff
    'enterprise': [],
}

not_working_features = [
    # do not work, requires a static version of the library not packaged on Fedora
    # /usr/bin/ld.bfd: cannot find -lfdb_c: No such file or directory
    'foundation',
]

rpm_to_install = [
    'cargo',
    'glibc-static',
    'git'
]

features_arg = []
if len(sys.argv) >= 2:
    for i in sys.argv[1:]:
        rpm_to_install.extend(rpm_features[i])
        if i in not_working_features:
            print(
                f"feature {i} is not supported for the static build, see the script for details")
            sys.exit(255)
    features_arg = ['--features',  ' '.join(sys.argv[1:])]

if len(rpm_to_install) > 0:
    dnf_cmd = [
        'dnf',
        'install',
        '-y',
        '--setopt=install_weak_deps=False'
    ]
    dnf_cmd.extend(rpm_to_install)
    subprocess.run(dnf_cmd)

latest_release_tag = requests.get(API_URL).json()['tag_name']

git_cmd = [
    'git',
    'clone',
    '--depth=1',
    f'https://github.com/{REPOS}.git',
    f'--revision={latest_release_tag}',
    'code'
]
subprocess.run(git_cmd)

os.chdir('code')

target = subprocess.run(['rustc', '--print', 'host-tuple'],
                        capture_output=True).stdout.decode('utf-8').strip()

command = ['cargo', 'build', '--target', target, '--no-default-features']
if BUILD == 'release':
    command.extend(['--release'])
command.extend(features_arg)

# see https://msfjarvis.dev/posts/building-static-rust-binaries-for-linux/
e = os.environ
e['RUSTFLAGS'] = '-C target-feature=+crt-static'

subprocess.run(command, env=e)

shutil.move(f'target/{target}/{BUILD}/stalwart', '/srv/stalwart')
