import sys
import subprocess
import requests
import os
import shutil

REPOS='stalwartlabs/stalwart'
TAG='latest'
API_URL=f'https://api.github.com/repos/{REPOS}/releases/{TAG}' 
BUILD='debug'

rpm_features = {
    # storage
    'sqlite': [],
    'postgres': [],
    'mysql': [],
    'foundation': ['clang-devel'],
    'rocks': ['clang-devel'],
    's3': [],
    'redis': [],
    # azure blob support
    'azure': [],
    # coordination
    'nats': [],
    'zenoh': [],
    'kafka': ['gcc-c++', 'cmake', 'libstdc++-static'],
    # non free stuff
    'enterprise': [],
}

rpm_to_install = [
    'cargo',
    'glibc-static',
    'git'
]

features_arg=[]
if len(sys.argv) >= 2:
    for i in sys.argv[1:]:
        rpm_to_install.extend(rpm_features[i])
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
    f'--revision={latest_release_tag}'
]
subprocess.run(git_cmd)

os.chdir(REPOS.split('/')[1])

target = subprocess.run(['rustc', '--print', 'host-tuple'],capture_output=True).stdout.strip()

command = ['cargo', 'build', '--target', target, '--no-default-features']
if BUILD == 'release':
    command.extend(['--release'])
command.extend(features_arg)

# see https://msfjarvis.dev/posts/building-static-rust-binaries-for-linux/
e = os.environ
e['RUSTFLAGS']='-C target-feature=+crt-static'

subprocess.run(command, env=e)

shutil.move(f'target/{target}/{BUILD}/stalwart', './stalwart.bin')
