<?php

namespace SAM\EnvironmentSymfonyTools\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Exception\InvalidArgumentException;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;
use Symfony\Component\HttpKernel\Bundle\BundleInterface;
use Symfony\Component\HttpKernel\KernelInterface;

class BinInstallCommand extends Command
{
    protected static $defaultName = 'sam:bin:install';

    /**
     * {@inheritdoc}
     */
    protected function configure()
    {
        $this->setDescription('Installs binaries under the bin directory');
    }

    /**
     * {@inheritdoc}
     */
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $fs = new Filesystem();

        $io = new SymfonyStyle($input, $output);
        $io->newLine();

        $binDir = __DIR__.'/../../../../../bin';

        $fs->copy(__DIR__.'/../bin/increment-tags.sh', $binDir.'/increment-tags.sh', true);
        $fs->copy(__DIR__.'/../bin/pull-checkout.sh', $binDir.'/pull-checkout.sh', true);
        $fs->copy(__DIR__.'/../bin/submit-feature.sh', $binDir.'/submit-feature.sh', true);
        $fs->copy(__DIR__.'/../bin/update-composer.js', $binDir.'/update-composer.js', true);
        $fs->copy(__DIR__.'/../bin/commit-and-push.sh', $binDir.'/commit-and-push.sh', true);

        $fs->chmod($binDir.'/increment-tags.sh', 0755);
        $fs->chmod($binDir.'/pull-checkout.sh', 0755);
        $fs->chmod($binDir.'/submit-feature.sh', 0755);
        $fs->chmod($binDir.'/update-composer.js', 0755);
        $fs->chmod($binDir.'/commit-and-push.sh', 0755);

        $io->success('All binaries were successfully installed.');

        return 0;
    }
}
