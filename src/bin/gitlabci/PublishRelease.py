#!/usr/bin/env python3
# Source: https://github.com/mrooding/gitlab-semantic-versioning
import os
import re
import sys
import semver
import subprocess
import gitlab
import json

def git(*args):
    return subprocess.check_output(["git"] + list(args))

def verify_env_var_presence(name):
    if name not in os.environ:
        raise Exception(f"Expected the following environment variable to be set: {name}")

def get_last_merge_request():
    project_id = os.environ['CI_PROJECT_ID']
    gitlab_private_token = os.environ['CI_GITLAB_TOKEN']

    gl = gitlab.Gitlab(os.environ['CI_PROJECT_URL'], private_token=gitlab_private_token)
    gl.auth()

    project = gl.projects.get(project_id)
    mrs = project.mergerequests.list(state='merged', order_by='updated_at')
    for mr in mrs:
        if mr.target_branch == 'master':
            return mr

def bump(latest):
    merge_request = get_last_merge_request()
    labels = merge_request.labels

    if "bump-minor" in labels:
        return semver.bump_minor(latest)
    elif "bump-major" in labels:
        return semver.bump_major(latest)
    else:
        return semver.bump_patch(latest)

def tag_repo(tag):
    project_id = os.environ['CI_PROJECT_ID']
    gitlab_private_token = os.environ['CI_GITLAB_TOKEN']

    gl = gitlab.Gitlab(os.environ['CI_PROJECT_URL'], private_token=gitlab_private_token)
    gl.auth()

    project = gl.projects.get(project_id)
    tag = project.tags.create({'tag_name': tag, 'ref': 'master', 'message': tag})

def add_release(tag):
    project_id = os.environ['CI_PROJECT_ID']
    gitlab_private_token = os.environ['CI_GITLAB_TOKEN']

    gl = gitlab.Gitlab(os.environ['CI_PROJECT_URL'], private_token=gitlab_private_token)
    gl.auth()

    project = gl.projects.get(project_id)
    description = load_changelogs(tag)

    release = project.releases.create({'name':tag, 'tag_name': tag, 'description': description})

def load_changelogs(tag):
    # Open sam-bundles.lock
    # Read last version for each bundle
    # Open all changelog and copy all changelog after the last-version
    # Concat everything
    # Return changelog
    changelog = ""
    with open('.gitlab-ci/releases/changelog-' + tag + '.json') as changelog_file:
        data = json.load(changelog_file)
        for key in data:
            changelog += "### " + key.capitalize() + "\n\n"
            for change in data[key]:
                changelog += change + "\n"
            changelog += "\n\n"

    return changelog

def main():
    env_list = ["CI_PROJECT_ID", "CI_PROJECT_URL", "CI_GITLAB_TOKEN"]
    [verify_env_var_presence(e) for e in env_list]

    try:
        git("fetch", "--unshallow")
        latestShort = git("describe", "--tags", "--match", "*[0-9].*[0-9].*[0-9]", "--abbrev=0").decode().strip()
        print("Current version is: " + latestShort)
    except subprocess.CalledProcessError:
        # Default to version 1.0.0 if no tags are available
        version = "1.0.0"
    else:
        version = bump(latestShort)

    tag_repo(version)
    add_release(version)
    print(version + " released and tagged")

    return 0

if __name__ == "__main__":
    sys.exit(main())
