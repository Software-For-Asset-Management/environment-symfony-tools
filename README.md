# environment-symfony-tools

## How to install

`composer require sam/environment-symfony-tools`

and then add into `composer.json` into `symfony-scripts` array:

```
"SAM\\EnvironmentSymfonyTools\\Composer\\ScriptHandler::install"
```

## How it works

When you install this composer package, on `post-install`, we copy `src/` content to the Symfony project
