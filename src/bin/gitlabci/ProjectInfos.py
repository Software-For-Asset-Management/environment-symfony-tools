#!/usr/bin/env python3
# Source: https://github.com/mrooding/gitlab-semantic-versioning
import os
import gitlab
from pathlib import Path
from dotenv import load_dotenv
load_dotenv()
load_dotenv(dotenv_path=Path('.') / '.env')
try:
    load_dotenv(dotenv_path=Path('.') / '.env.dev.local')
except IOError:
    print("No .env.dev.local, rely only on .env")

def verify_env_var_presence(name):
    if name not in os.environ:
        raise Exception(f"Expected the following environment variable to be set: {name}")

env_list = ["CI_GITLAB_TOKEN"]
[verify_env_var_presence(e) for e in env_list]

gitlab_private_token = os.environ['CI_GITLAB_TOKEN']

gl = gitlab.Gitlab('https://gitlab.com', private_token=gitlab_private_token)
gl.auth()

for group in gl.groups.list():
    if group.name == 'Projects':
        for project in group.projects.list():
            if project.name == os.environ['CI_GITLAB_PROJECT_NAME']:
                print(project)
