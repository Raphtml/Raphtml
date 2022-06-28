<?php

$path = "./README.md";

$dateStart = new DateTime('2021-02-15');

$search = 'Fun fact :';

function getNbOfDaysSinceStart(Datetime $date): int
{
    $today = new DateTime();
    $interval = $today->diff($date);
    return $interval->days;
}

function getYesterdayNbLength(DateTime $date): int
{
    $yesterday = new DateTime('yesterday');
    return strlen($yesterday->diff($date)->days);
}

function updateReadme(string $path, string $search, DateTime $dateStart): void
{
    $fileContent = file_get_contents($path);
    $nbDaysPos = strpos($fileContent, $search) + strlen($search) + 1;
    $yesterdayNblength = getYesterdayNbLength($dateStart);
    $string = "";
    for ($i=$nbDaysPos; $i < ($nbDaysPos + $yesterdayNblength); $i++){
        $string .= $fileContent[$i];
    }

    $newNbDays = getNbOfDaysSinceStart($dateStart);
    $fileContent = str_replace($string, $newNbDays, $fileContent);

    file_put_contents($path, $fileContent);
}

updateReadme($path, $search, $dateStart);
