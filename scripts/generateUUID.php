<?php

include '/etc/centreon/centreon.conf.php';
require_once '/usr/share/centreon/config/centreon.config.php';

include_once _CENTREON_PATH_ . "www/class/centreonDB.class.php";
include_once _CENTREON_PATH_ . "www/class/centreonUUID.class.php";


$db = new CentreonDB('centreon');

$query = "DELETE FROM informations WHERE informations.key = 'uuid'";
$db->query($query);

$centreonUUID = new CentreonUUID($db);
$uuid = $centreonUUID->getUUID();

?>