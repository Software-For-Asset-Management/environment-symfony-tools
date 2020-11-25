<?php

namespace SAM\EnvironmentSymfonyTools\Composer;

use Sensio\Bundle\DistributionBundle\Composer\ScriptHandler as BaseScriptHandler;
use Composer\Script\Event;
use Symfony\Component\Filesystem\Filesystem;
use SAM\EnvironmentSymfonyTools\Installer\Installer;

class ScriptHandler extends BaseScriptHandler
{
    /**
     * Install binaries
     *
     * @param Event $event
     */
    public static function install($event)
    {
        $binDir = static::getOptions($event)['symfony-bin-dir'];

        Installer::install($binDir);
    }
}
