<?php

namespace App\Command;

use App\Entity\EndUser;
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
    private const BATCH_SIZE = 100;

    public function __construct(
        private EntityManagerInterface $entityManager
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);

        $repository = $this->entityManager->getRepository(EndUser::class);
        $query = $repository->createQueryBuilder('e')
            ->where('e.requestCountForToday != 0')
            ->getQuery();

        $totalCount = $query->getResult();
        $io->progressStart(count($totalCount));

        $batchSize = self::BATCH_SIZE;
        $i = 0;

        foreach ($query->toIterable() as $endUser) {
            $endUser->setRequestCountForToday(0);

            if (($i % $batchSize) === 0) {
                $this->entityManager->flush();
                $this->entityManager->clear();
                $io->progressAdvance($batchSize);
            }

            ++$i;
        }

        $this->entityManager->flush();
        $this->entityManager->clear();

        $io->progressFinish();
        $io->success('All EndUser requestCountForToday values have been reset to 0.');

        return Command::SUCCESS;
    }
}
