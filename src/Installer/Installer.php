<?php

namespace SAM\EnvironmentSymfonyTools\Installer;

use Symfony\Component\Filesystem\Filesystem;

class Installer
{
    /**
     * Install binaries
     */
    public static function install($binDir)
    {
        $fs = new Filesystem();
        $samDir = $binDir.'/sam/';
        $gitlabCiDir = $binDir.'/../.gitlab-ci/sam/';

        if (!$fs->exists($samDir)) {
            $fs->mkdir($samDir);
        } else {
            // Remove previous dir to be sure that previous binaries or old ones arent there.
            $fs->remove($samDir);
            $fs->mkdir($samDir);
        }

        if (!$fs->exists($gitlabCiDir)) {
            $fs->mkdir($gitlabCiDir);
        } else {
            // Remove previous dir to be sure that previous binaries or old ones arent there.
            $fs->remove($gitlabCiDir);
            $fs->mkdir($gitlabCiDir);
        }

        $fs->copy(__DIR__.'/../bin/PublishSamBundles.sh', $samDir.'PublishSamBundles.sh', true);
        $fs->copy(__DIR__.'/../bin/PullSamBundles.sh', $samDir.'PullSamBundles.sh', true);
        $fs->copy(__DIR__.'/../bin/SubmitFeature.sh', $samDir.'SubmitFeature.sh', true);
        $fs->copy(__DIR__.'/../bin/CommitSamBundles.sh', $samDir.'CommitSamBundles.sh', true);
        $fs->copy(__DIR__.'/../bin/UpdateSamBundles.js', $samDir.'UpdateSamBundles.js', true);
        $fs->chmod($samDir.'PublishSamBundles.sh', 0755);
        $fs->chmod($samDir.'PullSamBundles.sh', 0755);
        $fs->chmod($samDir.'SubmitFeature.sh', 0755);
        $fs->chmod($samDir.'CommitSamBundles.sh', 0755);
        $fs->chmod($samDir.'UpdateSamBundles.js', 0755);

        $fs->copy(__DIR__.'/../bin/gitlabci/DeployProduction.py', $gitlabCiDir.'DeployProduction.py', true);
        $fs->copy(__DIR__.'/../bin/gitlabci/ProjectInfos.py', $gitlabCiDir.'ProjectInfos.py', true);
        $fs->copy(__DIR__.'/../bin/gitlabci/PublishRelease.py', $gitlabCiDir.'PublishRelease.py', true);
        $fs->chmod($gitlabCiDir.'DeployProduction.py', 0755);
        $fs->chmod($gitlabCiDir.'ProjectInfos.py', 0755);
        $fs->chmod($gitlabCiDir.'PublishRelease.py', 0755);
    }
}
