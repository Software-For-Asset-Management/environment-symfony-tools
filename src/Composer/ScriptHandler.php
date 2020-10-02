<?php

namespace SAM\EnvironmentSymfonyTools\Composer;

use Sensio\Bundle\DistributionBundle\Composer\ScriptHandler as BaseScriptHandler;
use Composer\Script\Event;
use Symfony\Component\Filesystem\Filesystem;

class ScriptHandler extends BaseScriptHandler
{
    /**
     * Install binaries
     *
     * @param Event $event
     */
    public static function install($event)
    {
        $options = static::getOptions($event);
        $fs = new Filesystem();

        $binDir = $options['symfony-bin-dir'];

        $fs->copy(__DIR__.'/../bin/increment-tags.sh', $binDir.'/increment-tags.sh', true);
        $fs->copy(__DIR__.'/../bin/pull-checkout.sh', $binDir.'/pull-checkout.sh', true);
        $fs->copy(__DIR__.'/../bin/submit-feature.sh', $binDir.'/submit-feature.sh', true);
        $fs->copy(__DIR__.'/../bin/update-composer.js', $binDir.'/update-composer.js', true);

        $fs->chmod($binDir.'/increment-tags.sh', 0755);
        $fs->chmod($binDir.'/pull-checkout.sh', 0755);
        $fs->chmod($binDir.'/submit-feature.sh', 0755);
        $fs->chmod($binDir.'/update-composer.js', 0755);
    }
}
