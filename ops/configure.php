<?php
// Only write managed config.php. Never replace persisted security.php.
$host = getenv('HOST_INFO');
if (!$host || !preg_match('~^https?://[a-zA-Z0-9.-]+(?::[0-9]+)?$~', $host)) {
    fwrite(STDERR, "HOST_INFO inválido\n"); exit(1);
}
if (!getenv('DB_PASSWORD')) {fwrite(STDERR,"Falta DB_PASSWORD\n");exit(1);}
$config = [
 'components' => [
  'db' => ['connectionString'=>'mysql:host=db;port=3306;dbname=limesurvey;', 'emulatePrepare'=>true,
           'username'=>'limesurvey','password'=>getenv('DB_PASSWORD'),'charset'=>'utf8mb4','tablePrefix'=>'lime_'],
  'request'=>['hostInfo'=>$host,'baseUrl'=>''],
  'urlManager'=>['urlFormat'=>'get','rules'=>[], 'showScriptName'=>true],
 ],
 'config'=>['debug'=>0,'debugsql'=>0,'mysqlEngine'=>'InnoDB'],
];
$file='/var/www/html/application/config/config.php';
if (file_put_contents($file,"<?php if (!defined('BASEPATH')) exit('No direct script access allowed');\nreturn ".var_export($config,true).";\n") === false) exit(1);
chmod($file,0640);
