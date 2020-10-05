# environment-symfony-tools

## Symfony 4.x

`composer require mysam/environment-symfony-tools:^2.0`

Add the following in your root composer.json file:

```json
{
    "auto-scripts": {
        "sam:bin:install": "symfony-cmd"
    },
}
```

## Symfony 3.x

### How to install

`composer require mysam/environment-symfony-tools:^1.0`

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
