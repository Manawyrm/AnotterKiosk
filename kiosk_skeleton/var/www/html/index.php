<h1>Kioskbrowser</h1>

CPU temperature: <br>
<?php passthru("sudo vcgencmd measure_temp"); ?>
<br>
CPU voltage: <br>
<?php passthru("sudo vcgencmd measure_volts"); ?>
<br>
Throttling status (everything except 0x0 means throttling, get a better power supply!): <br>
<?php passthru("sudo vcgencmd get_throttled"); ?>
<br>
Last heartbeat:
<?php echo date("Y-m-d H:i:s", filemtime("/dev/shm/heartbeat")); ?>
<br>

<br><br>
<img src="/screenshot.php?<?php echo microtime(); ?>">