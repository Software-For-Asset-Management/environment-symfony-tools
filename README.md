# environment-symfony-tools

## How to install

`composer require sam/environment-symfony-tools`

Add the following in your root composer.json file:

```json
{
    "scripts": {
        "post-install-cmd": [
            "SAM\\EnvironmentSymfonyTools\\Composer\\ScriptHandler::install"
        ],
        "post-update-cmd": [
            "SAM\\EnvironmentSymfonyTools\\Composer\\ScriptHandler::install"
        ]
    }
}
```

## How it works

When you install this composer package, on `post-install`, we copy `src/` content to the Symfony project
