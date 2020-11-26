#!/usr/bin/env python3
import os
import re
import sys
import semver
import subprocess
import gitlab
import json
import shutil
from pathlib import Path
from dotenv import load_dotenv
load_dotenv()

def git(*args):
    return subprocess.check_output(["git"] + list(args))

def verify_env_var_presence(name):
    if name not in os.environ:
        raise Exception(f"Expected the following environment variable to be set: {name}")

def get_update_type():
    updateType = "patch"
    with open('.gitlab-ci/changelog.json') as changelog_file:
        data = json.load(changelog_file)
        for key in data:
            if key == "added":
                return "minor"

    return updateType

def get_next_version(updateType):
    try:
        stream = os.popen("git ls-remote --tags | grep -o 'refs/tags/[0-9]*\.[0-9]*\.[0-9]*' | sort -rV | head -1 | grep -o '[^\/]*$'")
        version = stream.read().strip()
    except subprocess.CalledProcessError:
        # Default to version 1.0.0 if no tags are available
        version = "1.0.0"

    print('Current version: ' + version)

    if updateType == "minor":
        return semver.bump_minor(version)
    elif updateType == "major":
        return semver.bump_major(version)
    else:
        return semver.bump_patch(version)

def create_merge_request():
    project_id = os.environ['CI_PROJECT_ID']
    gitlab_private_token = os.environ['CI_GITLAB_TOKEN']

    gl = gitlab.Gitlab(os.environ['CI_PROJECT_URL'], private_token=gitlab_private_token)
    gl.auth()

    updateType = get_update_type()
    nextVersion = get_next_version(updateType)
    print('New version: ' + nextVersion)

    rotate_changelog(nextVersion)

    labels = []
    if updateType == "minor":
        labels.append("bump-minor")
    elif updateType == "major":
        labels.append("bump-major")

    project = gl.projects.get(project_id)
    mr = project.mergerequests.create({'source_branch': 'develop',
                                    'target_branch': 'master',
                                    'title': 'Release attempt for version ' + nextVersion,
                                    'labels': labels})

    print('')
    print('MR: ' + mr.web_url)
    print('')

    return nextVersion

def rotate_changelog(version):
    Path('.gitlab-ci/releases').mkdir(parents=True, exist_ok=True)
    shutil.move('.gitlab-ci/changelog.json', '.gitlab-ci/releases/changelog-' + version + '.json')
    git('add', '.gitlab-ci/releases/changelog-' + version + '.json')
    git("commit", "-am", "Rotate changelog for version " + version)
    git("push")

    print('Changelog rotated')

def main():
    env_list = ["CI_PROJECT_ID", "CI_PROJECT_URL", "CI_GITLAB_TOKEN"]
    [verify_env_var_presence(e) for e in env_list]

    branchName = git("rev-parse", "--abbrev-ref", "HEAD").decode().strip()
    if branchName == "develop":
        create_merge_request()
    else:
        print("Please checkout develop branch")

    return 0

if __name__ == "__main__":
    sys.exit(main())
