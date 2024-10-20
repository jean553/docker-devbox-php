<?php

namespace App\Command;

use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:reset-end-user-request-count',
    description: 'Reset requestCountForToday to 0 for all EndUser entities',
)]
class ResetEndUserRequestCountCommand extends Command
{
    public function __construct(
        private EntityManagerInterface $entityManager
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);

        $connection = $this->entityManager->getConnection();
        
        $io->progressStart();
        
        $sql = "UPDATE end_user SET requests_count_for_today = 0 WHERE requests_count_for_today != 0";
        $stmt = $connection->prepare($sql);
        $result = $stmt->executeStatement();
        
        $io->progressFinish();
        
        $io->success(sprintf('%d EndUser requestCountForToday values have been reset to 0.', $result));
        $io->progressFinish();
        $io->success('All EndUser requestsCountForToday values have been reset to 0.');

        return Command::SUCCESS;
    }
}
