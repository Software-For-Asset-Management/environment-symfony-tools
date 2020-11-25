<?php

namespace SAM\EnvironmentSymfonyTools\Command;

use SAM\EnvironmentSymfonyTools\Installer\Installer;
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
        $io = new SymfonyStyle($input, $output);
        $io->newLine();

        $binDir = __DIR__.'/../../../../../bin';

        Installer::install($binDir);

        $io->success('All binaries were successfully installed.');

        return 0;
    }
}
