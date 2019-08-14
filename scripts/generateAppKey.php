<?php

include '/etc/centreon/centreon.conf.php';
require_once '/usr/share/centreon/config/centreon.config.php';

include_once _CENTREON_PATH_ . "www/class/centreonDB.class.php";

$db = new CentreonDB('centreon');

$query = "DELETE FROM informations WHERE informations.key = 'appKey'";
$db->query($query);

$uniqueKey = md5(uniqid(rand(), true));
$query = "INSERT INTO `informations` (`key`,`value`) VALUES ('appKey', '" . $uniqueKey . "')";
$db->query($query);

?>